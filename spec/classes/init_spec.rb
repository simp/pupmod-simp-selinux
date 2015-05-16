require 'spec_helper'

describe 'selinux' do
  let(:facts) {{
    :fqdn => 'test.host.net',
    :hardwaremodel => 'x86_64',
    :processorcount => 4,
    :selinux => true,
    :selinux_config_mode => 'permissive',
    :selinux_enforced => true
  }}

  it { should compile.with_all_deps }
end
