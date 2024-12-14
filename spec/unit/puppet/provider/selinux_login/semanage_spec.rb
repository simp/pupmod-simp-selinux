require 'spec_helper'

describe Puppet::Type.type(:selinux_login).provider(:semanage) do
  let(:resource_hash) do
    {
      name: 'test_user',
    seuser: 'user_u'
    }
  end

  let(:resource) do
    Puppet::Type.type(:selinux_login).new(resource_hash)
  end

  let(:provider) do
    Puppet::Type.type(:selinux_login).provider(:semanage).new(resource)
  end

  before(:each) do
    allow(Facter).to receive(:value).with(:selinux).and_return(true)
    allow(Facter).to receive(:value).with(:selinux_config_policy).and_return('targeted')
    allow(Facter).to receive(:value).with(:kernel).and_return('Linux')

    # Stubbing these to 'true' just in case something actually tries them
    allow(provider.class).to receive(:commands).with(:semanage).and_return('/usr/sbin/semanage')
    allow(provider.class).to receive(:commands).with(:touch).and_return('/bin/touch')

    allow(provider.class).to receive(:semanage).with('login', '-l', '-n').and_return(
      <<-EOM,
__default__          unconfined_u         s0-s0:c0.c1023       *
root                 unconfined_u         s0-s0:c0.c1023       *
      EOM
    )

    # Need to bind this explicitly
    resource.provider = provider
  end

  context 'self.instances' do
    it 'collects all instances' do
      instances = provider.class.instances

      expect(instances.map { |x| x.instance_variable_get('@property_hash') }).to eq([
                                                                                      {
                                                                                        ensure: :present,
                                                                                        name: '__default__',
                                                                                        seuser: 'unconfined_u',
                                                                                        mls_range: 's0-s0:c0.c1023'
                                                                                      },
                                                                                      {
                                                                                        ensure: :present,
                                                                                        name: 'root',
                                                                                        seuser: 'unconfined_u',
                                                                                        mls_range: 's0-s0:c0.c1023'
                                                                                      },
                                                                                    ])
    end
  end

  context 'create' do
    it 'can create a resource' do
      allow(provider.class).to receive(:semanage).with(['login', '-a', '-s', resource_hash[:seuser], resource_hash[:name]]).and_return('')

      provider.create
    end
  end

  context 'destroy' do
    let(:resource) do
      Puppet::Type.type(:selinux_login).new(
        name: resource_hash[:name],
        ensure: 'absent',
      )
    end

    it 'can destroy a resource' do
      allow(provider.class).to receive(:semanage).with('login', '-d', resource_hash[:name]).and_return('')

      provider.destroy
    end
  end

  context 'mls_range?' do
    context 'on an MLS enabled system' do
      before(:each) do
        allow(File).to receive(:exist?).with('/etc/selinux/targeted/setrans.conf').and_return(true)
        allow(File).to receive(:read).with('/etc/selinux/targeted/setrans.conf').and_return(
          <<-EOM,
  # s0:c1,c3=CompanyConfidentialBob
  s0=SystemLow
  s0-s0:c0.c1023=SystemLow-SystemHigh
  s0:c0.c1023=SystemHigh
          EOM
        )
      end

      context 'does not need translation' do
        let(:resource) do
          Puppet::Type.type(:selinux_login).new(
            name: resource_hash[:name],
            mls_range: 's0-s0:c0.c1023',
          )
        end

        it 'is in sync' do
          allow(provider).to receive(:mls_range).and_return('s0-s0:c0.c1023')
          expect(resource.property(:mls_range).insync?(provider.mls_range)).to be true
        end
      end

      context 'needs translation' do
        let(:resource) do
          Puppet::Type.type(:selinux_login).new(
            name: resource_hash[:name],
            mls_range: 'SystemLow-SystemHigh',
          )
        end

        it 'translates valid MLS ranges' do
          allow(provider).to receive(:mls_range).and_return('s0-s0:c0.c1023')
          expect(resource.property(:mls_range).insync?(provider.mls_range)).to be true
        end

        it 'translates invalid valid MLS ranges' do
          allow(provider).to receive(:mls_range).and_return('s0-s0:c0.c11')
          expect(resource.property(:mls_range).insync?(provider.mls_range)).to be false
        end
      end
    end

    context 'on system without MLS enabled' do
      before(:each) do
        allow(File).to receive(:exist?).with('/etc/selinux/targeted/setrans.conf').and_return(false)
      end

      context 'ignores the :mls_range setting' do
        let(:resource) do
          Puppet::Type.type(:selinux_login).new(
            name: resource_hash[:name],
            mls_range: 'bob',
          )
        end

        it 'is in sync' do
          allow(provider).to receive(:mls_range).and_return(nil)

          expect(resource.property(:mls_range).insync?(provider.mls_range)).to be true
        end
      end
    end
  end

  context 'flush' do
    context 'when :seuser is specified' do
      it 'modifies the :seuser' do
        allow(provider.class).to receive(:semanage).with(['login', '-m', '-s', resource_hash[:seuser], resource_hash[:name]]).and_return('')

        provider.flush
      end
    end

    context 'when :mls_range is specified' do
      let(:resource_hash) do
        {
          name: 'test_user',
        mls_range: 'SystemLow'
        }
      end

      it 'modifies the :mls_range' do
        allow(provider.class).to receive(:semanage).with(['login', '-m', '-r', resource_hash[:mls_range], resource_hash[:name]]).and_return('')

        provider.flush
      end
    end

    context 'when :seuser and :mls_range are specified' do
      let(:resource_hash) do
        {
          name: 'test_user',
        seuser: 'user_u',
        mls_range: 'SystemLow'
        }
      end

      it 'modifies :seuser and :mls_range' do
        allow(provider.class).to receive(:semanage).with(['login', '-m', '-s', resource_hash[:seuser], '-r', resource_hash[:mls_range], resource_hash[:name]]).and_return('')

        provider.flush
      end
    end
  end
end
