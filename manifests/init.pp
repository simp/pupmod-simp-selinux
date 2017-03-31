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
class selinux (
  Selinux::State         $ensure               = simplib::lookup('simp_options::selinux', { 'default_value' => true }),
  Boolean                $manage_utils_package = true,
  Enum['targeted','mls'] $mode                 = 'targeted'
) {

  selinux_state { 'set_selinux_state': ensure => $ensure }

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
    'policycoreutils-python'
  ]
  if $manage_utils_package {
    ensure_resource('package', $utils_packages, { 'ensure' => 'latest' })
  }
}
