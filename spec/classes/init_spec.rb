require 'spec_helper'

describe 'selinux' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        context 'with default parameters' do
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_file('/etc/selinux/config').with_content(<<-EOF.gsub(/^\s+/,'')
            # This file controls the state of SELinux on the system.
            # SELINUX= can take one of these three values:
            # enforcing - SELinux security policy is enforced.
            # permissive - SELinux prints warnings instead of enforcing.
            # disabled - SELinux is fully disabled.
            SELINUX=enforcing
            # SELINUXTYPE= type of policy in use. Possible values are:
            # targeted - Only targeted network daemons are protected.
            # strict - Full SELinux protection.
            SELINUXTYPE=targeted
            EOF
            ) }
          it { is_expected.to contain_package('checkpolicy').with(:ensure => 'installed') }
          it { is_expected.to contain_package('policycoreutils-python').with(:ensure => 'installed') }
          it { is_expected.to contain_reboot_notify('selinux') }
        end

        context 'with ensure set to a non-boolean' do
          let(:params) {{ :ensure => 'permissive' }}
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_file('/etc/selinux/config').with_content(<<-EOF.gsub(/^\s+/,'')
            # This file controls the state of SELinux on the system.
            # SELINUX= can take one of these three values:
            # enforcing - SELinux security policy is enforced.
            # permissive - SELinux prints warnings instead of enforcing.
            # disabled - SELinux is fully disabled.
            SELINUX=permissive
            # SELINUXTYPE= type of policy in use. Possible values are:
            # targeted - Only targeted network daemons are protected.
            # strict - Full SELinux protection.
            SELINUXTYPE=targeted
            EOF
            ) }
            it { is_expected.to contain_reboot_notify('selinux') }
        end

        context 'with mode set' do
          let(:params) {{ :mode => 'mls' }}
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_file('/etc/selinux/config').with_content(<<-EOF.gsub(/^\s+/,'')
            # This file controls the state of SELinux on the system.
            # SELINUX= can take one of these three values:
            # enforcing - SELinux security policy is enforced.
            # permissive - SELinux prints warnings instead of enforcing.
            # disabled - SELinux is fully disabled.
            SELINUX=enforcing
            # SELINUXTYPE= type of policy in use. Possible values are:
            # targeted - Only targeted network daemons are protected.
            # strict - Full SELinux protection.
            SELINUXTYPE=mls
            EOF
            ) }
            it { is_expected.to contain_reboot_notify('selinux') }
        end

        context 'with manage_utils_package => false' do
          let(:params) {{:manage_utils_package => false}}
          it { is_expected.to_not contain_package('policycoreutils-python') }
          it { is_expected.to contain_reboot_notify('selinux') }
        end
      end
    end
  end
end
