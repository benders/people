class LoginController < ApplicationController
  def index
    render :action => "login" 
  end

  def login
    # the actual login form
    if @params[:username] and @params[:password]
      if Person.login(@params[:username], @params[:password])
        session[:login] = {:value => @params[:username]}
      else
        flash[:notice] = "Invalid credentials" 
      end
    else
      flash[:notice] = "Please enter username and password" 
    end
    redirect_to @session[:return_to]
  end
end
