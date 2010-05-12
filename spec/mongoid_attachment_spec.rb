require File.join(File.dirname(__FILE__), 'spec_helper')

class Email
  include Mongoid::Document
  include MongoidAttachment

  has_attachment :attachment
end

describe MongoidAttachment do
  it "should be initializable using a path" do
    email = Email.new(:attachment => fixture_path("example.txt"))
    email.attachment.read.should == "Example\n"
  end
end
