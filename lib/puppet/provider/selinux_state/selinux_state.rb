Puppet::Type.type(:selinux_state).provide(:selinux_state) do

  commands :setenforce => '/usr/sbin/setenforce'

  def ensure
    return 'disabled' if String(Facter.value(:selinux)) == 'false'
    return Facter.value(:selinux_current_mode).downcase
  end

  def ensure=(should)
    case should
      when 'enforcing'
        setenforce "1"
      else
        setenforce "0"
    end
  end
end
