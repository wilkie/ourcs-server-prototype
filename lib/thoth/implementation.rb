require_relative './interface.rb'

class Implementation
  # Retrieves a hash of all known implementations.
  def self.hash
    @@cache ||= {}
    @@keys  ||= []
    @@impls ||= []

    return @@cache unless @@cache.empty?
    Dir.glob('./implementation/**/*') do |file|
      if File.directory?(file)
        next
      end

      add(file)
    end

    @@cache
  end

  # Retrieves all known implementations.
  def self.all
    self.hash
    @@impls
  end

  # Makes the module aware of a new implementation.
  def self.add(file)
    # Relative path
    file = File.absolute_path(file)
    cur_path = File.absolute_path('.')
    file.gsub! /^#{Regexp.escape(cur_path)}/,"."

    unless defined? @@cache
      self.hash
    end

    name = file[/^\.\/implementation\/(.+)\.[^.]+/,1]
    interface, name = name.match(/^(.+)\/([^\/]+)$/).to_a.drop(1)

    implementation = self.new(:name => name,
                              :interface => interface,
                              :path => file)

    @@cache[interface.intern] ||= {}
    @@cache[interface.intern][name.intern] = implementation

    @@keys  << interface
    @@impls << implementation

    implementation
  end

  # Retrieves all interfaces with known implementations.
  def self.interfaces
    self.hash.keys
  end

  # Retrieves all implementations of a given interface.
  def self.find_all_by_interface(name)
    hash = self.hash
    if @@keys.include? name
      hash[name.intern].values
    else
      []
    end
  end

  # Retrieves the implementation of a given interface with the given name.
  def self.find_by_interface_and_name(interface, name)
    hash = self.hash
    if @@keys.include? interface
      hash[interface.intern].values.select{|e| e.name == name}.first
    else
      nil
    end
  end

  # Retrieves all implementations that have the given name.
  def self.find_all_by_name(name)
    hash = self.hash
    @@impls.select {|i| i.name == name}
  end

  # Retrieves the implementation at the given path.
  def self.find_by_path(path)
    path = File.absolute_path(path)
    hash = self.hash
    @@impls.select{|i| i.path == path}.first
  end

  attr_reader :name
  attr_reader :path

  # Constructs a new implementation.
  def initialize(options = {})
    @name      = options[:name]      || throw("Name not given")
    @path      = options[:path]      || throw("Path not given")
    @ifacename = options[:interface] || throw("Interface not given")

    @path = File.absolute_path(@path)
  end

  # Retrieves the interface that this implements.
  def interface
    @interface ||= Interface.find_by_name(@ifacename)
  end

  # Retrieves the specifications that test the behavior of this implementation.
  def specifications
    @specifications ||= Specification.find_all_by_interface(@ifacename)
  end

  # Retrieves other implementations that have the same behavior of this one.
  def implementations
    @implementations ||= Implementation.find_all_by_interface(@ifacename)-[self]
  end

  # Load this implementation (in ruby)
  def load
    self.specifications.each do |spec|
      spec.updated_implementation
    end
    Kernel::load @path
  end

  def open
    File.open(@path)
  end

  def data
    self.open.read
  end

  def to_hash
    {
      :name => @name,
      :path => @path,
      :interface => self.interface
    }
  end

  def to_json(*args)
    self.to_hash.to_json(*args)
  end

  # Hash for all
  def self.to_hash
    {
      :implementations => self.hash.keys.map do |k|
        {
          :name => k,
          :files => self.find_all_by_interface(k.to_s)
        }
      end
    }
  end

  # JSON for all
  def self.to_json(*args)
    self.to_hash.to_json(*args)
  end

  # Hash for all
  def self.find_all_by_interface_to_hash(name)
    {
      :implementations => [
        {
          :name => name.intern,
          :files => self.find_all_by_interface(name)
        }
      ]
    }
  end

  # JSON for all
  def self.find_all_by_interface_to_json(name, *args)
    self.find_all_by_interface_to_hash(name).to_json(*args)
  end
end
