require 'spec_helper_acceptance'

test_name 'selinux class'

describe 'selinux class' do
  hosts.each do |host|

    let(:manifest) { "include 'selinux'" }
    let(:host_fqdn) { fact_on(host, 'fqdn') }

    context 'default parameters' do
      let(:hieradata) {{
        'simp_options::selinux' => true,
      }}
      it 'should work with no errors and set selinux enforcing' do
        set_hieradata_on(host, hieradata)
        apply_manifest_on(host, manifest, :catch_failures => true)
        result = on(host, 'getenforce')
        expect(result.output).to match(/Enforcing/)
      end
    end

    context 'with simp_options::selinux: false' do
      let(:hieradata) {{
        'simp_options::selinux' => false,
      }}
      it 'should set selinux to permissive and require reboot' do
        set_hieradata_on(host, hieradata)
        agent_output = apply_manifest_on(host, manifest, :catch_failures => true)
        expect(agent_output.stdout).to match(/ensure changed 'enforcing' to 'disabled'/)
        expect(agent_output.stdout).to match(/System Reboot Required Because:\n\s+selinux => modified/)
        # Until reboot, selniux will remain permissive
        status = on(host, 'getenforce')
        expect(status.output).to match(/Permissive/)
      end

    end
  end
end
