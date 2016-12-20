# Manage SELinux state
#
# @param ensure
#   The state that SELinux should be in.
#   Valid values are: true, false, 'enforcing', 'permissive', 'disabled'.
#   Since you are calling this class, we assume that you want to enforce.
#
# @param mode
#   The SELinux type you want to enforce.
#   Valid values are: 'targeted', 'mls'
#   Note, it is quite possible that 'mls' will render your system inoperable.
#
# @param manage_utils_package
#   If true, ensure policycoreutils-python is installed. This is a supplemental
#   package that is required by semanage.
#
# Additional functionality for SELinux support.
#
class selinux (
  Variant[Boolean,Enum['enforcing','permissive','disabled']] $ensure = 'enforcing',
  Boolean                $manage_utils_package = true,
  Enum['targeted','mls'] $mode                 = 'targeted'
) {

  selinux_state { 'set_selinux_state': ensure => $ensure }

  file { '/etc/selinux/config':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('selinux/sysconfig.erb')
  }

  if $manage_utils_package {
    ensure_resource('package', ['checkpolicy','policycoreutils-python'], { 'ensure' => 'latest' })
  }
}
