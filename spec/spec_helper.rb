require 'pathname'
require 'rspec-puppet'
require 'puppetlabs_spec_helper/module_spec_helper'

# RSpec Material
fixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))
module_name = File.basename(File.expand_path(File.join(__FILE__,'../..')))

# Add fixture lib dirs to LOAD_PATH. Work-around for PUP-3336
if Puppet.version < "4.0.0"
  Dir["#{fixture_path}/modules/*/lib"].entries.each do |lib_dir|
    $LOAD_PATH << lib_dir
  end
end

default_hiera_config =<<-EOM
---
:backends:
  - "rspec"
  - "yaml"
:yaml:
  :datadir: "stub"
:hierarchy:
  # This is a variable that you can set in your test classes to ensure that the
  # targeted YAML file gets loaded in the fixtures.
  - "%{module_name}"
  - "default"
EOM

if not File.directory?(File.join(fixture_path,'hieradata')) then
  FileUtils.mkdir_p(File.join(fixture_path,'hieradata'))
end

if not File.directory?(File.join(fixture_path,'modules',module_name)) then
  FileUtils.mkdir_p(File.join(fixture_path,'modules',module_name))
end

Dir.chdir(File.join(fixture_path,'modules',module_name)) do
  ['manifests','templates','lib'].each do |tgt|
    if not File.symlink?(tgt) then
      FileUtils.ln_sf("../../../../#{tgt}",tgt)
    end
  end
end

RSpec.configure do |c|
  c.mock_framework = :rspec
  c.mock_with :mocha

  c.module_path = File.join(fixture_path, 'modules')
  c.manifest_dir = File.join(fixture_path, 'manifests')

  c.hiera_config = File.join(fixture_path,'hieradata','hiera.yaml')

  c.before(:all) do
# Add fixture lib dirs to LOAD_PATH. Work-around for PUP-3336
if Puppet.version < "4.0.0"
  Dir["#{fixture_path}/modules/*/lib"].entries.each do |lib_dir|
    $LOAD_PATH << lib_dir
  end
end

    data = YAML.load(default_hiera_config)
    data[:yaml][:datadir] = File.join(fixture_path, 'hieradata')
    File.open(c.hiera_config, 'w') do |f|
      f.write data.to_yaml
    end
  end
end

Dir.glob("#{RSpec.configuration.module_path}/*").each do |dir|
  begin
    Pathname.new(dir).realpath
  rescue
    fail "ERROR: The module '#{dir}' is not installed. Tests cannot continue."
  end
end
