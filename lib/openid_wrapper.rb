require 'openid'
require 'openid/extensions/sreg'
require 'openid/extensions/pape'
require 'openid_ar_store'

module OpenidWrapper

protected
  def openid_request(options = {})
    options.assert_valid_keys(
      :openid_identifier, :return_url, :realm, :immediate_mode, :required, :optional
    )
    
    identifier = options[:openid_identifier] || params[:openid_identifier]
    return_url = options[:return_url]        || complete_sessions_url
    realm      = options[:realm]             || (self.request.protocol + '*.' + self.request.domain)
    immediate  = options[:immediate_mode]    || params[:immediate_mode] || false

    begin
      openid_request = consumer.begin(identifier)
    rescue OpenID::OpenIDError => e
      flash[:error] = "Discovery failed for #{identifier}: #{e}"
      return redirect_to :action => 'new'
    end

    required = options[:required] || params[:required]
    optional = options[:optional] || params[:optional]
    sreg_request = simple_registration_request(required, optional)
    openid_request.add_extension(sreg_request)

    redirect_to openid_request.redirect_url(realm, return_url, immediate)
  end

  def openid_response
    # The return_to and its arguments are verified, so you need to pass in
    # the base URL and the arguments.  With Rails, the params method mashes
    # together parameters from GET, POST, and the path, so you'll need to pull
    # off the "path parameters"
    params_without_paths = params.reject {|key,value| request.path_parameters.include?(key)}
    
    # current_url: Extract the URL of the current request from your
    # application's web request framework and specify it here to have it
    # checked against the openid.return_to value in the response.  Do not
    # just pass <tt>args['openid.return_to']</tt> here; that will defeat the
    # purpose of this check.  (See OpenID Authentication 2.0 section 11.1.)
    # 
    # current_url will be checked against the opeinid.return_to value in the response.
    current_url = request.protocol + request.host_with_port + request.relative_url_root + request.path
    @openid_response = consumer.complete(params_without_paths, current_url)
    return @openid_response
  end
  
  def openid_params
    return nil unless @openid_response

    identifier = @openid_response.endpoint.display_identifier
    simple_registration = OpenID::SReg::Response.from_success_response(@openid_response).data

    openid_params = HashWithIndifferentAccess.new(simple_registration)
    openid_params.merge!(:openid_identifier => identifier)
    return openid_params
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
end
