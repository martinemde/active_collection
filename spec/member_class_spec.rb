require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

class Model
  def self.human_name(*args)
    "Model"
  end

  def self.table_name
    "models"
  end
end

class ModelCollection < ActiveCollection::Base
end

class SpecialModel
  def self.human_name(*args)
    "Special Model"
  end

  def self.table_name
    "special_models"
  end
end

class SpecialCollection < ActiveCollection::Base
  model "SpecialModel"
end

class InheritedSpecialCollection < SpecialCollection
end

class OverloadedInheritedSpecialCollection < SpecialCollection
  model "Model"
end

class BrokenCollection < ActiveCollection::Base
end

describe ActiveCollection do
  context "(with standard name)" do
    subject { ModelCollection.new }

    it "has the correct model_class" do
      subject.model_class.should == Model
    end

    it "retrieves table_name from member class" do
      subject.table_name.should == "models"
    end

    it "retrieves human_name from member class and pluralizes" do
      subject.human_name(:locale => 'en-us').should == "Models"
    end
  end

  context "(with model)" do
    subject { SpecialCollection.new }

    it "uses the correct model class" do
      subject.model_class.should == SpecialModel
    end

    it "doesn't affect other classes" do
      ModelCollection.new.model_class.should == Model
    end

    it "retrieves table_name from member class" do
      subject.table_name.should == "special_models"
    end

    it "retrieves human_name from member class and pluralizes" do
      subject.human_name(:locale => 'en-us').should == "Special Models"
    end
  end

  context "(inherited and not overloaded)" do
    subject { InheritedSpecialCollection.new }

    it "maintains the same model class" do
      subject.model_class.should == SpecialModel
    end
  end

  context "(inherited and overloaded)" do
    subject { OverloadedInheritedSpecialCollection.new }

    it "maintains the same model class" do
      subject.model_class.should == Model
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
