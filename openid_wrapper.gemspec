Gem::Specification.new do |spec|
  spec.name    = 'openid_wrapper'
  spec.version = '0.1.9'
  spec.date    = '2009.04.09'

  spec.summary = 'Openid wrapper for Rails'
  spec.description = 'Openid wrapper for Rails yeah'
  spec.rubyforge_project = 'openid_wrapper'

  spec.authors = ['Priit Tamboom']
  spec.email = 'priit@mx.ee'
  spec.homepage = 'http://priit.mx.ee/openid_wrapper'

  spec.add_dependency('ruby-openid', '>= 2.1.2')
  spec.has_rdoc = true
  spec.rdoc_options = ['--main', 'README.rdoc']
  spec.rdoc_options << '--inline-source' << '--charset=UTF-8'
  spec.extra_rdoc_files = ['README.rdoc', 'MIT-LICENSE', 'CHANGELOG.rdoc']
  spec.files = %w[README.rdoc CHANGELOG.rdoc MIT-LICENSE lib/openid_wrapper.rb lib/openid_wrapper/openid_wrapper.rb lib/openid_wrapper/openid_ar_store.rb lib/openid_wrapper/nonce.rb lib/openid_wrapper/association.rb rails/init.rb]
end
