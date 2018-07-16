require 'spec_helper_acceptance'

test_name 'selinux_login'

describe 'selinux_login' do
  hosts.each do |host|
    let(:login_context) { 'staff_u' }
    let(:hieradata) {
      <<-EOM
---
selinux::login_resources:
  "__default__":
    seuser: #{login_context}
    mls_range: "s0-s0:c0.c1023"
      EOM
    }

    let(:manifest) {
      <<-EOM
        include 'selinux'
      EOM
    }

    let(:alt_manifest) {
      <<-EOM
        selinux_login{ '__default__':
          seuser    => '#{login_context}',
          mls_range => 'SystemLow-SystemHigh'
        }
      EOM
    }

    context "on #{host}" do
      it 'should apply' do
        set_hieradata_on(host, hieradata)
        apply_manifest_on(host, manifest, :catch_failures => true)
      end

      it 'should be idempotent' do
        apply_manifest_on(host, manifest, :catch_changes => true)
      end

      it 'should be idempotent with the translated :mls_range' do
        apply_manifest_on(host, alt_manifest, :catch_changes => true)
      end

      context 'after reboot' do
        it 'should be idempotent' do
          host.reboot
          apply_manifest_on(host, manifest, :catch_changes => true)
        end

        it 'should be idempotent with the translated :mls_range' do
          apply_manifest_on(host, alt_manifest, :catch_changes => true)
        end

        it 'should change the default login context' do
          vagrant_context = on(host, %(selinuxdefcon vagrant), :accept_all_exit_codes => true).stdout.strip

          expect(vagrant_context).to match(/^#{login_context}:/)
        end
      end
    end
  end
end
