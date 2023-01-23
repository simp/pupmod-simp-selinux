require 'spec_helper_acceptance'

test_name 'selinux class kernel enforcement'

describe 'selinux class kernel enforcement' do
  hosts.each do |host|

    let(:manifest) { "include 'selinux'" }

    context 'kernel enforcing' do
      let(:hieradata) {{
        'selinux::ensure'         => true,
        'selinux::kernel_enforce' => true
      }}

      it 'should work with no errors and set selinux enforcing' do
        set_hieradata_on(host, hieradata)
        apply_manifest_on(host, manifest, :catch_failures => true)

        host.reboot

        os_fact = fact_on(host, 'os')
        # EL 9 machines don't appear to show selinux info on /proc/cmdline
        # For those machines, check getenforce instead
        if (os_fact['release']['major'].to_i > 8)
          result = on(host, 'getenforce')
          expect(result.stdout.strip).to eq('Enforcing')
        else
          result = on(host, 'cat /proc/cmdline').output.strip
          result = Hash[result.split(/\s+/).grep(/=/).map{|x|
            # Some RHS entries can contain '='
            y = x.split('=')
            [y[0], y[1..-1].join('=')]
          }]

          expect(result['selinux']).to eq('1')
          expect(result['enforcing']).to eq('1')
        end
      end

      it 'should be idempotent' do
        apply_manifest_on(host, manifest, :catch_changes => true)
      end
    end
  end
end
