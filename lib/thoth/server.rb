require 'bundler'
Bundler.require

require_relative './system.rb'
require_relative './interface.rb'
require_relative './implementation.rb'
require_relative './specification.rb'

require 'json'

# Query neighbors for interfaces
# Download new things
# Run programs?

class Server < Sinatra::Base
  # Retrieves a basic system overview
  get '/' do
    System.to_json
  end

  # Retrieve a list of all interfaces
  get '/interfaces' do
    Interface.to_json
  end

  # Retrieve the given interface
  get '/interfaces/:interface' do
    interface = Interface.find_by_name(params[:interface])

    if request.preferred_type('text/plain')
      content_type 'text/plain'
      send_file interface.path
    else
      content_type 'application/json'
      interface.to_json
    end
  end

  # Post a new interface
  post '/interfaces' do
  end

  # Retrieve a list of implementations for the given interface
  get '/implementations/:interface' do
    if request.preferred_type('application/json')
      content_type 'application/json'
      Implementation.find_all_by_interface_to_json(params[:interface])
    else
      status 404
    end
  end

  # Retrieve an implementation for the given interface
  get '/implementations/:interface/:impl' do
    impl = Implementation.find_by_interface_and_name(params[:interface], params[:impl])
    if impl
      send_file impl.path
    else
      status 404
    end
  end

  # Posts a new implementation for the given interface
  post '/implementations/:interface' do
  end

  # Retrieves a list of all specifications known.
  get '/specifications' do
    Specification.to_json
  end

  # Retrieves a list of specifications for the given interface
  get '/specifications/:interface' do
    Specification.find_all_by_interface_to_json(params[:interface])
  end

  # Retrieves a specification for the given interface
  get '/specifications/:interface/:spec' do
    spec = Specification.find_by_interface_and_name(params[:interface], params[:spec])
    if spec
      send_file spec.path
    else
      status 404
    end
  end

  # Posts a new specification for the given interface
  post '/specifications/:interface' do
  end

  # Retrieves a list of our known neighbors
  get '/neighbors' do
  end

  # Retrieves information about a particular neighbor
  get '/neighbors/:id' do
  end

  # Posts that we have found a new neighbor
  post '/neighbors' do
  end
end
