require 'spec_helper'

describe 'selinux' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) do
        os_facts
      end

      let(:mcstrans_service) do
        os_facts[:os][:release][:major].to_i >= 7 ? 'mcstransd' : 'mcstrans'
      end

      let(:policycoreutils_package) do
        os_facts[:os][:release][:major].to_i >= 7 ? 'policycoreutils-restorecond' : 'policycoreutils'
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
        it { is_expected.to contain_package('checkpolicy').with(ensure: 'present') }
        it { is_expected.not_to contain_package('mcstrans') }
        it { is_expected.not_to contain_service('mcstransd') }

        if os_facts[:os][:release][:major].to_i >= 7
          it { is_expected.not_to contain_package(policycoreutils_package) }
          it { is_expected.not_to create_service('restorecond') }
        else
          it { is_expected.to contain_package(policycoreutils_package).with(ensure: 'present') }
          it { is_expected.to create_service('restorecond').with({
            enable: true,
            ensure: 'running'
          }) }
        end
      end

      context 'when managing mcstrans' do
        let(:params) do
          {
            :manage_mcstrans_package => true,
            :manage_mcstrans_service => true
          }
        end

        it { is_expected.to contain_package('mcstrans').with(ensure: 'present') }

        it { is_expected.to create_service(mcstrans_service).with({
            enable: true,
            ensure: 'running'
        }) }

        if Array(os_facts[:init_systems]).include?('systemd')
          context 'when hidepid=2 on /proc' do
            let(:facts) do
              os_facts.merge(
                {
                  :simplib__mountpoints => {
                    '/proc' => {
                      'options_hash' => {
                        'hidepid' => 2
                      }
                    }
                  }
                }
              )
            end

            it { is_expected.to create_service(mcstrans_service) }
            it { is_expected.not_to create_systemd__dropin_file('selinux_mcstransd_hidepid_add_gid') }

            context 'when gid set on /proc' do
              let(:proc_gid) do
                999
              end

              let(:facts) do
                os_facts.merge(
                  {
                    :simplib__mountpoints => {
                      '/proc' => {
                        'options_hash' => {
                          'hidepid' => 2,
                          'gid' => proc_gid
                        }
                      }
                    }
                  }
                )
              end

              it { is_expected.to create_service(mcstrans_service) }
              it do
                is_expected.to create_systemd__dropin_file('selinux_mcstransd_hidepid_add_gid.conf')
                  .with_unit("#{mcstrans_service}.service")
                  .with_content(/SupplementaryGroups=#{proc_gid}/)
                  .that_notifies("Service[#{mcstrans_service}]")
              end
            end
          end
        end
      end

      context 'with ensure set to a non-boolean' do
        let(:params) {{ ensure: 'permissive' }}
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
      end

      context 'with ensure set to false and restorecond enabled' do
        let(:params) {{
          ensure: false,
          manage_restorecond_package: true,
          manage_restorecond_service: true
        }}
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_file('/etc/selinux/config').with_content(<<-EOF.gsub(/^\s+/,'')
          # This file controls the state of SELinux on the system.
          # SELINUX= can take one of these three values:
          # enforcing - SELinux security policy is enforced.
          # permissive - SELinux prints warnings instead of enforcing.
          # disabled - SELinux is fully disabled.
          SELINUX=disabled
          # SELINUXTYPE= type of policy in use. Possible values are:
          # targeted - Only targeted network daemons are protected.
          # strict - Full SELinux protection.
          SELINUXTYPE=targeted
          EOF
          ) }

        it { is_expected.to contain_package(policycoreutils_package).with(ensure: 'present') }

        it { is_expected.to create_service('restorecond').with(
          enable: true,
          ensure: 'stopped'
        ) }
      end

      context 'with mode set' do
        let(:params) {{ mode: 'mls' }}
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
      end

      context 'with manage_utils_package => false' do
        let(:params) {{ manage_utils_package: false }}
        it { is_expected.to_not contain_package('checkpolicy') }
      end

      context 'modifying kernel state' do
        context 'no kernel enforcement' do
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_reboot_notify('selinux') }
          it { is_expected.to create_selinux_state('set_selinux_state').that_notifies('Reboot_notify[selinux]') }
          it { is_expected.to_not create_kernel_parameter('selinux') }
          it { is_expected.to_not create_kernel_parameter('enforcing') }
        end

        context 'with kernel enforcement' do
          context 'ensure -> enforcing' do
            let(:params) {{
              ensure: 'enforcing',
              kernel_enforce: true
            }}
            it { is_expected.to compile.with_all_deps }
            it { is_expected.to create_kernel_parameter('selinux').with_value(1).that_notifies('Reboot_notify[selinux]') }
            it { is_expected.to create_kernel_parameter('enforcing').with_value(1).that_notifies('Reboot_notify[selinux]') }
          end
          context 'enabled -> disabled' do
            let(:facts) do
              os_facts
            end
            let(:params) {{
              ensure: 'disabled',
              kernel_enforce: true
            }}
            it { is_expected.to compile.with_all_deps }
            it { is_expected.to create_kernel_parameter('selinux').with_value(0).that_notifies('Reboot_notify[selinux]') }
            it { is_expected.to_not create_kernel_parameter('enforcing') }
          end
          context 'ensure -> false' do
            let(:facts) do
              os_facts
            end
            let(:params) {{
              ensure: false,
              kernel_enforce: true
            }}
            it { is_expected.to compile.with_all_deps }
            it { is_expected.to create_kernel_parameter('selinux').with_value(0).that_notifies('Reboot_notify[selinux]') }
            it { is_expected.to_not create_kernel_parameter('enforcing') }
          end
          context 'ensure -> permissive' do
            let(:facts) do
              os_facts
            end
            let(:params) {{
              ensure: 'permissive',
              kernel_enforce: true
            }}
            it { is_expected.to compile.with_all_deps }
            it { is_expected.to create_kernel_parameter('selinux').with_value(1).that_notifies('Reboot_notify[selinux]') }
            it { is_expected.to create_kernel_parameter('enforcing').with_value(0).that_notifies('Reboot_notify[selinux]') }
          end
          context 'ensure -> disabled' do
            let(:facts) do
              os_facts = os_facts.dup
              os_facts[:selinux] = false
              os_facts
            end
            let(:params) {{
              ensure: 'disabled',
              kernel_enforce: true
            }}
            it { is_expected.to compile.with_all_deps }
            it { is_expected.to create_kernel_parameter('selinux').with_value(0).that_notifies('Reboot_notify[selinux]') }
            it { is_expected.to_not create_kernel_parameter('enforcing') }
          end
          context 'ensure -> enforcing' do
            let(:facts) do
              os_facts = os_facts.dup
              os_facts[:selinux] = false
              os_facts
            end
            let(:params) {{
              ensure: 'enforcing',
              kernel_enforce: true
            }}
            it { is_expected.to compile.with_all_deps }
            it { is_expected.to create_kernel_parameter('selinux').with_value(1).that_notifies('Reboot_notify[selinux]') }
            it { is_expected.to create_kernel_parameter('enforcing').with_value(1).that_notifies('Reboot_notify[selinux]') }
          end
          context 'ensure -> true' do
            let(:facts) do
              os_facts = os_facts.dup
              os_facts[:selinux] = false
              os_facts
            end
            let(:params) {{
              ensure: true,
              kernel_enforce: true
            }}
            it { is_expected.to compile.with_all_deps }
            it { is_expected.to create_kernel_parameter('selinux').with_value(1).that_notifies('Reboot_notify[selinux]') }
            it { is_expected.to create_kernel_parameter('enforcing').with_value(1).that_notifies('Reboot_notify[selinux]') }
          end
          context 'ensure -> permissive' do
            let(:facts) do
              os_facts = os_facts.dup
              os_facts[:selinux] = false
              os_facts
            end
            let(:params) {{
              ensure: 'permissive',
              kernel_enforce: true
            }}
            it { is_expected.to compile.with_all_deps }
            it { is_expected.to create_kernel_parameter('selinux').with_value(1).that_notifies('Reboot_notify[selinux]') }
            it { is_expected.to create_kernel_parameter('enforcing').with_value(0).that_notifies('Reboot_notify[selinux]') }
          end
        end
      end
    end
  end
end
