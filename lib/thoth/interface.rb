require_relative './implementation.rb'
require_relative './specification.rb'

class Interface
  require 'pathname'

  # Retrieves all interfaces as a hash.
  def self.hash
    @@cache  ||= {}
    @@keys   ||= []
    @@ifaces ||= []

    return @@cache unless @@cache.empty?
    Dir.glob('./interface/*') do |file|
      if File.directory?(file)
        next
      end

      add(file)
    end
    @@cache
  end

  # Adds the interface found at the given path
  def self.add(file)
    # Relative path
    file = File.absolute_path(file)
    cur_path = File.absolute_path('.')
    file.gsub! /^#{Regexp.escape(cur_path)}/,"."

    unless defined? @@cache
      self.hash
    end

    name = file[/^\.\/interface\/(.+)\.[^.]+/,1]
    interface = self.new(:name => name,
                         :path => file)

    unless @@cache.include? name.intern
      @@cache[name.intern] = interface
      @@keys << name
      @@ifaces << interface
    end
  end

  # Retrieves a list of all known interface names.
  def self.names
    self.hash.keys
  end

  # Retrieves a list of known interfaces.
  def self.all
    self.hash
    @@ifaces
  end

  # Retrieves the interface for the given name, if known.
  def self.find_by_name(name)
    hash = self.hash

    if @@keys.include? name
      hash[name.intern]
    else
      nil
    end
  end

  attr_reader :name
  attr_reader :path

  # Constructs a new interface from a given interface file.
  def initialize(options = {})
    @name = options[:name] || throw("Name not given")
    @path = options[:path] || throw("Path not given")

    @path = File.absolute_path(@path)
  end

  # Retrieve all implementations for this interface.
  def implementations
    Implementation.find_all_by_interface(self.name)
  end

  # Retrieve all specifications for this interface.
  def specifications
    Specification.find_all_by_interface(self.name)
  end

  # Loads the interface (in ruby)
  def load
    require @path
  end

  def open
    File.open(@path)
  end

  def data
    self.open.read
  end

  # Hash
  def to_hash
    {
      :name => @name,
      :path => @path
    }
  end

  # JSON
  def to_json(*args)
    self.to_hash.to_json(*args)
  end

  # Hash for all
  def self.to_hash
    {
      :interfaces => self.all
    }
  end

  # JSON for all
  def self.to_json(*args)
    self.to_hash.to_json(*args)
  end
end
