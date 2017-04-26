require 'spec_helper'

describe 'selinux::mcstrans' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      context 'with default parameters' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_package('mcstrans').with_ensure('installed') }

        if facts[:os][:release][:major].to_i >= 7
          it { is_expected.to create_service('mcstransd').with_enable(true) }
          it { is_expected.not_to create_service('restorecond') }
        else
          it { is_expected.to create_service('mcstrans').with_enable(true) }
          it { is_expected.to create_service('restorecond').with_enable(true) }
        end
      end

    end
  end
end
