require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::FisheyeAgent do
  before(:each) do
    @valid_options = Agents::FisheyeAgent.new.default_options
    @checker = Agents::FisheyeAgent.new(:name => "FisheyeAgent", :options => @valid_options)
    @checker.user = users(:bob)
    @checker.save!
  end

  pending "add specs here"
end
