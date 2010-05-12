require 'mongoid'

module MongoidAttachment
  module ClassMethods
    def has_attachment(name)
      id_field_getter_name = "#{name}_id".to_sym
      id_field_setter_name = "#{id_field_getter_name}=".to_sym

      field id_field_getter_name, :type => Mongo::ObjectID

      define_method("#{name}=".to_sym) do |value|
        # DO NOT ADD String HERE!  Strings can be generated from CGI
        # parameters, allowing malicious POST requests to read arbitrary
        # files from the file system.
        case value
        when Pathname
          obj_id = File.open(value, 'r') {|f| grid.put(f) }
        when IO
          obj_id = grid.put(value)
        else
          raise("Must initialize attachments with Pathname or File objects, " +
                "not #{value.inspect}")
        end
        send(id_field_setter_name, obj_id)
      end

      define_method(name) do
        grid.get(send(id_field_getter_name))
      end
    end
  end

  module InstanceMethods
    def grid
      @grid ||= Mongo::Grid.new(Mongoid.configure.master)
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)
  end
end
