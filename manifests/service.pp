# @summary Ensures mcstrans and restorecond services managed
#
class selinux::service {
  assert_private()

  if ($selinux::state == 'disabled') or !$facts['selinux'] {
    $_aux_service_ensure = 'stopped'
  }
  else {
    # An ensure of 'running' requires selinux to be enabled.
    # Final state after reboot will be correct.
    $_aux_service_ensure = 'running'
  }

  if $selinux::manage_mcstrans_service {

    if 'systemd' in pick($facts.dig('init_systems') , []) {
      # If hidepid is set > 0 and a GID is set, then the service must have that
      # GID added to its supplementary groups at start time
      if pick($facts.dig('simplib__mountpoints', '/proc', 'options_hash', 'hidepid'), 0) > 0 {
        $_proc_gid = $facts.dig('simplib__mountpoints', '/proc', 'options_hash', 'gid')

        if $_proc_gid {
          simplib::assert_optional_dependency($module_name, 'camptocamp/systemd')

          systemd::dropin_file { "${module_name}_mcstransd_hidepid_add_gid.conf":
            unit          => "${selinux::mcstrans_service_name}.service",
            notify        => Service[$selinux::mcstrans_service_name],
            daemon_reload => 'eager',
            content       => @("SYSTEMD_OVERRIDE")
              [Service]
              SupplementaryGroups=${_proc_gid}
              | SYSTEMD_OVERRIDE
          }
        }
      }
    }

    service { $selinux::mcstrans_service_name:
      ensure     => $_aux_service_ensure,
      enable     => true,
      hasrestart => true,
      hasstatus  => false,
      require    => Class['selinux::install']
    }
  }

  if $selinux::manage_restorecond_service {
    service { 'restorecond':
      ensure     => $_aux_service_ensure,
      enable     => true,
      hasrestart => true,
      hasstatus  => false,
      require    => Class['selinux::install']
    }
  }
}
