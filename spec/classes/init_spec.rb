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
          it { is_expected.to contain_package('policycoreutils-python').with(:ensure => 'latest') }
        end
        context 'with manage_utils_package => false' do
          let(:params) {{:manage_utils_package => false}}
          it { is_expected.to_not contain_package('policycoreutils-python') }
        end
      end
    end
  end
end
