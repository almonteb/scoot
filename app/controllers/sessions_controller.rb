# This controller handles the login/logout function of the site.
class SessionsController < ApplicationController
  skip_before_filter :public_and_logged_in
  
  # render new.rhtml
  def new
  end

  def create
    password_authentication(params[:email_or_login], params[:password])
  end

  def destroy
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    flash[:notice] = "You have been logged out."
    redirect_back_or_default('/')
  end

  protected

  def password_authentication(email_or_login, password)
    self.current_user = User.authenticate(email_or_login, password)
    if logged_in?
      successful_login
    else
      failed_login("Email and/or password didn't match, please try again.")
    end
  end

  def failed_login(message = "Authentication failed.",method="")
    if method==''
      flash.now[:error] = message
      render :action => 'new'
    else
      redirect_to login_path(:method=>method)
      flash[:error] = message
    end
  end

  def successful_login
    if params[:remember_me] == "1"
      self.current_user.remember_me
      cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
    end
    redirect_back_or_default('/')
    flash[:notice] = "Logged in successfully"
  end

end
