require "digest"

class SessionsController < ApplicationController
  skip_before_action :require_login, only: %i[new create]

  def new
  end

  def create
    if valid_credentials?
      session[:admin_authenticated] = true
      redirect_to root_path
    else
      flash.now[:alert] = "아이디 또는 비밀번호가 올바르지 않습니다."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to new_session_path
  end

  private

  def valid_credentials?
    secure_equal?(params[:username].to_s, ENV.fetch("ADMIN_USERNAME", "admin")) &&
      secure_equal?(params[:password].to_s, ENV.fetch("ADMIN_PASSWORD", "change-me"))
  end

  def secure_equal?(given, expected)
    given_digest = Digest::SHA256.hexdigest(given)
    expected_digest = Digest::SHA256.hexdigest(expected)
    ActiveSupport::SecurityUtils.secure_compare(given_digest, expected_digest)
  end
end
