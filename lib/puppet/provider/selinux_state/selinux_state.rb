Puppet::Type.type(:selinux_state).provide(:selinux_state) do
  desc 'Set the SELinux state on the machine, and optionally relabel the filesystem.'

  commands :setenforce => '/usr/sbin/setenforce'
  commands :touch => '/bin/touch'

  def relabel?(should)
    on_cases  = ['enforcing',:true]
    off_cases = ['permissive','disabled',:false]

    return true if should == 'permissive' && self.ensure == 'disabled'
    return(on_cases.include? should) && (off_cases.include? self.ensure)
  end

  def ensure
    return 'disabled' if String(Facter.value(:selinux)) == 'false'
    return Facter.value(:selinux_current_mode).downcase
  end

  def ensure=(should)
    # You can't enforce/disable selinux if it's currently disabled
    # so don't try.
    if String(Facter.value(:selinux)) != 'false'
      case should
        when 'enforcing'
          setenforce '1'
        else
          setenforce '0'
      end
    end

    # If we're going from off to on, we should touch /.autorelabel
    if resource[:autorelabel] && relabel?(should)
      touch '/.autorelabel'
    end
  end
end
