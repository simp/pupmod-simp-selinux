require 'spec_helper_acceptance'

test_name 'selinux_login'

describe 'selinux_login' do
  hosts.each do |host|
    let(:login_context) { 'staff_u' }
    let(:hieradata) do
      <<-EOM
---
selinux::login_resources:
  "__default__":
    seuser: #{login_context}
    mls_range: "s0-s0:c0.c1023"
      EOM
    end

    let(:manifest) do
      <<-EOM
        include 'selinux'
      EOM
    end

    let(:alt_manifest) do
      <<-EOM
        selinux_login{ '__default__':
          seuser    => '#{login_context}',
          mls_range => 'SystemLow-SystemHigh'
        }
      EOM
    end

    context "on #{host}" do
      it 'applies' do
        set_hieradata_on(host, hieradata)
        apply_manifest_on(host, manifest, catch_failures: true)
      end

      it 'is idempotent' do
        apply_manifest_on(host, manifest, catch_changes: true)
      end

      it 'is idempotent with the translated :mls_range' do
        apply_manifest_on(host, alt_manifest, catch_changes: true)
      end

      context 'after reboot' do
        it 'is idempotent' do
          host.reboot
          apply_manifest_on(host, manifest, catch_changes: true)
        end

        it 'is idempotent with the translated :mls_range' do
          apply_manifest_on(host, alt_manifest, catch_changes: true)
        end

        it 'changes the default login context' do
          vagrant_context = on(host, %(selinuxdefcon vagrant), accept_all_exit_codes: true).stdout.strip

          expect(vagrant_context).to match(%r{^#{login_context}:})
        end
      end
    end
  end
end
