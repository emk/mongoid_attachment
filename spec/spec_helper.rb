require 'rubygems'
require 'bundler'

Bundler.setup(:default, :development)

require 'spec'
require 'spec/autorun'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(File.dirname(__FILE__)), 'lib'))

require 'mongoid_attachment'

def fixture_path(path)
  File.join(File.dirname(__FILE__), 'fixtures', path)
end

Mongoid.configure do |config|
  config.master = Mongo::Connection.new.db('mongoid_attachment_test')
end

Spec::Runner.configure do |config|  
end
