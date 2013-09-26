require 'spec_helper'
require 'sequel/plugins/x_json_attributes'

module Sequel
  module Plugins
    describe XJsonAttributes do

      class JsonAttributesA < Sequel::Model
        plugin :x_json_attributes, :nosql
        json_accessor :forename, String
      end

      class JsonAttributesB < JsonAttributesA
        json_accessor :location, String
      end

      subject { JsonAttributesA.new }

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

      context Time do

        before(:all) do
          JsonAttributesA.json_accessor :issued_at, Time
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
          JsonAttributesA.json_accessor :balance, BigDecimal
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
          JsonAttributesA.json_accessor :born_on, Date
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

