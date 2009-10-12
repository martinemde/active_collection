require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

class Beer
  def self.human_name(*args)
    "Beer"
  end

  def self.table_name
    "beers"
  end
end

class BeerCollection < ActiveCollection::Base
end

class DunkelBeer
  def self.human_name(*args)
    "Dunkel Beer"
  end

  def self.table_name
    "dunkel_beers"
  end
end

class DarkBeerCollection < ActiveCollection::Base
  model "DunkelBeer"
end

class BrokenCollection < ActiveCollection::Base
end

describe ActiveCollection do
  context "(with standard name)" do
    subject { BeerCollection.new }

    it "has the correct model_class" do
      subject.model_class.should == Beer
    end

    it "retrieves table_name from member class" do
      subject.table_name.should == "beers"
    end

    it "retrieves human_name from member class and pluralizes" do
      subject.human_name(:locale => 'en-us').should == "Beers"
    end
  end

  context "(with model)" do
    subject { DarkBeerCollection.new }

    it "uses the correct model class" do
      subject.model_class.should == DunkelBeer
    end

    it "doesn't affect other classes" do
      BeerCollection.new.model_class.should == Beer
    end

    it "retrieves table_name from member class" do
      subject.table_name.should == "dunkel_beers"
    end

    it "retrieves human_name from member class and pluralizes" do
      subject.human_name(:locale => 'en-us').should == "Dunkel Beers"
    end
  end

  context "(broken name)" do
    subject { BrokenCollection.new }

    it "raises a useful error when usage is attempted" do
      message = "No exception raised."
      begin
        subject.model_class
      rescue NameError => e
        message = e.to_s
      end
      message.should =~ /Use 'model "Class"' in the collection to declare the correct model class for BrokenCollection/
      message.should =~ /uninitialized constant Broken/
    end
  end
end
