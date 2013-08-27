module Sequel
  module Plugins
    module XCti

      def self.apply(model, opts={})
        model.plugin :lazy_attributes
        model.plugin :dirty
      end

      def self.configure(model, opts={})
        tbl = model.table_name
        col = model.dataset.db.from(tbl).columns

        cti = { base: model, tables: { tbl => col } }.merge(opts)
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
            tbl = implicit_table_name

            set_dataset(parent.dataset.join(tbl, [join_using]))
            dataset.row_proc = parent.dataset.row_proc

            col = dataset.db.from(tbl).columns
            col.each { |c| define_lazy_attribute_getter(c) }

            @cti = opt.dup
            @cti[:tables] = @cti[:tables].dup.merge({ tbl => col })
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
          prk = values[primary_key]

          cti[:tables].each do |tbl, col|
            val = values.select{ |k,v| col.include?(k) }

            val[primary_key] = prk if prk
            rtn = model.db.from(tbl).insert(val)

            prk ||= rtn
          end

          values[primary_key] = prk
        end

        def _update(columns)
          cti[:tables].keys.reverse.each do |tbl|
            col = cti[:tables][tbl]
            val = values.select{ |k,v| column_changed?(k) && col.include?(k) }
            model.db.from(tbl).where(primary_key => pk).
              update(val) unless val.empty?
          end
        end

        def _delete
          cti[:tables].keys.reverse.each do |tbl|
            model.db.from(tbl).where(primary_key => pk).delete
          end
        end

        def cti
          model.instance_variable_get(:@cti)
        end

      end

    end
  end
end

