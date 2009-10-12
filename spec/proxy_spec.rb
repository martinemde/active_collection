require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

class Beer
  def self.human_name(*args)
    "Beer"
  end

  def self.all(*args)
    [Beer.new, Beer.new]
  end
end

class BeerCollection < ActiveCollection::Base
end

describe ActiveCollection, "(proxying)" do
  subject { BeerCollection.new }

  it "responds to array methods" do
    subject.should respond_to(:map)
    subject.should respond_to(:slice)
  end

  it "loads the collection when sending array methods" do
    Beer.should_receive(:all).and_return([Beer.new])
    subject.send(:slice, 0).should_not be_nil
  end

  it "responds to its own instance methods" do
    subject.should respond_to(:loaded?)
    subject.should respond_to(:empty?)
  end

  it "doesn't load the collection when sending collection methods" do
    Beer.should_not_receive(:all)
    subject.send(:loaded?).should be_false
  end
end
