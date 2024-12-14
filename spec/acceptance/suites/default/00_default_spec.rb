require 'spec_helper_acceptance'

test_name 'selinux class'

describe 'selinux class' do
  hosts.each do |host|
    let(:manifest) { "include 'selinux'" }
    let(:host_fqdn) { fact_on(host, 'fqdn') }

    context 'prep' do
      # There have been issues with OEL 7 and SSH hanging due to an old EL7 bug
      if fact_on(host, 'operatingsystem').strip == 'OracleLinux'
        it 'updates systemd packages' do
          on(host, 'yum -y update systemd*')
        end
      end

      it 'enables SELinux and set it to permissive' do
        enable_selinux_manifest = <<-EOM
          class { 'selinux':
            ensure => 'permissive',
            autorelabel => true
          }
        EOM

        apply_manifest_on(host, enable_selinux_manifest)
        host.reboot
      end
    end

    context 'default parameters' do
      let(:hieradata) do
        {
          'selinux::ensure' => true,
        }
      end

      it 'works with no errors and set selinux enforcing' do
        set_hieradata_on(host, hieradata)
        apply_manifest_on(host, manifest, catch_failures: true)

        result = on(host, 'getenforce')
        expect(result.output).to match(%r{Enforcing})

        result = on(host, %(source /etc/selinux/config && echo $SELINUX))
        expect(result.output.strip).to eq 'enforcing'

        host.reboot
      end

      it 'is idempotent' do
        apply_manifest_on(host, manifest, catch_changes: true)
      end
    end

    context 'with simp_options::selinux: false' do
      let(:hieradata) do
        {
          'selinux::ensure' => false,
        }
      end

      it 'disables selinux, set the current state to permissive, and require reboot' do
        set_hieradata_on(host, hieradata)
        agent_output = apply_manifest_on(host, manifest, catch_failures: true)
        expect(agent_output.stdout).to match(%r{ensure changed 'enforcing' to 'disabled'})
        expect(agent_output.stdout).to match(%r{System Reboot Required Because:\n\s+selinux => A reboot is required to modify the selinux state})
        status = on(host, 'getenforce')
        expect(status.output).to match(%r{Permissive})
        # This will not be idempotent until after reboot since the system will
        # always show as 'disabled'
      end

      it 'is disabled after reboot' do
        host.reboot

        status = on(host, 'getenforce')
        expect(status.output).to match(%r{Disabled})
      end

      it 'is idempotent' do
        apply_manifest_on(host, manifest, catch_changes: true)
      end
    end

    context 'when re-enabling selinux after being disabled' do
      let(:hieradata) do
        {
          'selinux::ensure' => true,
        }
      end

      it 'works with no errors and set selinux enforcing' do
        set_hieradata_on(host, hieradata)
        agent_output = apply_manifest_on(host, manifest, catch_failures: true)
        expect(agent_output.stdout).to match(%r{ensure changed 'disabled' to 'enforcing'})
        expect(agent_output.stdout).to match(%r{System Reboot Required Because:\n\s+selinux => A reboot is required to modify the selinux state})
        status = on(host, 'getenforce')
        # Won't take effect until after reboot
        expect(status.output).to match(%r{Disabled})
      end

      it 'is enforcing after reboot' do
        host.reboot

        status = on(host, 'getenforce')
        expect(status.output).to match(%r{Enforcing})
      end

      it 'is idempotent at the second run' do
        # There is an selinux context switch on /etc/selinux/config that needs
        # to happen
        apply_manifest_on(host, manifest, catch_failures: true)
        apply_manifest_on(host, manifest, catch_changes: true)
      end
    end
  end
end
