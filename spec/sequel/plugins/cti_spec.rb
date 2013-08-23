require 'spec_helper'
require 'sequel/plugins/cti'

module Sequel
  module Plugins
    describe Cti do

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
        String :a1, null: false
      end

      db[:a1s].insert({ id: 2, a1: 'A1' })
      db[:a1s].insert({ id: 4, a1: 'A1' })

      db.create_table(:a2s) do
        foreign_key :id, :rts, primary_key: true
        String :a2, null: false
      end

      db[:a2s].insert({ id: 3, a2: 'A2' })

      db.create_table(:b1s) do
        foreign_key :id, :a1s, primary_key: true
        String :b1, null: false
      end

      db[:b1s].insert({ id: 4, b1: 'B1' })

      class ::RT < Sequel::Model(db)
        plugin :cti, key: :fk,
          map: { 1 => self, 2 => 'A1', 3 => 'A2', 4 => 'B1' }
      end

      class ::A1 < RT; end
      class ::A2 < RT; end
      class ::B1 < A1; end

      describe 'SELECT' do

        context 'via base class' do

          let(:instances) { RT.all }

          it 'loads all instance types' do
            instances.map(&:class).should === [RT, A1, A2, B1]
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
            A1.all.map(&:class).should == [A1, B1]
          end
        end

        context 'via leaf class' do
          it 'only loads instances of that type' do
            B1.all.map(&:class).should == [B1]
          end
        end

      end

      describe 'INSERT' do

        it 'creates instances with the correct type value' do
          RT.create(rt: 'NEW').fk.should == 1
          A1.create(rt: 'NEW').fk.should == 2
        end

      end

    end
  end
end

