Summary: SELinux Puppet Module
Name: pupmod-selinux
Version: 1.0.0
Release: 5
License: Apache License, Version 2.0
Group: Applications/System
Source: %{name}-%{version}-%{release}.tar.gz
Buildroot: %{_tmppath}/%{name}-%{version}-%{release}-buildroot
Requires: puppet >= 3.3.0
Buildarch: noarch
Requires: simp-bootstrap >= 4.2.0
Obsoletes: pupmod-selinux-test
Requires: pupmod-onyxpoint-compliance_markup

Prefix:"/etc/puppet/environments/simp/modules"

%description
This Puppet module manages various attributes of the SELinux system state.

%prep
%setup -q

%build

%install
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

mkdir -p %{buildroot}/%{prefix}/selinux

dirs='files lib manifests templates'
for dir in $dirs; do
  test -d $dir && cp -r $dir %{buildroot}/%{prefix}/selinux
done

mkdir -p %{buildroot}/usr/share/simp/tests/modules/selinux

%clean
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

mkdir -p %{buildroot}/%{prefix}/selinux

%files
%defattr(0640,root,puppet,0750)
/etc/puppet/environments/simp/modules/selinux

%post

%postun
# Post uninitall stuff

%changelog
* Thu Feb 25 2016 Ralph Wright <ralph.wright@onyxpoint.com> - 1.0.0-5
- Added compliance function support

* Fri Jan 16 2015 Trevor Vaughan <tvaughan@onyxpoint.com> - 1.0.0-4
- Changed puppet-server requirement to puppet

* Sun May 04 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 1.0.0-3
- Rewrite the native type to properly handle all options.
- Remove incorrect use of !! in the selinux provider.

* Wed Apr 16 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 1.0.0-2
- Update to allow true/false as enable modes so that it can be removed from the
  sec module.

* Wed Apr 09 2014 Nick Markowski <nmarkowski@keywcorp.com> - 1.0.0-2
- Added a custom type to set the selinux mode.  It autorequires all
  selboolean types.  This replaces the selinux_enable execs in the init manifest.

* Mon Oct 07 2013 Kendall Moore <kmoore@keywcorp.com> 1.0.0-1
- Updated all erb templates to properly scope variables.

* Fri May 03 2013 Trevor Vaughan <tvaughan@onyxpoint.com> 1.0.0-0
- First cut at an SELinux module.
- The only current functionality is to enable or disable SELinux on the running
  system in a sane manner.
