require 'mongoid'

module MongoidAttachment
  module ClassMethods
    def has_attachment(name)
      id_field_getter_name = "#{name}_id".to_sym
      id_field_setter_name = "#{id_field_getter_name}=".to_sym

      field id_field_getter_name, :type => Mongo::ObjectID

      define_method("#{name}=".to_sym) do |value|
        obj_id = File.open(value, 'r') {|f| grid.put(f) }
        puts obj_id.inspect
        send(id_field_setter_name, obj_id)
      end

      define_method(name) do
        puts send(id_field_getter_name).inspect
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
