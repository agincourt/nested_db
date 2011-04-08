# Provide a simple gemspec so you can easily use your enginex
# project in your rails apps through git.
Gem::Specification.new do |s|
  s.name = "nested_db"
  s.summary = "A Mongoid-based customer-facing DB."
  s.description = "A Mongoid-based customer-facing DB."
  s.files = Dir["{app,lib,config}/**/*"] + ["MIT-LICENSE", "Rakefile", "Gemfile", "README.rdoc"]
  s.version = "0.0.1"
end