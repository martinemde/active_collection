require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

class Beer
end

class OrderedBeerCollection < ActiveCollection::Base
  model "Beer"
  order_by "name"
end

class InheritedOrderedBeerCollection < OrderedBeerCollection
end

class OverloadedInheritedOrderedBeerCollection < OrderedBeerCollection
  order_by "created_at DESC"
end

class NotOrderedBeerCollection < ActiveCollection::Base
  model "Beer"
end

describe ActiveCollection, "(order_by)" do
  context "(without class order_by)" do
    subject { NotOrderedBeerCollection.new }

    it "does not have any order on load" do
      Beer.should_receive(:all).with({}).and_return([])
      subject.to_a
    end

    it "adds order on instance" do
      subject.order_by! "id DESC"
      Beer.should_receive(:all).with(:order => "id DESC").and_return([])
      subject.to_a
    end

    it "creates a new object with the order_by on #order_by" do
      col = subject.order_by "id DESC"
      Beer.should_receive(:all).with(:order => "id DESC").and_return([])
      col.to_a
    end

    it "doesn't affect the existing object on #order_by" do
      col = subject.order_by "id DESC"
      Beer.should_receive(:all).with({}).and_return([])
      subject.to_a
    end
  end

  context "(with class order_by)" do
    subject { OrderedBeerCollection.new }

    it "sends order when collection loads" do
      Beer.should_receive(:all).with(:order => "name").and_return([])
      subject.to_a
    end

    it "does not send order with count" do
      Beer.should_receive(:count).with({}).and_return(0)
      subject.empty?
    end

    it "overloads order when added to instance" do
      subject.order_by! "id DESC"
      Beer.should_receive(:all).with(:order => "id DESC").and_return([])
      subject.to_a
    end
  end

  context "(inherited from a class with order_by)" do
    subject { InheritedOrderedBeerCollection.new }

    it "sends superclass order on collection loads" do
      Beer.should_receive(:all).with(:order => "name").and_return([])
      subject.to_a
    end

    it "overloads order when added to instance" do
      subject.order_by! "id DESC"
      Beer.should_receive(:all).with(:order => "id DESC").and_return([])
      subject.to_a
    end
  end

  context "(inherited adding order_by)" do
    subject { OverloadedInheritedOrderedBeerCollection.new }

    it "overloads superclasses' order" do
      Beer.should_receive(:all).with(:order => "created_at DESC").and_return([])
      subject.to_a
    end

    it "overloads order when added to instance" do
      subject.order_by! "id DESC"
      Beer.should_receive(:all).with(:order => "id DESC").and_return([])
      subject.to_a
    end
  end
end
