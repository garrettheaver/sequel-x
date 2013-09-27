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

        def json_accessor(name, setter=nil, getter=nil)
          json_getter(name, getter || setter)
          json_setter(name, setter)
        end

        def json_getter(name, getter=nil)
          define_method(name) do
            column = self.class.class_variable_get(:@@xja)[:column]

            return nil unless values[column]
            colv = values[column][name] || values[column][name.to_s]

            retv = if Proc === getter
                     getter.call(colv)
                   else
                     case getter.__id__
                     when Time.__id__ then Time.at(colv)
                     when BigDecimal.__id__ then BigDecimal.new(colv)
                     when Date.__id__ then Date.jd(colv)
                     else colv
                     end
                   end

            retv
          end
        end

        def json_setter(name, setter=nil)
          define_method("#{name}=") do |setv|
            column = self.class.class_variable_get(:@@xja)[:column]

            colv = if Proc === setter
                     setter.call(setv)
                   else
                     case setv
                     when Time then setv.to_i
                     when BigDecimal then setv.to_s
                     when Date then setv.jd
                     else setv
                     end
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

