require 'rubygems'
require 'bundler'

Bundler.setup(:default, :development)

require 'spec'
require 'spec/autorun'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(File.dirname(__FILE__)), 'lib'))

require 'mongoid_attachment'

Spec::Runner.configure do |config|  
end
