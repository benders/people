# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  # Pick a unique cookie name to distinguish our session data from others'
  session :session_key => '_people_session_id'

  protected

  def authenticate
    unless session[:user]
      session[:return_to] = @request.request_uri
      redirect_to :controller => "login" 
      return false
    end
  end
  
  def user_connect
    if session[:user]
      conf = ActiveLdap::Base.configuration(session[:user])
      ActiveLdap::Base.establish_connection(conf)
    end
  end
   
  #
  # Custom Fragment Cache that allows the :mtime option
  #
    
  def read_fragment(name, options = nil)
    return unless perform_caching
    options = options.dup
    mtime = options && options.delete(:mtime)
    
    key = fragment_cache_key(name)
    if mtime && (mtime.to_i > super(key + '+mtime', options).to_i)
      logger.info("Cached content stale (#{mtime.to_i} > #{super(key + '+mtime', options).to_i}): #{key}")
      nil
    else
      super(key, options)
    end
  end
  
  def write_fragment(name, content, options = nil)
    return unless perform_caching
    options = options.dup
    mtime = options && options.delete(:mtime)
    
    key = fragment_cache_key(name)
    logger.info("Caching (#{content.length} bytes): #{key}")
    content = super(key, content, options)
    if content && mtime && mtime.respond_to?("to_i")
      logger.info("Caching (#{mtime.to_i}): #{key}+mtime")
      super(key + '+mtime', mtime.to_i.to_s, options)
    end
    content
  end
end
