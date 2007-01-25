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
end
