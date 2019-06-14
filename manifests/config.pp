# @summary Set global SELinux system parameters
#
class selinux::config {
  assert_private()

  reboot_notify { 'selinux': reason => 'A reboot is required to modify the selinux state' }

  selinux_state { 'set_selinux_state':
    ensure      => $selinux::ensure,
    autorelabel => $selinux::autorelabel,
    notify      => Reboot_notify['selinux']
  }

  $_enabling  = !$facts['selinux'] and member(['enforcing','permissive'], $selinux::state)
  $_disabling = $facts['selinux'] and !member(['enforcing','permissive'], $selinux::state)

  if $selinux::kernel_enforce {
    if $selinux::state == 'disabled' {
      kernel_parameter { 'selinux':
        value  => '0',
        notify => Reboot_notify['selinux']
      }
    }
    else {
      kernel_parameter { 'selinux':
        value  => '1',
        notify => Reboot_notify['selinux']
      }

      if ( $selinux::state == 'permissive' ) {
        kernel_parameter { 'enforcing':
          value  => '0',
          notify => Reboot_notify['selinux']
        }
      }
      else {
        kernel_parameter { 'enforcing':
          value  => '1',
          notify => Reboot_notify['selinux']
        }
      }
    }
  }

  file { '/etc/selinux/config':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => epp("${module_name}/etc/selinux/config",
      {
        state => $selinux::state,
        mode  => $selinux::mode
      }
    )
  }
}
