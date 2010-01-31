require "openid"

config.to_prepare do
  ActionController::Base.send :include, OpenidWrapper
end

RAILS_DEFAULT_LOGGER.info "** openid_wrapper: initialized properly from #{__FILE__}"
