#! /usr/bin/env ruby -S rspec
require 'spec_helper'

describe Puppet::Type.type(:selinux_login) do
  it 'requires either :seuser or :mls_range' do
    expect {
      Puppet::Type.type(described_class.name).new({
                                                    name: 'test_user'
                                                  })
    }.to raise_error(%r{must specify either :seuser or :mls_range})
  end

  it 'accepts a login and seuser' do
    expect {
      Puppet::Type.type(described_class.name).new({
                                                    name: 'test_user',
        seuser: 'user_u'
                                                  })
    }.not_to raise_error
  end

  it 'accepts a login and mls_range' do
    expect {
      Puppet::Type.type(described_class.name).new({
                                                    name: 'test_user',
        mls_range: 'SystemLow'
                                                  })
    }.not_to raise_error
  end

  unsafe_logins = ['__default__', 'root']

  unsafe_logins.each do |unsafe_login|
    context "unsafe login '#{unsafe_login}'" do
      it 'allows creation' do
        expect {
          Puppet::Type.type(described_class.name).new({
                                                        name: unsafe_login,
            seuser: 'user_u'
                                                      })
        }.not_to raise_error
      end

      it 'refuses to destroy' do
        expect {
          Puppet::Type.type(described_class.name).new({
                                                        name: unsafe_login,
            ensure: 'absent'
                                                      })
        }.to raise_error(%r{Refusing to remove.+#{unsafe_login}})
      end

      it 'destroys when forced' do
        expect {
          Puppet::Type.type(described_class.name).new({
                                                        name: unsafe_login,
            ensure: 'absent',
            force: true
                                                      })
        }.not_to raise_error
      end
    end
  end
end
