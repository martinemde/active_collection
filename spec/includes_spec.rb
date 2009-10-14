require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

class Beer
end

class IncludedBeerCollection < ActiveCollection::Base
  model "Beer"
  includes :brewery
end

class InheritedNotIncludedBeerCollection < IncludedBeerCollection
end

class InheritedIncludedBeerCollection < IncludedBeerCollection
  includes :imbibes => :user
end

class NotIncludedBeerCollection < ActiveCollection::Base
  model "Beer"
end

class MultipleIncludesBeerCollection < ActiveCollection::Base
  model "Beer"
  includes :brewery
  includes :imbibes
end

describe ActiveCollection, "(includes)" do
  context "(without class includes)" do
    subject { NotIncludedBeerCollection.new }

    it "does not have any includes" do
      Beer.should_receive(:all).with({}).and_return([])
      subject.to_a
    end

    it "adds includes added to an instance" do
      subject.include! :tags
      Beer.should_receive(:all).with(:include => [:tags]).and_return([])
      subject.to_a
    end

    it "creates a new object with the includes on #include" do
      col = subject.include :tags
      Beer.should_receive(:all).with(:include => [:tags]).and_return([])
      col.to_a
    end

    it "doesn't affect the existing object on #include" do
      col = subject.include :tags
      Beer.should_receive(:all).with({}).and_return([])
      subject.to_a
    end

    it "doesn't choke on nil include" do
      col = subject.include nil
      Beer.should_receive(:all).with({}).and_return([])
      subject.to_a
    end
  end

  context "(with class includes)" do
    subject { IncludedBeerCollection.new }

    it "includes any class level includes with collection loads" do
      Beer.should_receive(:all).with(:include => [:brewery]).and_return([])
      subject.to_a
    end

    it "does not send includes with count" do
      Beer.should_receive(:count).with({}).and_return(0)
      subject.empty?
    end

    it "merges includes added to an instance with default includes" do
      subject.include! :tags
      Beer.should_receive(:all).with(:include => [:brewery, :tags]).and_return([])
      subject.to_a
    end

    it "doesn't mind includes being given as an array" do
      subject.include! [:tags]
      Beer.should_receive(:all).with(:include => [:brewery, :tags]).and_return([])
      subject.to_a
    end
  end

  context "(inherited from a class with includes)" do
    subject { InheritedNotIncludedBeerCollection.new }

    it "includes superclass includes with collection loads" do
      Beer.should_receive(:all).with(:include => [:brewery]).and_return([])
      subject.to_a
    end

    it "does not send includes with count" do
      Beer.should_receive(:count).with({}).and_return(0)
      subject.empty?
    end

    it "merges includes added to an instance with default includes" do
      subject.include! :tags
      Beer.should_receive(:all).with(:include => [:brewery, :tags]).and_return([])
      subject.to_a
    end

    it "creates a new object with the includes on #include" do
      col = subject.include :tags
      Beer.should_receive(:all).with(:include => [:brewery, :tags]).and_return([])
      col.to_a
    end
  end

  context "(inherited adding includes)" do
    subject { InheritedIncludedBeerCollection.new }

    it "merges superclass includes on collection load" do
      Beer.should_receive(:all).with(:include => [:brewery, {:imbibes => :user}]).and_return([])
      subject.to_a
    end

    it "merges includes added to an instance with default includes" do
      subject.include! :tags
      Beer.should_receive(:all).with(:include => [:brewery, {:imbibes => :user}, :tags]).and_return([])
      subject.to_a
    end
  end

  context "(multiple includes)" do
    subject { MultipleIncludesBeerCollection.new }

    it "merges includes on collection load" do
      Beer.should_receive(:all).with(:include => [:brewery, :imbibes]).and_return([])
      subject.to_a
    end

    it "merges includes added to an instance with default includes" do
      subject.include! :tags
      Beer.should_receive(:all).with(:include => [:brewery, :imbibes, :tags]).and_return([])
      subject.to_a
    end
  end
end
