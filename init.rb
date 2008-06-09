# Include hook code here
if config.respond_to?(:gems)
  config.gem 'ruby-openid', :lib => 'openid', :version => '>=2.0.4'
else
  begin
    require 'openid'
  rescue LoadError
    begin
      gem 'ruby-openid', '>=2.0.4'
    rescue Gem::LoadError
      puts 'Install openid gem: ruby-openid'
    end
  end
end

config.to_prepare do
  ActionController::Base.send :include, OpenidWrapper
  ActionController::Base.send :include, Authentication
end
