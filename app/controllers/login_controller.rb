class LoginController < ApplicationController
  def index
    render :action => "login" 
  end

  def login
    # the actual login form
    if @params[:username] and @params[:password]
      person = Person.new(@params[:username])
      if person.login(@params[:password])
        @session[:user] = {:value => @params[:username]}
      else
        @flash[:notice] = "Invalid credentials" 
      end
    else
      flash[:notice] = "Please enter username and password" 
    end
    redirect_to @session[:return_to]
  end
end
