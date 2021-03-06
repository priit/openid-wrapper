require 'openid'
require 'openid/extensions/sreg'
require 'openid/extensions/pape'
require File.expand_path(File.dirname(__FILE__) + '/openid_ar_store')

module OpenidWrapper
  def self.included(base)
    base.send :helper_method, :openid_params
  end

protected
  def begin_openid(options = {}, &check_user)
    options.assert_valid_keys(
      :openid_identifier, :return_url, :error_redirect, :realm,
      :immediate_mode, :required, :optional,

    # You can pass arguments to openid_params, so you can access it from complete_openid with openid_params.
    # Example: begin_openid :params => {:subdomain => params[:subdomain]} in your create method and
    # in you can access them at complete method like openid_params[:subdomain] or params[:subdomain].
      :openid_params, 
 
    # redirect_to is sugar shortcut instead of writing :openid_params => {:redirect_to => params[:redirect_to]}
    # later you can access it from openid_params[:redirect_to]
      :redirect_to 
    )
 
    # trying to be as flexible as possible
    identifier = options[:openid_identifier]  || params[:openid_identifier] || ''
    return_url = options[:return_url]         || complete_sessions_url
    error_redirect = options[:error_redirect] || request.env['HTTP_REFERER'] || '/'
    realm      = options[:realm]              || current_realm
    immediate  = options[:immediate_mode]     || params[:immediate_mode] || false
    
    begin
      @openid_request = consumer.begin(identifier.strip)
    rescue OpenID::OpenIDError => e
      flash[:error] = "Discovery failed for #{identifier}: #{e}"
      return redirect_to(error_redirect)
    end
    
    required = options[:required] || params[:required]
    optional = options[:optional] || params[:optional]
    sreg_request = simple_registration_request(required, optional)
    @openid_request.add_extension(sreg_request)
    
    if check_user
      normalized_identifier = @openid_request.endpoint.claimed_id
      yield normalized_identifier
    end

    add_to_params(options[:params])
    add_to_params(:redirect_to => params[:redirect_to]) unless params[:redirect_to].nil?

    redirect_to @openid_request.redirect_url(realm, return_url, immediate)
  end
  
  alias :create_openid :begin_openid
  
  def complete_openid
    # For wrapper DEVS: 
    # The return_to and its arguments are verified, so you need to pass in
    # the base URL and the arguments.  With Rails, the params method mashes
    # together parameters from GET, POST, and the path, so you'll need to pull
    # off the "path parameters"
    params_without_paths = params.reject {|key,value| request.path_parameters.include?(key)}
    
    # For wrapper DEVS: 
    # about current_realm from OpenID gem: Extract the URL of the current 
    # request from your application's web request framework and specify it here
    # to have it checked against the openid.return_to value in the response.  Do not
    # just pass <tt>args['openid.return_to']</tt> here; that will defeat the
    # purpose of this check.  (See OpenID Authentication 2.0 section 11.1.)
    @openid_response = consumer.complete(params_without_paths, current_realm)

    # Add openid params to params[:openid]
    params[:openid] = openid_params

    return @openid_response
  end
  
  # For wrapper USERS:
  # openid_params is just a helper method to filter out openid parameters from params, so
  # you can directly save them to user model. By the way, you can access all them 
  # directly from rails params as well.
  def openid_params
    return nil if @openid_response.nil?

    simple_registration = OpenID::SReg::Response.from_success_response(@openid_response).data
    local_params = HashWithIndifferentAccess.new(simple_registration)

    # For wrapper USERS: 
    # Use openid_params[:openid] for user interface and 
    # use openid_params[:openid_identifier] for querying your database or 
    # authorization server or other identifier equality comparisons.

    # DOTO: I have to find out how much is display_identifier used before using it with identifier.
    # local_params.merge!(:openid => @openid_response.display_identifier)
    local_params.merge!(:openid_identifier => @openid_response.identity_url)
    
    # DOTO: find out other way to access openid_params pool.
    # Add custom params to openid_params pool.
    # local_params.merge!(@openid_response.message.get_args(:bare_namespace))
    
    return local_params
  end  
  
private
  def consumer
    OpenID::Consumer.new(session, ActiveRecordStore.new)
  end

  def simple_registration_request(required, optional)
    required ||= []
    optional ||= []

    valid_attributes = %w[nickname fullname email dob gender postcode country timezone language]

    if optional.size == 0 && required.size == 0
      optional = valid_attributes
    else
      (required + optional).each do |atr|
        raise "Invalid option: #{atr}. Must be one of: #{valid_attributes.join(', ')}" unless valid_attributes.index(atr)
      end
    end

    sreg_request = OpenID::SReg::Request.new
    sreg_request.request_fields(required, true) if required.size > 0
    sreg_request.request_fields(optional, false) if optional.size > 0
    return sreg_request
  end

  # For Wrapper DEVS:
  # current_realm will be checked against openid.return_to value. Read more from method complete_openid.
  def current_realm
    request.protocol + request.host_with_port + request.path
  end

  def add_to_params(args)
    return nil if @openid_request.nil?
    return nil if args.nil?
    
    args.each do |key,value|
      @openid_request.return_to_args[key.to_s] = value.to_s
    end
  end
end
