# Manage active SELinux state and state after a reboot
#
# @param ensure
#   The state that SELinux should be in.
#   Since you are calling this class, we assume that you want to enforce.
#
# @param mode
#   The SELinux type you want to enforce.
#   Note, it is quite possible that 'mls' will render your system inoperable.
#
# @param manage_utils_package
#   If true, ensure policycoreutils-python is installed. This is a supplemental
#   package that is required by semanage.
#
# @param manage_mcstrans_package
#   Manage the `mcstrans` package.
#
# @param manage_mcstrans_service
#   Manage the `mcstrans` service.
#
# @param mcstrans_service_name
#  The `mcstrans` service name.
#
# @param mcstrans_package_name
#  The `mcstrans` package name.
#
# @param manage_restorecond_package
#   Manage the `restorecond` package.
#
# @param manage_restorecond_service
#   Manage the `restorecond` service.
#
# @param restorecond_package_name
#   The `restorecond` package name.
#
# @param package_ensure The ensure status of packages to be installed
#
class selinux (
  # defaults are in module data
  Boolean $manage_mcstrans_package,
  Boolean $manage_mcstrans_service,
  String  $mcstrans_package_name,
  String  $mcstrans_service_name,
  Boolean $manage_restorecond_package,
  Boolean $manage_restorecond_service,
  String  $restorecond_package_name,
  Selinux::State         $ensure               = simplib::lookup('simp_options::selinux', { 'default_value' => true }),
  Boolean                $manage_utils_package = true,
  String                 $package_ensure       = simplib::lookup('simp_options::package_ensure', { 'default_value' => 'installed' }),
  Enum['targeted','mls'] $mode                 = 'targeted'
) {

  selinux_state { 'set_selinux_state': ensure => $ensure }

  reboot_notify { 'selinux': subscribe => Selinux_state['set_selinux_state'] }

  $_state = $ensure ? {
    true    => 'enforcing',
    false   => 'disabled',
    default => $ensure
  }

  file { '/etc/selinux/config':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('selinux/sysconfig.erb')
  }

  $utils_packages = [
    'checkpolicy',
    'policycoreutils-python',
  ]

  if $manage_utils_package {
    ensure_resource('package', $utils_packages, { 'ensure' => $package_ensure })
  }

  if $manage_mcstrans_package {
    package { $mcstrans_package_name: ensure => $package_ensure }
  }

  if $manage_restorecond_package {
    package { $restorecond_package_name: ensure => $package_ensure }
  }

  if ($_state == 'disabled') or !$facts['os']['selinux']['enabled'] {
    $_aux_service_ensure = 'stopped'
  }
  else {
    # An ensure of 'running' requires selinux to be enabled.
    # Final state after reboot will be correct.
    $_aux_service_ensure = 'running'
  }

  if $manage_mcstrans_service {
    service { $mcstrans_service_name:
      ensure     => $_aux_service_ensure,
      enable     => true,
      hasrestart => true,
      hasstatus  => false,
      require    => Package[$mcstrans_package_name]
    }
  }

  if $manage_restorecond_package {
    service { 'restorecond':
      ensure     => $_aux_service_ensure,
      enable     => true,
      hasrestart => true,
      hasstatus  => false,
      require    => Package[$restorecond_package_name]
    }
  }
}
