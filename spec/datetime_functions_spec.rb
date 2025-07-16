# frozen_string_literal: true
require 'spec_helper'
require 'active_support/core_ext/numeric/time'

module JMESPath
  describe 'datetime functions' do
    describe 'current_datetime' do
      it 'returns the current time in ISO8601 format' do
        result = JMESPath.search('current_datetime()', {})
        expect(result).to match(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{2}:\d{2}\z/)

        # Should be close to current time (within 1 second)
        parsed_time = Time.parse(result)
        expect(parsed_time).to be_within(1).of(Time.now)
      end

      it 'raises error when arguments are provided' do
        expect {
          JMESPath.search('current_datetime(`1`)', {})
        }.to raise_error(JMESPath::Errors::InvalidArityError)
      end
    end

    # Test data for datetime filtering
    let(:test_data) do
      {
        events: [
          { name: 'Recent', timestamp: (Time.now - 3600).iso8601 },        # 1 hour ago
          { name: 'Yesterday', timestamp: (Time.now - 86400).iso8601 },    # 1 day ago
          { name: 'Last week', timestamp: (Time.now - 604800).iso8601 },   # 1 week ago
          { name: 'Future', timestamp: (Time.now + 3600).iso8601 },        # 1 hour from now
        ]
      }
    end

    describe 'ago functions' do
      describe 'seconds_ago' do
        it 'returns time N seconds ago in ISO8601 format' do
          result = JMESPath.search('seconds_ago(`30`)', {})
          expect(result).to match(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{2}:\d{2}\z/)

          parsed_time = Time.parse(result)
          expect(parsed_time).to be_within(1).of(Time.now - 30)
        end

        it 'raises error for non-numeric argument' do
          expect {
            JMESPath.search('seconds_ago("30")', {})
          }.to raise_error(JMESPath::Errors::InvalidTypeError)
        end

        it 'raises error for wrong number of arguments' do
          expect {
            JMESPath.search('seconds_ago(`30`, `60`)', {})
          }.to raise_error(JMESPath::Errors::InvalidArityError)
        end
      end

      describe 'minutes_ago' do
        it 'returns time N minutes ago in ISO8601 format' do
          result = JMESPath.search('minutes_ago(`5`)', {})
          parsed_time = Time.parse(result)
          expect(parsed_time).to be_within(1).of(Time.now - 300)
        end

        it 'can filter events from the last N minutes' do
          result = JMESPath.search('events[?timestamp > minutes_ago(`90`)]', test_data)
          expect(result.map { |e| e[:name] }).to eq(['Recent', 'Future'])
        end
      end

      describe 'hours_ago' do
        it 'returns time N hours ago in ISO8601 format' do
          result = JMESPath.search('hours_ago(`2`)', {})
          parsed_time = Time.parse(result)
          expect(parsed_time).to be_within(1).of(Time.now - 7200)
        end

        it 'can filter events from the last N hours' do
          result = JMESPath.search('events[?timestamp > hours_ago(`2`)]', test_data)
          expect(result.map { |e| e[:name] }).to include('Recent', 'Future')
        end
      end

      describe 'days_ago' do
        it 'returns time N days ago in ISO8601 format' do
          result = JMESPath.search('days_ago(`1`)', {})
          parsed_time = Time.parse(result)
          expect(parsed_time).to be_within(1).of(Time.now - 86400)
        end

        it 'can filter events from the last N days' do
          result = JMESPath.search('events[?timestamp > days_ago(`2`)]', test_data)
          expect(result.map { |e| e[:name] }).to include('Recent', 'Yesterday', 'Future')
        end
      end

      describe 'weeks_ago' do
        it 'returns time N weeks ago in ISO8601 format' do
          result = JMESPath.search('weeks_ago(`1`)', {})
          parsed_time = Time.parse(result)
          expect(parsed_time).to be_within(1).of(Time.now - 604800)
        end

        it 'can filter events from the last N weeks' do
          result = JMESPath.search('events[?timestamp > weeks_ago(`2`)]', test_data)
          expect(result.map { |e| e[:name] }).to include('Recent', 'Yesterday', 'Last week', 'Future')
        end
      end

      describe 'months_ago' do
        it 'returns time N months ago in ISO8601 format' do
          result = JMESPath.search('months_ago(`1`)', {})
          parsed_time = Time.parse(result)
          expected_time = 1.month.ago
          expect(parsed_time).to be_within(1).of(expected_time)
        end

        it 'handles month boundaries correctly' do
          # ActiveSupport handles edge cases like Jan 31 - 1 month gracefully
          result = JMESPath.search('months_ago(`3`)', {})
          expect(result).to match(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{2}:\d{2}\z/)
        end
      end

      describe 'years_ago' do
        it 'returns time N years ago in ISO8601 format' do
          result = JMESPath.search('years_ago(`1`)', {})
          parsed_time = Time.parse(result)
          expected_time = 1.year.ago
          expect(parsed_time).to be_within(1).of(expected_time)
        end

        it 'handles leap years correctly' do
          result = JMESPath.search('years_ago(`4`)', {})
          expect(result).to match(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{2}:\d{2}\z/)
        end
      end
    end

    describe 'from_now functions' do
      describe 'seconds_from_now' do
        it 'returns time N seconds from now in ISO8601 format' do
          result = JMESPath.search('seconds_from_now(`30`)', {})
          parsed_time = Time.parse(result)
          expect(parsed_time).to be_within(1).of(Time.now + 30)
        end
      end

      describe 'minutes_from_now' do
        it 'returns time N minutes from now in ISO8601 format' do
          result = JMESPath.search('minutes_from_now(`15`)', {})
          parsed_time = Time.parse(result)
          expect(parsed_time).to be_within(1).of(Time.now + 900)
        end

        it 'can find future events' do
          result = JMESPath.search('events[?timestamp < minutes_from_now(`90`)]', test_data)
          expect(result.map { |e| e[:name] }).to include('Recent', 'Yesterday', 'Last week')
        end
      end

      describe 'hours_from_now' do
        it 'returns time N hours from now in ISO8601 format' do
          result = JMESPath.search('hours_from_now(`2`)', {})
          parsed_time = Time.parse(result)
          expect(parsed_time).to be_within(1).of(Time.now + 7200)
        end

        it 'can find near-future events' do
          result = JMESPath.search('events[?timestamp > current_datetime() && timestamp < hours_from_now(`2`)]', test_data)
          expect(result.map { |e| e[:name] }).to eq(['Future'])
        end
      end

      describe 'days_from_now' do
        it 'returns time N days from now in ISO8601 format' do
          result = JMESPath.search('days_from_now(`1`)', {})
          parsed_time = Time.parse(result)
          expect(parsed_time).to be_within(1).of(Time.now + 86400)
        end
      end

      describe 'weeks_from_now' do
        it 'returns time N weeks from now in ISO8601 format' do
          result = JMESPath.search('weeks_from_now(`2`)', {})
          parsed_time = Time.parse(result)
          expect(parsed_time).to be_within(1).of(Time.now + 1209600)
        end
      end

      describe 'months_from_now' do
        it 'returns time N months from now in ISO8601 format' do
          result = JMESPath.search('months_from_now(`1`)', {})
          parsed_time = Time.parse(result)
          expected_time = 1.month.from_now
          expect(parsed_time).to be_within(1).of(expected_time)
        end
      end

      describe 'years_from_now' do
        it 'returns time N years from now in ISO8601 format' do
          result = JMESPath.search('years_from_now(`1`)', {})
          parsed_time = Time.parse(result)
          expected_time = 1.year.from_now
          expect(parsed_time).to be_within(1).of(expected_time)
        end
      end
    end

    describe 'complex datetime queries' do
      it 'combines multiple datetime functions in filters' do
        # Events between 2 days ago and 1 hour from now
        result = JMESPath.search(
          'events[?timestamp > days_ago(`2`) && timestamp < hours_from_now(`1`)]',
          test_data
        )
        expect(result.map { |e| e[:name] }).to include('Recent', 'Yesterday')
      end

      it 'works with sorting by timestamp' do
        result = JMESPath.search('events | sort_by(@, &timestamp)', test_data)
        names = result.map { |e| e[:name] }
        expect(names).to eq(['Last week', 'Yesterday', 'Recent', 'Future'])
      end
    end

    describe 'error handling with disable_visit_errors option' do
      it 'returns nil instead of raising errors when disabled' do
        runtime = JMESPath::Runtime.new(disable_visit_errors: true)

        # Invalid type error
        result = runtime.search('days_ago("not a number")', {})
        expect(result).to be_nil

        # Invalid arity error
        result = runtime.search('current_datetime(`1`)', {})
        expect(result).to be_nil
      end
    end
  end
end
