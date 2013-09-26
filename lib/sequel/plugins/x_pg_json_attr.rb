module Sequel
  module Plugins
    class XPgJsonAttr

      def self.apply(model, opts={})
        model.db.extension :pg_json
      end

      def self.configure(model, column)
        model.class_variable_set(:@@xja, {
          column: column
        })
      end

      module ClassMethods

        def json_accessor(name, type=Object)
          json_getter(name, type)
          json_setter(name)
        end

        def json_getter(name, type=Object)
          define_method(name) do
            column = self.class.class_variable_get(:@@xja)[:column]
            return nil unless values[column]

            colv = values[column][name]
            retv = case type.__id__
                   when Time.__id__ then Time.at(colv)
                   when BigDecimal.__id__ then BigDecimal.new(colv)
                   when Date.__id__ then Date.jd(colv)
                   else colv
                   end

            retv
          end
        end

        def json_setter(name)
          define_method("#{name}=") do |setv|
            column = self.class.class_variable_get(:@@xja)[:column]

            colv = case setv
                   when Time then setv.to_i
                   when BigDecimal then setv.to_s
                   when Date then setv.jd
                   else setv
                   end

            values[column] = (values[column] ||= {}).merge(name => colv)
          end
        end

      end

      module InstanceMethods

        def before_save
          column = self.class.class_variable_get(:@@xja)[:column]
          values[column] = Sequel.pg_json(values[column]) if values[column]
        end

      end

    end
  end
end

