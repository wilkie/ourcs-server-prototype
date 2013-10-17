require_relative './interface.rb'

class Specification
  # Retrieves a hash of all known specifications.
  def self.hash
    @@cache ||= {}
    @@keys  ||= []
    @@specs ||= []

    return @@cache unless @@cache.empty?
    Dir.glob('./specification/**/*') do |file|
      if File.directory?(file)
        next
      end

      self.add(file)
    end

    @@cache
  end

  # Retrieves all known specifications.
  def self.all
    self.hash
    @@specs
  end

  # Retrieves the specification of a given interface with the given name.
  def self.find_by_interface_and_name(interface, name)
    hash = self.hash
    if @@keys.include? interface
      hash[interface.intern].values.select{|e| e.name == name}.first
    else
      nil
    end
  end

  # Runs all of the tests and return true when all pass for the given interface.
  def self.passes?(name)
    self.find_all_by_interface(name).each do |spec|
      if !spec.passes?
        return false
      end
    end

    true
  end

  # Makes the module aware of a new specification.
  def self.add(file)
    # Relative path
    file = File.absolute_path(file)
    cur_path = File.absolute_path('.')
    file.gsub! /^#{Regexp.escape(cur_path)}/,"."

    unless defined? @@cache
      self.hash
    end

    name = file[/^\.\/specification\/(.+)\.[^.]+/,1]
    interface, name = name.match(/^(.+)\/([^\/]+)$/).to_a.drop(1)

    specification = self.new(:name      => name,
                             :interface => interface,
                             :path      => file)

    @@cache[interface.intern] ||= {}
    @@cache[interface.intern][name.intern] = specification

    @@keys  << interface
    @@specs << specification

    specification
  end

  # Retrieves all interfaces with known specifications.
  def self.interfaces
    self.hash.keys
  end

  # Retrieves all specifications of a given interface.
  def self.find_all_by_interface(name)
    hash = self.hash
    if @@keys.include? name
      hash[name.intern].values
    else
      []
    end
  end

  # Retrieves all specifications that have the given name.
  def self.find_all_by_name(name)
    hash = self.hash
    @@specs.select {|i| i.name == name}
  end

  # Retrieves the specification found at the given path.
  def self.find_by_path(path)
    path = File.absolute_path(path)
    hash = self.hash
    @@specs.select{|i| i.path == path}.first
  end

  attr_reader :name
  attr_reader :path

  # Constructs a new specification.
  def initialize(options = {})
    @name      = options[:name]      || throw("Name not given")
    @path      = options[:path]      || throw("Path not given")
    @ifacename = options[:interface] || throw("Interface not given")

    @path = File.absolute_path(@path)
  end

  # Retrieves the interface that this specification describes.
  def interface
    @interface ||= Interface.find_by_name(@ifacename)
  end

  # Retrieves the implementations that this specification describes.
  def implementations
    @implementations ||= Implementation.find_all_by_name(@ifacename)
  end

  # Retrieves the other specifications that also describe this interface.
  def specifications
    @specifications ||= Specification.find_all_by_name(@ifacename)-[self]
  end

  # Runs this specification and returns true when the test passes.
  def passes?
    code = File.read(@path)

    if @pass.nil?
      @pass = instance_eval(code)
    end

    @pass
  end

  # Let this specification know that the implementation has changed.
  def updated_implementation
    @pass = nil
  end

  # Let this specification know that the list of implementations has changed.
  def updated_implementation_list
    @implementations = nil
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
    hash = self.to_hash
    hash[:interface] = hash[:interface].to_json(*args)
    hash.to_json(*args)

    self.to_hash.to_json
  end

  # Hash for all
  def self.find_all_by_interface_to_hash(name)
    {
      :specifications => [
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

  # Hash for all
  def self.to_hash
    {
      :specifications => self.hash.keys.map do |k|
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
end
