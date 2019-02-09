require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::TimeFilterAgent do
  before(:each) do
    @valid_options = Agents::TimeFilterAgent.new.default_options
    @checker = Agents::TimeFilterAgent.new(:name => "TimeFilterAgent", :options => @valid_options)
    @checker.user = users(:bob)
    @checker.save!
  end

  it 'renders the event description without errors' do
    expect { @checker.event_description }.not_to raise_error
  end

  context '#validate_options' do
    it 'is valid with the default options' do
      expect(@checker).to be_valid
    end

    it 'requires either time to be set' do
      @checker.options['earliest'] = ""
      @checker.options['latest'] = ""
      expect(@checker).not_to be_valid
    end

    it 'requires time_path to be set' do
      @checker.options['time_path'] = ""
      expect(@checker).not_to be_valid
    end
  end  

  context '#receive' do
    it "accepts an AM/PM time in timeframe" do
      event = Event.new(payload: {"time" => "5:30PM"})

      expect { @checker.receive([event]) }.to change(Event, :count).by(1)
    end

    it "accepts an AM/PM time in timeframe for alternative path" do
      event = Event.new(payload: {"my_time" => "5:30PM"})
      @checker.options['time_path'] = "my_time"

      expect { @checker.receive([event]) }.to change(Event, :count).by(1)
    end


    it "rejects an AM/PM time after timeframe" do
      event = Event.new(payload: {"time" => "11:30PM"})

      expect { @checker.receive([event]) }.to change(Event, :count).by(0)
    end

    it "rejects an AM/PM time before timeframe" do
      event = Event.new(payload: {"time" => "7:30AM"})

      expect { @checker.receive([event]) }.to change(Event, :count).by(0)
    end

    it "accepts a 24h time in timeframe" do
      event = Event.new(payload: {"time" => "20:00"})

      expect { @checker.receive([event]) }.to change(Event, :count).by(1)
    end

    it "accepts a 24h time with seconds in timeframe" do
      event = Event.new(payload: {"time" => "8:00:00"})

      expect { @checker.receive([event]) }.to change(Event, :count).by(1)
    end

    it "rejects a 24h time after timeframe" do
      event = Event.new(payload: {"time" => "23:30"})

      expect { @checker.receive([event]) }.to change(Event, :count).by(0)
    end

    it "rejects a 24h time before timeframe" do
      event = Event.new(payload: {"time" => "3:30"})

      expect { @checker.receive([event]) }.to change(Event, :count).by(0)
    end

    it "rejects an event without a time" do
      event = Event.new(payload: {"no_time" => "for you"})

      expect { @checker.receive([event]) }.to change(Event, :count).by(0)
    end

    it "rejects an event without a bad time" do
      event = Event.new(payload: {"time" => "not a time"})

      expect { @checker.receive([event]) }.to change(Event, :count).by(0)
    end
  end

end
