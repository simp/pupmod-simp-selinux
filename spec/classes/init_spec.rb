require 'spec_helper'

describe 'selinux' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_package('policycoreutils-python').with(:ensure => 'latest') }
      end
    end
  end
end
