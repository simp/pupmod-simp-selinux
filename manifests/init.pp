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

  $state = $ensure ? {
    true    => 'enforcing',
    false   => 'disabled',
    default => $ensure
  }

  contain 'selinux::install'
  contain 'selinux::config'
  contain 'selinux::service'

  Class['selinux::install'] ->
  Class['selinux::config'] ~>
  Class['selinux::service']
}
