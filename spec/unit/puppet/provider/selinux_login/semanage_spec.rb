require 'spec_helper'

describe Puppet::Type.type(:selinux_login).provider(:semanage) do

  let(:resource_hash) {{
    :name   => 'test_user',
    :seuser => 'user_u'
  }}

  let(:resource) {
    Puppet::Type.type(:selinux_login).new(resource_hash)
  }

  let(:provider) {
    Puppet::Type.type(:selinux_login).provider(:semanage).new(resource)
  }

  before(:each) do
    Facter.stubs(:value).with(:selinux).returns(true)
    Facter.stubs(:value).with(:selinux_config_policy).returns('targeted')
    Facter.stubs(:value).with(:kernel).returns('Linux')

    # Stubbing these to 'true' just in case something actually tries them
    provider.class.stubs(:commands).with(:semanage).returns('/usr/sbin/semanage')
    provider.class.stubs(:commands).with(:touch).returns('/bin/touch')

    provider.class.stubs(:semanage).with('login', '-l', '-n').returns(
      <<-EOM
__default__          unconfined_u         s0-s0:c0.c1023       *
root                 unconfined_u         s0-s0:c0.c1023       *
      EOM
    )
  end

  context 'self.instances' do
    it 'collects all instances' do
      instances = provider.class.instances

      expect(instances.map{|x| x.instance_variable_get('@property_hash')}).to eq([
        {
          :ensure    => :present,
          :name      => '__default__',
          :seuser    => 'unconfined_u',
          :mls_range => 's0-s0:c0.c1023'
        },
        {
          :ensure    => :present,
          :name      => 'root',
          :seuser    => 'unconfined_u',
          :mls_range => 's0-s0:c0.c1023'
        }
      ])
    end
  end

  context 'create' do
    it 'can create a resource' do
      provider.class.stubs(:semanage).with(['login', '-a', '-s', resource_hash[:seuser], resource_hash[:name]]).returns('')

      provider.create
    end
  end

  context 'destroy' do
    let(:resource) {
      Puppet::Type.type(:selinux_login).new(
        name: resource_hash[:name],
        ensure: 'absent'
      )
    }

    it 'can destroy a resource' do
      provider.class.stubs(:semanage).with('login', '-d', resource_hash[:name]).returns('')

      provider.destroy
    end
  end

  context 'mls_range?' do
    context 'on an MLS enabled system' do
      before(:each) do
        File.stubs(:exist?).with('/etc/selinux/targeted/setrans.conf').returns(true)
        File.stubs(:read).with('/etc/selinux/targeted/setrans.conf').returns(
          <<-EOM
  # s0:c1,c3=CompanyConfidentialBob
  s0=SystemLow
  s0-s0:c0.c1023=SystemLow-SystemHigh
  s0:c0.c1023=SystemHigh
          EOM
        )
      end

      context 'does not need translation' do
        let(:resource) {
          Puppet::Type.type(:selinux_login).new(
            name: resource_hash[:name],
            mls_range: 's0-s0:c0.c1023'
          )
        }

        it 'is in sync' do
          provider.stubs(:mls_range).returns('s0-s0:c0.c1023')
          expect(resource.property(:mls_range).insync?(provider.mls_range)).to be true
        end
      end

      context 'needs translation' do
        let(:resource) {
          Puppet::Type.type(:selinux_login).new(
            name: resource_hash[:name],
            mls_range: 'SystemLow-SystemHigh'
          )
        }

        it 'translates valid MLS ranges' do
          provider.stubs(:mls_range).returns('s0-s0:c0.c1023')
          expect(resource.property(:mls_range).insync?(provider.mls_range)).to be true
        end

        it 'translates invalid valid MLS ranges' do
          provider.stubs(:mls_range).returns('s0-s0:c0.c11')
          expect(resource.property(:mls_range).insync?(provider.mls_range)).to be false
        end
      end
    end

    context 'on system without MLS enabled' do
      before(:each) do
        File.stubs(:exist?).with('/etc/selinux/targeted/setrans.conf').returns(false)
      end

      context 'ignores the :mls_range setting' do
        let(:resource) {
          Puppet::Type.type(:selinux_login).new(
            name: resource_hash[:name],
            mls_range: 'bob'
          )
        }

        it 'is in sync' do
          provider.stubs(:mls_range).returns(nil)

          expect(resource.property(:mls_range).insync?(provider.mls_range)).to be true
        end
      end
    end
  end

  context 'flush' do
    context 'when :seuser is specified' do
      it 'modifies the :seuser' do
        provider.class.stubs(:semanage).with(['login', '-m', '-s', resource_hash[:seuser], resource_hash[:name]]).returns('')

        provider.flush
      end
    end

    context 'when :mls_range is specified' do
      let(:resource_hash) {{
        :name      => 'test_user',
        :mls_range => 'SystemLow'
      }}

      it 'modifies the :mls_range' do
        provider.class.stubs(:semanage).with(['login', '-m', '-r', resource_hash[:mls_range], resource_hash[:name]]).returns('')

        provider.flush
      end
    end

    context 'when :seuser and :mls_range are specified' do
      let(:resource_hash) {{
        :name      => 'test_user',
        :seuser    => 'user_u',
        :mls_range => 'SystemLow'
      }}

      it 'modifies :seuser and :mls_range' do
        provider.class.stubs(:semanage).with(['login', '-m', '-s', resource_hash[:seuser], '-r', resource_hash[:mls_range], resource_hash[:name]]).returns('')

        provider.flush
      end
    end
  end
end
