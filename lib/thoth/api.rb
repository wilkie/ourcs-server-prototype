class API
  require_relative 'interface.rb'
  require_relative 'implementation.rb'
  require_relative 'specification.rb'
  require_relative 'protocol.rb'

  require 'fileutils'

  def self.discover(host, port)
    @@hosts ||= []
    @@ports ||= []
    if host.is_a? Array
      host.each_with_index do |h,i|
        self.discover(h, port[i])
      end
    else
      puts "Discovered neighbor at #{host}:#{port}."
      @@hosts << host
      @@ports << port
    end
  end

  def self.hosts
    @@hosts
  end

  def self.host
    @@hosts.first
  end

  def self.ports
    @@ports
  end

  def self.port
    @@ports.first
  end

  def self.query(interface, options = {})
    interface = Interface.find_by_name(interface)
    puts ""

    if interface.nil?
      puts "Interface not found."
    else
      puts "Interface:       #{interface.path}"
    end
  end

  def self.list(interface, options = {})
    interface = Interface.find_by_name(interface)
    puts ""

    if interface.nil?
      puts "Interface not found."
    else
      implementations = interface.implementations
      specifications  = interface.specifications
      puts "Interface:       #{interface.name}"
      puts "Path:            #{interface.path}"
      puts "Implementations: #{implementations.count}"
      implementations.each do |impl|
        puts "                 #{impl.name}@#{impl.path}"
      end
      puts "Specifications:  #{specifications.count}"
      specifications.each do |spec|
        puts "                 #{spec.name}@#{spec.path}"
      end
    end
  end

  # We want new information about the given interface
  def self.sync(interface = nil, options = {})
    puts ""
    if interface.nil? || interface.empty?
      puts "Synchronizing with all neighbors."

      found = false
      self.hosts.each_with_index do |host, i|
        port = self.ports[i]

        begin
          protocol = Protocol.new(:host => host,
                                  :port => port)
        rescue
          puts "Neighbor not reachable."
          next
        end

        interfaces = protocol.interfaces["interfaces"]

        interfaces.each do |iface|
          name = iface["name"]

          sync(name)
        end
      end
    else
      # Ask neighbors
      found = false
      self.hosts.each_with_index do |host, i|
        port = self.ports[i]

        begin
          protocol = Protocol.new(:host => host,
                                  :port => port)
        rescue
          puts "Neighbor not reachable."
          next
        end

        info = protocol.info_for_interface(interface)

        if info
          puts "Found interface... Downloading..."
          found = true
          stream = protocol.interface(interface)

          ensure_interface_path(interface)
          create_interface(interface, stream)
        end
      end

      unless found
        puts "Could not find this interface."
      else
        sync_specifications(interface, options)
        sync_implementations(interface, options)
      end
    end
  end

  def self.sync_specifications(interface, options = {})
    puts ""

    # Ask neighbors
    found = false
    self.hosts.each_with_index do |host, i|
      port = self.ports[i]

      begin
        protocol = Protocol.new(:host => host,
                                :port => port)
      rescue
        puts "Neighbor not reachable."
        next
      end

      specifications = protocol.specifications(interface)

      unless specifications.empty?
        puts "Found specifications... Synchronizing..."
        found = true

        specifications = specifications["specifications"].first["files"]

        specifications.each do |spec|
          unless Specification.find_by_interface_and_name(interface, spec["name"])
            puts "=> #{spec["name"]}"
            ensure_specification_path(interface, spec["name"])

            stream = protocol.specification(interface, spec["name"])
            create_specification(interface, spec["name"], stream)
          end
        end
      end
    end

    unless found
      puts "Could not query specifications."
    end
  end

  def self.sync_implementations(interface, options = {})
    puts ""

    found = false

    # Ask neighbors
    self.hosts.each_with_index do |host, i|
      port = self.ports[i]

      begin
        protocol = Protocol.new(:host => host,
                                :port => port)
      rescue
        puts "Neighbor not reachable."
        next
      end

      implementations = protocol.implementations(interface)

      unless implementations.empty?
        puts "Found implementations... Synchronizing..."
        found = true

        implementations = implementations["implementations"].first["files"]

        implementations.each do |impl|
          unless Implementation.find_by_interface_and_name(interface, impl["name"])
            puts "=> #{impl["name"]}"
            ensure_implementation_path(interface, impl["name"])

            stream = protocol.implementation(interface, impl["name"])
            create_implementation(interface, impl["name"], stream)
          end
        end
      end
    end

    unless found
      puts "Could not query implementations."
    end
  end

  def self.ensure_interface_path(interface)
    FileUtils.mkdir_p "interface"
  end

  def self.ensure_implementation_path(interface, implementation)
    FileUtils.mkdir_p "implementation/#{interface}"
  end

  def self.ensure_specification_path(interface, specification)
    FileUtils.mkdir_p "specification/#{interface}"
  end

  def self.create_interface(interface, stream)
    path = "interface/#{interface}.rb"
    File.open(path, "w+b") do |f|
      f.write stream
    end

    Interface.add(path)
  end

  def self.create_implementation(interface, implementation, stream)
    path = "implementation/#{interface}/#{implementation}.rb"
    File.open(path, "w+b") do |f|
      f.write stream
    end

    Implementation.add(path)
  end

  def self.create_specification(interface, implementation, stream)
    path = "specification/#{interface}/#{implementation}.rb"
    File.open(path, "w+b") do |f|
      f.write stream
    end

    Specification.add(path)
  end

  # We have found new information we would like to share
  # about the given interface
  def self.publish(interface, options = {})
  end
end
