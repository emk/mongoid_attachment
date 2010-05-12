require File.join(File.dirname(__FILE__), 'spec_helper')

class Email
  include Mongoid::Document
  include MongoidAttachment

  has_attachment :attachment
end

describe MongoidAttachment do
  describe "initialization" do
    it "should open files specified by pathnames" do
      path = fixture_path("example.txt")
      email = Email.new(:attachment => Pathname.new(path))
      email.attachment.read.should == "Example\n"
    end

    it "should not allow pathnames to be passed as strings (for security)" do
      lambda do
        Email.new(:attachment => fixture_path("example.txt"))
      end.should raise_error(/Must initialize attachments with Pathname or File objects/)
    end

    it "should read IO objects directly into the grid" do
      email = File.open(fixture_path("example.txt"), 'r') do |f|
        Email.new(:attachment => f)
      end
      email.attachment.read.should == "Example\n"
    end

  end
end
