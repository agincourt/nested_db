Gem::Specification.new do |s|
  s.name = "nested_db"
  s.summary = "A Mongoid-based customer-facing DB."
  s.description = "A Mongoid-based customer-facing DB."
  s.files = Dir["{app,lib,config}/**/*"] + ["MIT-LICENSE", "Rakefile", "Gemfile", "README.rdoc"]
  s.version = "0.0.1"
  s.authors = ['Ryan Townsend']
  
  s.add_dependency("mongo",    ["= 1.2.4"])
  s.add_dependency("bson_ext", ["= 1.2.4"])
  s.add_dependency("mongoid",  ["= 2.0.0"])
                                 
  s.add_dependency("haml",     ["= 3.1.0.alpha.147"])
  s.add_dependency("liquid",   ["= 2.2.2"])
  s.add_dependency("RedCloth", ["= 4.2.7"])
  
  s.add_dependency("carrierwave", ["= 0.5.3"])
  s.add_dependency("mini_magick", ["= 3.2"])
  s.add_dependency("fog",         ["= 0.7.2"])
end