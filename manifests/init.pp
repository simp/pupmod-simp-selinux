#
# Class: selinux
#
# Additional functionality for SELinux support.
#
class selinux (
# _Variables
# $ensure
#     The state that SELinux should be in.
#     Valid values are: true, false, 'enforcing', 'permissive', 'disabled'.
#     Since you are calling this class, we assume that you want to enforce.
  $ensure = 'enforcing',
# $mode
#     The SELinux type you want to enforce.
#     Valid values are: 'targeted', 'mls'
#     Note, it is quite possible that 'mls' will render your system inoperable.
  $mode = 'targeted'
) {
  validate_array_member($mode,['targeted','mls'])

  compliance_map()

  selinux_state { 'set_selinux_state': ensure => $ensure }

  file { '/etc/selinux/config':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('selinux/sysconfig.erb')
  }

  package { 'policycoreutils-python':
    ensure => 'latest'
  }
}
