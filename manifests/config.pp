# This class sets selinux system parameters
#
class selinux::config {
  assert_private()

  selinux_state { 'set_selinux_state':
    ensure      => $::selinux::ensure,
    autorelabel => $::selinux::autorelabel
  }

  $_enabling  = !$facts['os']['selinux']['enabled'] and member(['enforcing','permissive'],$::selinux::state)
  $_disabling = $facts['os']['selinux']['enabled'] and !member(['enforcing','permissive'],$::selinux::state)

  if $_enabling or $_disabling {
    reboot_notify { 'selinux':
      reason    => 'A reboot is required to completely modify selinux state',
      subscribe => Selinux_state['set_selinux_state']
    }
  }

  # These vars are used in the template below
  $_state = $::selinux::state
  $_mode = $::selinux::mode

  file { '/etc/selinux/config':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('selinux/sysconfig.erb')
  }
}
