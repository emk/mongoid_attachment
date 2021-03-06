require File.join(File.dirname(__FILE__), 'spec_helper')

class Email
  include Mongoid::Document
  include MongoidAttachment

  has_attachment :attachment
end

class Album
  include Mongoid::Document
  include MongoidAttachment
  embeds_many :pictures, :dependent => :destroy
end

class Picture
  include Mongoid::Document
  include MongoidAttachment
  embedded_in(:album, :inverse_of => :pictures)
  has_attachment :image
end

describe MongoidAttachment do
  describe "initialization" do
    describe "by pathname" do
      before do
        path = fixture_path("example.txt")
        @email = Email.new(:attachment => Pathname.new(path))
      end

      it "should store the specified file in the grid" do
        @email.attachment.read.should == "Example\n"
      end
      
      it "should record the filename" do
        @email.attachment.filename.should == "example.txt"
      end

      it "should guess the content_type" do
        @email.attachment.content_type.should == "text/plain"
      end
    end

    it "should not allow pathnames to be passed as strings (for security)" do
      lambda do
        Email.new(:attachment => fixture_path("example.txt"))
      end.should raise_error(/Must initialize attachments with Pathname or IO objects/)
    end

    describe "using an IO object" do
      before do
        @email = File.open(fixture_path("example.txt"), 'r') do |f|
          Email.new(:attachment => f)
        end
      end

      it "should read the data directly into the grid" do
        @email.attachment.read.should == "Example\n"
      end

      it "should record the pathname if present" do
        @email.attachment.filename.should == "example.txt"
      end

      it "should guess a MIME type if the pathname is present" do
        @email.attachment.content_type.should == "text/plain"
      end
    end

    describe "using an IO object with no path information" do
      before do
        @email = StringIO.open("In-memory string", 'r') do |f|
          Email.new(:attachment => f)
        end
      end

      it "should read the data directly into the grid" do
        @email.attachment.read.should == "In-memory string"
      end
      
      it "should have no filename and a generic content_type" do
        @email.attachment.filename.should be_nil
        @email.attachment.content_type.should == "binary/octet-stream"
      end
    end

    describe "using an IO object with extra CGI-related fields" do
      before do
        @email = File.open(fixture_path("example.txt"), 'r') do |f|
          # Create a fake CGI attachment the hard way.  The CGI module never
          # exports the IO subclasses it creates; but instead builds them by
          # hand like this each time.
          (class << f; self; end).class_eval do
            define_method(:original_filename) { "example.txt" }
            define_method(:content_type) { "text/plain" }
          end
          Email.new(:attachment => f)
        end
      end

      it "should read the data directly into the grid" do
        @email.attachment.read.should == "Example\n"
      end

      it "should record original_filename as filename" do
        @email.attachment.filename.should == "example.txt"
      end
     
      it "should record content_type" do
        @email.attachment.content_type.should == "text/plain"
      end
    end
  end  

  it "should return nil if no attachment is present" do
    Email.new.attachment.should be_nil
  end

  it "should destroy the attachment when the document is deleted" do
    path = fixture_path("example.txt")
    email = Email.create!(:attachment => Pathname.new(path))
    attachment_id = email.attachment_id
    email.destroy
    attachment_id.should have_been_removed_from_grid
  end

  it "should destroy the attachment when a nested document is destroyed" do
    pic = Picture.new(:image => Pathname.new(fixture_path("example.txt")))
    album = Album.create!(:pictures => [pic])
  
    image_id = pic.image_id
    album.pictures.destroy_all
    image_id.should have_been_removed_from_grid
  end

  it "should destroy nested attachments when a document is destroyed" do
    pic = Picture.new(:image => Pathname.new(fixture_path("example.txt")))
    album = Album.create!(:pictures => [pic])

    image_id = pic.image_id
    album.destroy
    image_id.should have_been_removed_from_grid
  end
  
  it "should delete the old attachment when nil is assigned" do
    path = fixture_path("example.txt")
    email = Email.create!(:attachment => Pathname.new(path))
    old_attachment_id = email.attachment_id
    email.attachment = nil
    old_attachment_id.should have_been_removed_from_grid
  end

  it "should delete the old attachment when a new attachment is assigned" do
    path = fixture_path("example.txt")
    email = Email.create!(:attachment => Pathname.new(path))
    old_attachment_id = email.attachment_id
    email.attachment = Pathname.new(fixture_path("example2.txt"))
    old_attachment_id.should have_been_removed_from_grid
  end

  context "memoization" do
    it "should reuse the same GridIO object for multiple accesses" do
      path = fixture_path("example.txt")
      email = Email.create!(:attachment => Pathname.new(path))
      email.attachment.should === email.attachment
    end

    it "should unmemoize the GridIO object during assignment" do
      path = fixture_path("example.txt")
      email = Email.create!(:attachment => Pathname.new(path))
      old = email.attachment
      email.attachment = Pathname.new(fixture_path("example2.txt"))
      email.attachment.should_not === old
    end

    it "should unmemoize during reload, but keep the object" do
      path = fixture_path("example.txt")
      email = Email.create!(:attachment => Pathname.new(path))
      old = email.attachment
      email.reload
      email.attachment.should_not === old
      email.attachment.filename.should == "example.txt"
    end
  end

  # it should offer some kind content transformation API (for encryption, etc.)
end
