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

Spec::Matchers.define :have_been_removed_from_grid do
  match do |grid_id|
    begin
      Email.grid.get(grid_id)
      false
    rescue => e
      (e.to_s =~ /Could not open file matching/) ? true : false
    end
  end
end

Mongoid.configure do |config|
  config.master = Mongo::Connection.new.db('mongoid_attachment_test')
end

Spec::Runner.configure do |config|  
end
