$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "pgate_model/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "pgate_model"
  s.version     = PgateModel::VERSION
  s.authors     = ["jimmy"]
  s.email       = ["solo123@21cn.com"]
  s.homepage    = "http://www.pooul.cn"
  s.summary     = "Data models for pgate"
  s.description = "Share data models"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.0.0", ">= 5.0.0.1"
  s.add_dependency "httparty"
  s.add_development_dependency "sqlite3"
end
