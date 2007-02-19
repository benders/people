# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

require 'base64'

class ApplicationController < ActionController::Base
  # Pick a unique cookie name to distinguish our session data from others'
  session :session_key => '_people_session_id'

  before_filter :get_http_auth

  protected

  def get_http_auth
    username, password = nil, nil
    authtype, token = nil, nil
    # extract authorisation credentials 
    if request.env.has_key? 'X-HTTP_AUTHORIZATION' 
      # try to get it where mod_rewrite might have put it 
      authtype, token = request.env['X-HTTP_AUTHORIZATION'].to_s.split 
    elsif request.env.has_key? 'HTTP_AUTHORIZATION'
      # this is the regular location
      authtype, token = request.env['HTTP_AUTHORIZATION'].to_s.split
    end
    return nil unless authtype
    if authtype.upcase == "BASIC"
      username, password = Base64.decode64(token).split(':', 2)
      @http_auth = {:username => username, :password => password}
    else
      logger.warn("Unsupported Auth mechanism #{authtype}")
      return false
    end
    @http_auth ||= nil
  end
  
  # This uses the @http_auth instance variable, so it must be run after get_http_auth
  def require_http_auth
    unless @http_auth
      response.headers['WWW-Authenticate'] = 'Basic realm="Slackworks"'
      render(:status => 401, :text => "Authentication Required")
      false
    else
      @http_auth
    end
  end
  
  def require_edit
    unless @http_auth[:username] == params[:id] || Person.admin?(@http_auth[:username])
      render(:status => 403, :text => "Self Editing Only")
      return false
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
