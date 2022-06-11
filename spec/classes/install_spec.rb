require 'spec_helper'

describe 'selinux::install' do
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

      it { is_expected.to contain_package('checkpolicy').with(ensure: /\A(present|installed)\Z/) }
      it { is_expected.not_to contain_package('mcstrans') }

      if os_facts[:os][:release][:major].to_i >= 7
        it { is_expected.not_to contain_package(policycoreutils_package) }
      else
        it { is_expected.to contain_package(policycoreutils_package).with(ensure: 'present') }
      end

      context 'when managing mcstrans' do
        let(:params) do
          {
            :manage_mcstrans_package => true,
          }
        end

        it { is_expected.to contain_package('mcstrans').with_ensure(/\A(present|installed)\Z/) }
      end
    end
  end
end
