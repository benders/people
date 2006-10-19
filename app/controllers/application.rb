# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base

  protected
  def authenticate
    unless session[:login]
      @session[:return_to] = @request.request_uri
      redirect_to :controller => "login" 
      return false
    end
  end

end