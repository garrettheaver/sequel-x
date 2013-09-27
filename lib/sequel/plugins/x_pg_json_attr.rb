module Sequel
  module Plugins
    class XPgJsonAttr

      def self.apply(model, opts={})
        model.db.extension :pg_json
      end

      def self.configure(model, column)
        model.class_variable_set(:@@xja, {
          column: column,

          getters: {
            Time => -> v { Time.at(v) },
            BigDecimal => -> v { BigDecimal.new(v) },
            Date => -> v { Date.jd(v) }
          },

          setters: {
            Time => -> t { t.to_f },
            BigDecimal => -> d { d.to_s },
            Date => -> d { d.jd }
          }
        })
      end

      module ClassMethods

        def json_accessor(name, setter=nil, getter=nil)
          json_getter(name, getter || setter)
          json_setter(name, setter)
        end

        def json_getter(name, getter=nil)
          define_method(name) do
            config = self.class.class_variable_get(:@@xja)

            getter = config[:getters][getter] || getter
            column = config[:column]

            return nil unless values[column]
            colv = values[column][name.to_s]

            Proc === getter ? getter.call(colv) : colv
          end
        end

        def json_setter(name, setter=nil)
          define_method("#{name}=") do |setv|
            config = self.class.class_variable_get(:@@xja)

            setter = config[:setters][setter] || setter
            column = config[:column]

            colv = Proc === setter ? setter.call(setv) : setv
            values[column] = (values[column] ||= {}).merge(name.to_s => colv)
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

