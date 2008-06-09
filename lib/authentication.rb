module Authentication

# Sugar API shared with views as well
    def self.included(base)
      base.send :helper_method, :admin?, :user?, :current_user, :logged_in?
    end

    def admin?
      role_as?(:admin)
    end
    
    def user?
      role_as?(:user)
    end

    def current_user
      @current_user ||= User.find_by_id(session[:current_user_id])
    end
    
    def current_user=(user)
      @current_user = user
      session[:current_user_id] = user.id
    end

    def logged_in?
      current_user ? true : false
    end


# before_filters for controllers
  def login_required
    redirect_to login_path if !logged_in?
  end

  def admin_required
    redirect_to login_path unless role_as? :admin
  end
  
  def user_required
    redirect_to login_path unless role_as? :user
  end

  def role_as?(role)
    if logged_in?
      current_user.role?(role)
    else
     false
    end 
  end
end
