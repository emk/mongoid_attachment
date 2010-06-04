require 'mongoid'

module MongoidAttachment
  # Return the macro used to create this pseudo-association.
  def self.macro
    :has_attachment
  end

  module ClassMethods
    # Return the Mongo::Grid object associated with this class.
    def grid
      @grid ||= Mongo::Grid.new(Mongoid.configure.master)
    end
    
    # Put a file (specified using a Pathname or IO object) onto the grid
    # and return a BSON::ObjectID.
    #
    # For security reasons, you can't pass a pathname as a string, but must
    # always use an explicit Pathname.  This makes it more difficult for a
    # malicious HTTP client to pass a string when the server expected a
    # file input, and thereby trick the server into reading a file off the
    # server's own filesystem and storing it on the grid.
    def put_on_grid(path_or_io)
      if path_or_io.instance_of?(Pathname)
        File.open(path_or_io, 'r') do |f|
          grid.put(f, :filename => path_or_io.basename.to_s)
        end
      elsif [:eof?, :close].all? {|m| path_or_io.respond_to?(m) }
        have_cgi_metadata = [:original_filename, :content_type].all? do |method|
          path_or_io.respond_to?(method)
        end
        if have_cgi_metadata
          grid.put(path_or_io,
                   :filename => path_or_io.original_filename,
                   :content_type => path_or_io.content_type)
        elsif path_or_io.respond_to?(:path) && !path_or_io.path.nil?
          grid.put(path_or_io, :filename => File.basename(path_or_io.path))
        else
          grid.put(path_or_io)
        end
      else
        raise("Must initialize attachments with Pathname or IO objects, " +
              "not #{path_or_io.inspect}")
      end
    end

    # Declare an attachment named +name+.  This will create a setter and a
    # getter method.
    def has_attachment(name)
      id_field_getter_name = "#{name}_id".to_sym
      id_field_setter_name = "#{id_field_getter_name}=".to_sym

      field id_field_getter_name, :type => BSON::ObjectID

      define_method("#{name}=".to_sym) do |value|
        unmemoize(name)

        # Remove any existing file from the grid.
        old_id = send(id_field_getter_name)
        unless old_id.nil?
          self.class.grid.delete(old_id)
        end

        # Store the new file on the grid, or set our ID to nil if we have
        # no file.
        if value.nil?
          send(id_field_setter_name, nil)
        else
          id = self.class.put_on_grid(value)
          send(id_field_setter_name, id)
        end
      end

      define_method(name) do
        memoized(name) do
          id = send(id_field_getter_name)
          id.nil? ? nil : self.class.grid.get(id)
        end
      end

      # This makes sure we get unmemoized on reloads, and helps us with
      # recursive destroy.
      opts = Mongoid::Associations::Options.new(:name => name,
                                                :foreign_key =>
                                                  id_field_getter_name)
      associations[name] =
        Mongoid::Associations::MetaData.new(MongoidAttachment, opts)
    end
  end

  module InstanceMethods
    # Recursively walk down through embedded documents, destroying
    # any attachments we find.
    def destroy_all_attachments
      associations.each do |name, metadata|
        association = metadata.association
        if ::MongoidAttachment == association
          send("#{name}=", nil)
        elsif ::Mongoid::Associations::EmbedsOne == association
          send(name).destroy_all_attachments
        elsif ::Mongoid::Associations::EmbedsMany == association
          send(name).each {|d| d.destroy_all_attachments }
        end
      end
    end    
  end

  # :nodoc: Called when MongoidAttachment is included by a class.
  def self.included(base)
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)

    # KLUDGE - Handle non-recursive before_destroy with brute force.  Note
    # that this may cause unnecessary recursion if before_destroy ever gets
    # fixed to work correctly.
    base.before_destroy :destroy_all_attachments
  end
end
