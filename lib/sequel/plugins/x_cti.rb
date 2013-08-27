module Sequel
  module Plugins
    module XCti

      def self.apply(model, opts={})
        model.plugin :lazy_attributes
      end

      def self.configure(model, opts={})
        tables = [model.table_name].freeze
        cti = { base: model, tables: tables }.merge(opts)
        model.instance_variable_set(:@cti, cti)

        model.instance_eval do
          dataset.row_proc = lambda do |row|
            key, models = cti[:key], cti[:models]
            constantize(models[row[key]]).call(row)
          end
        end
      end

      module ClassMethods

        def inherited(subclass)
          parent, join_using, opt = self, primary_key, @cti

          subclass.instance_eval do
            table = implicit_table_name

            @cti = opt.dup
            @cti[:tables] = (opt[:tables].dup << table).freeze

            set_dataset(parent.dataset.join(table, [join_using]))
            dataset.row_proc = parent.dataset.row_proc

            columns = dataset.db.from(table).columns
            columns.each { |c| define_lazy_attribute_getter(c) }
            set_columns(columns)
          end

          super
        end

      end

      module InstanceMethods

        def before_create
          key, inv = cti[:key], cti[:models].invert
          send("#{key}=", inv[model] || inv[model.name])
          super
        end

        private

        def _insert
          key = values[primary_key]

          cti[:tables].each do |tbl|
            val = cti_values(tbl)
            next if val.empty?

            val[primary_key] = key if key
            rtn = model.db.from(tbl).insert(val)

            key ||= rtn
          end

          values[primary_key] = key
        end

        def _update(columns)
          cti[:tables].reverse.each do |tbl|
            val = cti_values(tbl)
            model.db.from(tbl).where(primary_key => pk).
              update(val) unless val.empty?
          end
        end

        def _delete
          cti[:tables].reverse.each do |tbl|
            model.db.from(tbl).where(primary_key => pk).delete
          end
        end

        def cti_values(table)
          columns = model.db.from(table).columns
          values.select{ |k,v| columns.include?(k) }
        end

        def cti
          model.instance_variable_get(:@cti)
        end

      end

    end
  end
end

