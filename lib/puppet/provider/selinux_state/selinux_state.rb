Puppet::Type.type(:selinux_state).provide(:selinux_state) do

  commands :setenforce => '/usr/sbin/setenforce'

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
          setenforce "1"
        else
          setenforce "0"
      end
    end
  end
end
