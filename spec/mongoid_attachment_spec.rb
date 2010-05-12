require File.join(File.dirname(__FILE__), 'spec_helper')

class Email
  include Mongoid::Document
  include MongoidAttachment

  has_attachment :attachment
end

describe MongoidAttachment do
  describe "initialization" do
    it "should treat strings as paths to files" do
      email = Email.new(:attachment => fixture_path("example.txt"))
      email.attachment.read.should == "Example\n"
    end

    it "should read open files directly into the grid" do
      email = File.open(fixture_path("example.txt"), 'r') do |f|
        Email.new(:attachment => f)
      end
      email.attachment.read.should == "Example\n"
    end
  end
end
