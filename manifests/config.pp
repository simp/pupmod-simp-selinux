# This class sets selinux system parameters
#
class selinux::config {
  assert_private()

  selinux_state { 'set_selinux_state': ensure => $::selinux::ensure }

  reboot_notify { 'selinux': subscribe => Selinux_state['set_selinux_state'] }

  $_state = $::selinux::state
  $_mode = $::selinux::mode

  file { '/etc/selinux/config':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('selinux/sysconfig.erb')
  }
}
