require 'mongoid'

module MongoidAttachment
  module ClassMethods
    # Return the Mongo::Grid object associated with this class.
    def grid
      @grid ||= Mongo::Grid.new(Mongoid.configure.master)
    end
    
    # Put a file (specified using a Pathname or IO object) onto the grid
    # and return a Mongo::ObjectID.
    #
    # For security reasons, you can't pass a pathname as a string, but must
    # always use an explicit Pathname.  This makes it more difficult for a
    # malicious HTTP client to pass a string when the server expected a
    # file input, and thereby trick the server into reading a file off the
    # server's own filesystem and storing it on the grid.
    def put_on_grid(path_or_io)
      case path_or_io
      when Pathname
        File.open(path_or_io, 'r') do |f|
          grid.put(f, :filename => path_or_io.basename.to_s)
        end
      when IO
        have_cgi_metadata = [:original_filename, :content_type].all? do |method|
          path_or_io.respond_to?(method)
        end
        if have_cgi_metadata
          grid.put(path_or_io,
                   :filename => path_or_io.original_filename,
                   :content_type => path_or_io.content_type)
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

      field id_field_getter_name, :type => Mongo::ObjectID

      define_method("#{name}=".to_sym) do |value|
        obj_id = self.class.put_on_grid(value)
        send(id_field_setter_name, obj_id)
      end

      define_method(name) do
        self.class.grid.get(send(id_field_getter_name))
      end
    end
  end

  # :nodoc: Called when MongoidAttachment is included by a class.
  def self.included(base)
    base.extend(ClassMethods)
  end
end
