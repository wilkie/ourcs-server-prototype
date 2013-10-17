require_relative './interface.rb'
require_relative './implementation.rb'
require_relative './specification.rb'

require 'json'

class System
  def self.interfaces
    Interface.all
  end

  def self.implementations
    Implementation.all
  end

  def self.specifications
    Specification.all
  end

  def self.to_hash
    Interface.to_hash.merge!(
      Implementation.to_hash.merge!(
        Specification.to_hash))
  end

  def self.to_json(*args)
    self.to_hash.to_json(*args)
  end
end
