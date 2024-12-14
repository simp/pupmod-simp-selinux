Puppet::Type.type(:selinux_login).provide(:semanage) do
  desc 'Support setting SELinux login mappings via semanage'

  defaultfor kernel: 'Linux'
  confine selinux: true
  commands semanage: 'semanage'
  commands touch: 'touch'

  mk_resource_methods

  def self.setrans(category)
    category.strip!

    selinux_policy = Facter.value(:selinux_config_policy)

    # For some reason, selinux_config_policy does not always have a value
    unless selinux_policy
      if File.exist?('/etc/selinux/config')

        selinux_type_entry = File.read('/etc/selinux/config').lines.grep(%r{\A\s*SELINUXTYPE=}).last

        if selinux_type_entry
          selinux_policy = selinux_type_entry.split('=').last.strip
        end
      end
    end

    raise(Puppet::Error, 'Could not find the policy type in /etc/selinux/config. Is SELinux enabled and working?') unless selinux_policy

    @setrans_table ||= {}

    if @setrans_table.empty?
      setrans_file = '/' + File.join('etc', 'selinux', selinux_policy, 'setrans.conf')

      if File.exist?(setrans_file)
        @setrans_table = Hash[
          File.read(setrans_file).lines.map { |line|
            if %r{^\s*#}.match?(line)
              nil
            else
              line.strip.split('=').reverse
            end
          }.compact
        ]
      end
    end

    return @setrans_table[category] if @setrans_table[category]

    category
  end

  def setrans(category)
    self.class.setrans(category)
  end

  def self.instances
    resources = []

    # We're calling this instead of using a Python helper because the internal
    # Python logic is not a simple resource mapping
    semanage('login', '-l', '-n').lines.each do |entry|
      login, seuser, mls_range = entry.strip.split(%r{\s+})

      resource = {
        ensure: :present,
        name: login,
        seuser: seuser
      }

      # Not all environments are MLS enabled
      resource[:mls_range] = setrans(mls_range) if mls_range

      resources << new(resource)
    end

    resources
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if (resource = resources[prov.name])
        resource.provider = prov
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    args = [ 'login', '-a', '-s', @resource[:seuser] ]

    if @resource['mls_range']
      args << '-r'
      args << @resource[:mls_range]
    end

    args << @resource[:name]

    semanage(args)
  end

  def destroy
    semanage('login', '-d', @resource[:name])
  end

  # Some translation work needs to be done here to see if we're in sync
  def mls_range?(is, should)
    # If the system is not MLS enabled, there's nothing to check
    return true if is.nil?

    (is == should) || (is == setrans(should))
  end

  def flush
    args = ['login', '-m']

    if @resource[:seuser]
      args << '-s'
      args << @resource[:seuser]
    end

    if @resource[:mls_range]
      args << '-r'
      args << @resource[:mls_range]
    end

    args << @resource[:name]

    semanage(args)

    # Changing any of these is cause to relabel everything at the next boot
    return unless ['__default__', 'root'].include?(@resource[:name])
    touch '/.autorelabel'
  end
end
