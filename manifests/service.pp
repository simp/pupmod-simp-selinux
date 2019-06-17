# @summary Ensures mcstrans and restorecond services managed
#
class selinux::service {
  assert_private()

  if ($::selinux::state == 'disabled') or !$facts['selinux'] {
    $_aux_service_ensure = 'stopped'
  }
  else {
    # An ensure of 'running' requires selinux to be enabled.
    # Final state after reboot will be correct.
    $_aux_service_ensure = 'running'
  }

  if $::selinux::manage_mcstrans_service {
    service { $::selinux::mcstrans_service_name:
      ensure     => $_aux_service_ensure,
      enable     => true,
      hasrestart => true,
      hasstatus  => false,
      require    => Class['selinux::install']
    }
  }

  if $::selinux::manage_restorecond_service {
    service { 'restorecond':
      ensure     => $_aux_service_ensure,
      enable     => true,
      hasrestart => true,
      hasstatus  => false,
      require    => Class['selinux::install']
    }
  }
}
