module Authentication

# Sugar API shared with views as well
  def self.included(base)
    base.send :helper_method, :admin?, :user?, :current_user, :logged_in?, :return_path
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
    redirect_to_login_path 'Please login!' if not logged_in?
  end

  def admin_required
    redirect_to_login_path 'You must have admin rights to access this page.' if not role_as? :admin
  end
  
  def user_required
    redirect_to_login_path 'Please login!' if not role_as? :user
  end
  
  def store_return_path
    session[:return_path] = request.request_uri
  end

  def return_path=(path)
    session[:return_path] = path
  end
  
  def return_path
    session[:return_path]
  end

  def redirect_back_or(path)
    redirect_to(return_path || path)
    session[:return_path] = nil
  end
  
  alias :redirect_back_or_default :redirect_back_or
  
  def role_as?(role)
    if logged_in?
      current_user.role?(role)
    else
     false
    end 
  end
  
private
  def redirect_to_login_path(message = nil)
    store_return_path
    flash[:notice] = message
    redirect_to login_path
  end
end
