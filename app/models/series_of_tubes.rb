require 'singleton'

class SeriesOfTubes
  include Singleton
  
  def initialize
    @connections = {}
  end
  
  def get_connection(key)
    @connections[key]
  end
  
  def set_connection(key, connection)
    @connections[key] = connection
  end
end