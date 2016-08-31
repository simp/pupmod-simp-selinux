#
# Class: selinux
#
# Parameters
#
# $ensure
# Type: String
# Default: 'enforcing'
#   The state that SELinux should be in.
#   Valid values are: true, false, 'enforcing', 'permissive', 'disabled'.
#   Since you are calling this class, we assume that you want to enforce.
#
# $mode
# Type: String
# Default: 'targeted'
#   The SELinux type you want to enforce.
#   Valid values are: 'targeted', 'mls'
#   Note, it is quite possible that 'mls' will render your system inoperable.
#
# $manage_utils_package
# Type: Boolean
# Default: true
#   If true, ensure policycoreutils-python is installed. This is a supplemental
#   package that is required by semanage.
#
# Additional functionality for SELinux support.
#
class selinux (
  $ensure               = 'enforcing',
  $manage_utils_package = true,
  $mode                 = 'targeted'
) {
  validate_array_member($mode,['targeted','mls'])
  validate_bool($manage_utils_package)
  validate_array_member($ensure,[true,false,'enforcing','permissive','disabled'])

  compliance_map()

  selinux_state { 'set_selinux_state': ensure => $ensure }

  file { '/etc/selinux/config':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('selinux/sysconfig.erb')
  }

  if $manage_utils_package {
    if !defined(Package['policycoreutils-python']) {
      package { 'policycoreutils-python':
        ensure => 'latest'
      }
    }
  }
}
