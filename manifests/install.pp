# @summary Install selinux-related packages not managed by vox_selinux
#
class selinux::install (
  Boolean       $manage_utils_package       = pick(getvar('selinux::manage_utils_package'), true),
  Array[String] $utils_packages             = ['checkpolicy'],
  Boolean       $manage_mcstrans_package    = simplib::lookup('selinux::manage_mcstrans_package'),
  String        $mcstrans_package_name      = simplib::lookup('selinux::mcstrans_package_name'),
  Boolean       $manage_restorecond_package = simplib::lookup('selinux::manage_restorecond_package'),
  String        $restorecond_package_name   = simplib::lookup('selinux::restorecond_package_name'),
  String        $package_ensure             = simplib::lookup('selinux::package_ensure', { 'default_value' => simplib::lookup('simp_options::package_ensure', { 'default_value' => 'present' } ) } )
){
  if $manage_utils_package {
    ensure_packages($utils_packages, { 'ensure' =>  $package_ensure})
  }

  if $manage_mcstrans_package {
    ensure_packages([$mcstrans_package_name], { 'ensure' =>  $package_ensure})
  }

  if $manage_restorecond_package {
    ensure_packages([$restorecond_package_name], { 'ensure' =>  $package_ensure})
  }
}
