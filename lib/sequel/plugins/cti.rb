module Sequel
  module Plugins
    module Cti

      def self.apply(model, opts={})
        model.plugin :lazy_attributes
      end

      def self.configure(model, opts={})
        model.instance_variable_set(:@cti, opts)
        model.instance_eval do
          dataset.row_proc = lambda do |row|
            key, map = opts[:key], opts[:map]
            constantize(map[row[key]]).call(row)
          end
        end
      end

      module ClassMethods

        def inherited(subclass)
          parent, join_using = self, primary_key
          subclass.instance_variable_set(:@cti, @cti)

          subclass.instance_eval do
            table = implicit_table_name

            set_dataset(parent.dataset.join(table, [join_using]))
            dataset.row_proc = parent.dataset.row_proc

            dataset.db.from(table).columns.each do |col|
              define_lazy_attribute_getter(col)
            end
          end

          super
        end

      end

      module InstanceMethods

        def before_create
          key, inv = cti[:key], cti[:map].invert
          send("#{key}=", inv[model] || inv[model.name])
          super
        end

        def _insert

        end

        private

        def cti
          model.instance_variable_get(:@cti)
        end

      end

    end
  end
end

