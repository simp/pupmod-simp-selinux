require 'puppet/parameter/boolean'

Puppet::Type.newtype(:selinux_state) do
  @doc = "Toggle the enforcement of selinux"


  newparam(:name, :namevar => true) do
    desc "An arbitrary, but unique, name for the resource."
  end

  newparam(:autorelabel, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc 'Automatically determine if the filesystem needs to be relabeled.
      Enforcing > Permissive > Disabled
    Going to the right requires relabeling.'

    defaultto 'true'
  end

  newproperty(:ensure) do
    desc 'Set the SELinux state on the system'
    defaultto(:enforcing)
    newvalues(:false,:true,:disabled,:permissive,:enforcing)

    munge do |value|
      case value
        when true,'true'
          value = :enforcing
        when false,'false'
          value = :disabled
      end

      value
    end
  end

  # Autorequire ALL Selbooleans
  autorequire(:selboolean) do
    req = []
    resource = catalog.resources.find_all { |r|
      r.is_a?(Puppet::Type.type(:selboolean))
    }
    if not resource.empty? then
      req << resource
    end
    req.flatten!
    req.each { |r| debug "Autorequiring #{r}" }
    req
  end
end
