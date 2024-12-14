require 'puppet/parameter/boolean'

Puppet::Type.newtype(:selinux_login) do
  @doc = <<-EOM
  Manage SELinux login mapping configuration

  NOTE: You may need to run `restorecon -RF` on any user home directories that
  have their default contexts updated. This is particularly important for the
  `__default__` login entry but cannot be automated given the potential load
  and unintended system consequences.
  EOM

  ensurable

  newparam(:name, namevar: true) do
    desc 'The user or group name to be managed. Groups must be prefixed with a "%"'
  end

  newparam(:force, boolean: true, parent: Puppet::Parameter::Boolean) do
    desc 'Force the modification of potentially unsafe logins such as "root" and "__default__"'

    defaultto 'false'
  end

  newproperty(:seuser) do
    desc <<-EOM
      The SELinux user to which the login should be mapped.
      You can get a list by running `semanage user -l`
    EOM

    newvalues(%r{^.+$})
  end

  newproperty(:mls_range) do
    desc 'The Multi-Level Security range to be applied to the login'

    newvalues(%r{^.+$})

    def insync?(is)
      provider.mls_range?(is, should)
    end
  end

  autorequire(:user) do
    toreq = []

    unless self[:name].start_with?('%')
      toreq << self[:name]
    end

    toreq
  end

  autorequire(:group) do
    toreq = []

    if self[:name].start_with?('%')
      toreq << self[:name][1..-1]
    end

    toreq
  end

  validate do
    if self[:ensure] == :absent

      unsafe_logins = ['__default__', 'root']

      if unsafe_logins.include?(self[:name])
        unless self[:force]
          raise(Puppet::Error, %(Refusing to remove potentially unsafe entry '#{self[:name]}'. Set "'force' => true" to override))
        end
      end
    else
      unless self[:seuser] || self[:mls_range]
        raise(Puppet::Error, %(You must specify either :seuser or :mls_range))
      end
    end
  end
end
