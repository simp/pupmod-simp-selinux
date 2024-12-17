# frozen_string_literal: true

require 'spec_helper_acceptance'

test_name 'selinux with /proc hidepid'

describe 'selinux with /proc hidepid' do
  let(:manifest) do
    <<~MANIFEST
    class { 'selinux':
      manage_mcstrans_package => true,
      manage_mcstrans_service => true
    }
    MANIFEST
  end

  hosts.each do |host|
    if host.which('systemctl').empty?
      it "Is not supported on #{host}" do
        skip('non-systemd systems are not supported')
      end

      next
    end

    os_fact = fact_on(host, 'os')
    if (os_fact['family'] == 'RedHat') && (os_fact['release']['major'] != '7')
      it "does not occur on #{host}" do
        skip('the issue is fixed by the vendor')
      end

      next
    end

    context "on #{host}" do
      it 'remounts /proc with hidepid=2' do
        on(host, 'mount -o remount,hidepid=2 /proc')
      end

      it 'applies with no errors' do
        apply_manifest_on(host, manifest)
      end

      it 'does not have issues with MCS translation' do
        on(host, 'ls -Z / | grep -q SystemLow')
      end

      # DO NOT DO THIS IN PRODUCTION - JUST FOR TESTING
      it 'remounts /proc with hidepid=2 and gid=100' do
        on(host, 'mount -o remount,hidepid=2,gid=100 /proc')
      end

      it 'has issues with MCS translation' do
        on(host, 'ls -Z / | grep SystemLow', acceptable_exit_codes: [1])
      end

      it 'applies with no errors' do
        apply_manifest_on(host, manifest)
      end

      it 'does not have issues with MCS translation' do
        on(host, 'ls -Z / | grep -q SystemLow')
      end

      it 'is idempotent' do
        apply_manifest_on(host, manifest, catch_changes: true)
      end
    end
  end
end
