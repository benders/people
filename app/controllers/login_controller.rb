class LoginController < ApplicationController
  def index
    render :action => "login" 
  end

  def login
    if params[:username] and params[:password]
      if Person.authenticate(params[:username], params[:password])
        session[:user] = params[:username]
      else
        flash[:notice] = "Invalid credentials" 
      end
    else
      flash[:notice] = "Please enter username and password" 
    end
    if session[:return_to]
      redirect_to session[:return_to]
      session[:return_to] = nil
    else
      redirect_to people_url 
    end
  end
end
