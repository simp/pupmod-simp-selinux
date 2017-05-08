# Manage SELinux related services on EL6 and EL7
#
# @param manage_package Manage the `mcstrans` package
# @param manage_service Manage the `mcstrans` service
# @param manage_restorecond Manage the `restorecond` service
# @param package_name The `mcstrans` package name
# @param service_name The `mcstrans` service name
# @param package_ensure The ensure status of packages to be installed
#
class selinux::mcstrans (
  # defaults are in module data
  Boolean $manage_package,
  Boolean $manage_service,
  Boolean $manage_restorecond,
  String  $package_name,
  String  $service_name,
  String  $package_ensure = simplib::lookup('simp_options::package_ensure', { 'default_value' => 'installed' }),
) {

  if $manage_package {
    package { $package_name: ensure => $package_ensure }
  }

  if $manage_service {
    service { $service_name:
      ensure     => 'running',
      enable     => true,
      hasrestart => true,
      hasstatus  => false,
      require    => Package[$package_name]
    }
  }

  if $manage_restorecond {
    service { 'restorecond':
      enable     => true,
      hasrestart => true,
      hasstatus  => false
    }
  }

}
