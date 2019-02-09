require 'time'

module Agents
  class TimeFilterAgent < Agent
    cannot_be_scheduled!

    description <<-MD
      The Time Filter Agent filters events based on whether a 24h or AM/PM time in them is within a provided range.

      `time_path` should be set to where in the event's payload the time information is, default is `time`

      `earliest` should be set to earliest allowed time, default is `08:00`

      `latest` should be set to the latest allowed time, default is `20:00`
    MD

    def default_options
      {
        "earliest": "08:00",
        "latest": "20:00",
        "time_path": "time"
      }
    end

    def validate_options
      errors.add(:base, "time_path needs to be present") if options['time_path'].blank?
      errors.add(:base, "earliest and/or latest needs to be present") if options['earliest'].blank? or options['latest'].blank?
    end

    def working?
      checked_without_error?
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        event_time = get_time(event.payload[options['time_path']])
        return if event_time.nil?

        earliest_time = get_time(options['earliest'])        
        latest_time = get_time(options['latest'])
        return unless earliest_time.nil? or event_time >= earliest_time
        return unless latest_time.nil? or event_time <= latest_time

        create_event payload: event.payload
      end
    end

    private

    def get_time(string)
      return if string.blank?
      begin
        Time.parse(string)
      rescue
        nil
      end
    end
  end
end
