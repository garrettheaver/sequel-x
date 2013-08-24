require 'spec_helper'
require 'sequel/plugins/x_cti'

module Sequel
  module Plugins
    describe XCti do

      #        RT
      #       /  \
      #      A1  A2
      #     /
      #    B1

      db = Sequel.sqlite

      db.create_table(:rts) do
        primary_key :id, auto_increment: false
        Integer :fk, null: false
        String :rt, null: false
      end

      db[:rts].insert({ id: 1, fk: 1, rt: 'RT' })
      db[:rts].insert({ id: 2, fk: 2, rt: 'A1' })
      db[:rts].insert({ id: 3, fk: 3, rt: 'A2' })
      db[:rts].insert({ id: 4, fk: 4, rt: 'B1' })

      db.create_table(:a1s) do
        foreign_key :id, :rts, primary_key: true
        String :a1
      end

      db[:a1s].insert({ id: 2, a1: 'A1' })
      db[:a1s].insert({ id: 4, a1: 'A1' })

      db.create_table(:a2s) do
        foreign_key :id, :rts, primary_key: true
        String :a2
      end

      db[:a2s].insert({ id: 3, a2: 'A2' })

      db.create_table(:b1s) do
        foreign_key :id, :a1s, primary_key: true
        String :b1
      end

      db[:b1s].insert({ id: 4, b1: 'B1' })

      class ::RT < Sequel::Model(db)
        plugin :x_cti, key: :fk,
          map: { 1 => self, 2 => 'A1', 3 => 'A2', 4 => 'B1' }
      end

      class ::A1 < RT; end
      class ::A2 < RT; end
      class ::B1 < A1; end

      describe 'SELECT' do

        context 'via base class' do

          let(:instances) { RT.all }

          it 'loads all instance types' do
            assert_equal [RT, A1, A2, B1], instances.map(&:class)
          end

          it 'loads the correct attributes for each instance' do
            assert_equal 'RT', instances[0].rt
            assert_equal 'A1', instances[1].a1
            assert_equal 'A2', instances[2].a2
            assert_equal 'B1', instances[3].b1
          end

        end

        context 'via intermediate class' do
          it 'loads instances of that type and subclasses' do
            assert_equal [A1, B1], A1.all.map(&:class)
          end
        end

        context 'via leaf class' do
          it 'only loads instances of that type' do
            assert_equal [B1], B1.all.map(&:class)
          end
        end

      end

      describe 'INSERT' do

        let(:rt) { RT.create(rt: 'A').reload }
        let(:a1) { A1.create(rt: 'B', a1: 'C').reload }
        let(:b1) { B1.create(rt: 'D', a1: 'E', b1: 'F').reload }

        it 'creates instances with the correct type value' do
          assert_equal 1, rt.fk
          assert_equal 2, a1.fk
        end

        context 'when base class' do
          it 'saves the instance attributes' do
            assert_equal 'A', rt.rt
          end
        end

        context 'when a subclass' do
          it 'saves the attributes for each table' do
            assert_equal 'D', b1.rt
            assert_equal 'E', b1.a1
            assert_equal 'F', b1.b1
          end
        end

      end

      describe 'DELETE' do

        let(:b1) { B1.create(rt: 'D', a1: 'E', b1: 'F').delete }

        it 'removes the record from all associated tables' do
          assert_equal [], db[:rts].where(:id => b1.pk).all
          assert_equal [], db[:a1s].where(:id => b1.pk).all
          assert_equal [], db[:b1s].where(:id => b1.pk).all
        end

      end

      describe 'UPDATE' do

        let(:b1) { B1.create(rt: 'D', a1: 'E', b1: 'F') }

        before(:each) do
          b1.update(rt: 'G', a1: 'H', b1: 'I').reload
        end

        it 'updates the attributes in the associated tables' do
          assert_equal 'G', b1.rt
          assert_equal 'H', b1.a1
          assert_equal 'I', b1.b1
        end

      end

    end
  end
end

