require 'spec_helper'
require 'sequel/plugins/x_pg_json_attr'

module Sequel
  module Plugins
    describe XPgJsonAttr do

      db = Sequel.connect('mock://postgres')

      class PgJsonAttrA < Sequel::Model(db)
        plugin :x_pg_json_attr, :nosql
        json_accessor :forename, String
      end

      class PgJsonAttrB < PgJsonAttrA
        json_accessor :location, String
      end

      subject { PgJsonAttrA.new }

      describe '::json_accessors' do

        it 'creates a getter method' do
          assert_equal true, subject.respond_to?('forename')
        end

        it 'creates a setter method' do
          assert_equal true, subject.respond_to?('forename=')
        end

        it 'does not create subclass accessors in the super' do
          assert_equal false, subject.respond_to?('location')
        end

        it 'allows accessors without a specific type' do
          expect{ PgJsonAttrA.json_accessor :lastname }.
            to_not raise_error
        end

        it 'allows getters without a specific type' do
          expect{ PgJsonAttrA.json_getter :address }.
            to_not raise_error
        end

        it 'allows setter without a specific converter' do
          expect{ PgJsonAttrA.json_setter :address }.
            to_not raise_error
        end

      end

      describe '#before_save' do

        it 'saves even if the attribute hash is nil' do
          subject.values[:nosql] = nil
          expect{ subject.before_save }.to_not raise_error
        end

        it 'converts the attribute hash to a json hash' do
          subject.values[:nosql] = { forename: 'Garrett' }
          subject.before_save

          assert_equal Sequel::Postgres::JSONHash,
            subject.values[:nosql].class
        end

      end

      context Object do

        describe 'getters' do
          it 'returns nil when no value exists' do
            assert_equal nil, subject.forename
          end
        end

        describe 'setters' do
          it 'sets the key to the given value' do
            subject.forename = 'Garrett'
            assert_equal 'Garrett', subject.forename
          end
        end

      end

      context Proc do

        before(:all) do
          PgJsonAttrA.json_accessor :hostname, -> u { u.host }, -> v { URI(v) }
        end

        describe 'setter' do
          it 'stores values using the output of the setter lambda' do
            subject.hostname = URI('http://www.iterationfour.com/about')
            assert_equal 'www.iterationfour.com', subject.values[:nosql][:hostname]
          end
        end

        describe 'getter' do
          it 'returns the value using the output of the getter lambda' do
            subject.values[:nosql] = { hostname: 'www.iterationfour.com' }
            assert_equal URI('www.iterationfour.com'), subject.hostname
          end
        end

      end

      context Time do

        before(:all) do
          PgJsonAttrA.json_accessor :issued_at, Time
        end

        describe 'setter' do
          it 'stores times as ints in unix format' do
            subject.issued_at = Time.new(1970, 1, 1, 1, 0, 1)
            assert_equal 1, subject.values[:nosql][:issued_at]
          end
        end

        describe 'getter' do
          it 'returns the value as a time object' do
            subject.values[:nosql] = { issued_at: 1 }
            assert_equal Time.new(1970, 1, 1, 1, 0, 1), subject.issued_at
          end
        end

      end

      context BigDecimal do

        before(:all) do
          PgJsonAttrA.json_accessor :balance, BigDecimal
        end

        describe 'setters' do
          it 'stores big decimals as strings in E notation' do
            subject.balance = BigDecimal.new('99.99')
            assert_equal '0.9999E2', subject.values[:nosql][:balance]
          end
        end

        describe 'getters' do
          it 'returns the value as a big decimal object' do
            subject.values[:nosql] = { balance: '0.9999E2' }
            assert_equal BigDecimal.new('99.99'), subject.balance
          end
        end

      end

      context Date do

        before(:all) do
          PgJsonAttrA.json_accessor :born_on, Date
        end

        describe 'setters' do
          it 'stores dates as ints in julian format' do
            subject.born_on = Date.new(2013, 1, 1)
            assert_equal 2456294, subject.values[:nosql][:born_on]
          end
        end

        describe 'getters' do
          it 'returns the value as a date object' do
            subject.values[:nosql] = { born_on: 2456294 }
            assert_equal Date.new(2013, 1, 1), subject.born_on
          end
        end

      end

    end
  end
end

