require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

class Beer
  def self.human_name(*args)
    "Beer"
  end
end

class BeerCollection < ActiveCollection::Base
end

describe ActiveCollection do
  subject { BeerCollection.new }

  context "(empty)" do
    describe "(count methods)" do
      before do
        Beer.stub!(:count).and_return(0)
      end

      it "is empty" do
        subject.should be_empty
      end

      it "has size of 0" do
        subject.size.should == 0
      end

      it "has total_entries of 0" do
        subject.total_entries.should == 0
      end
    end

    describe "(collection loading methods)" do
      before do
        Beer.stub!(:all).and_return([])
      end

      it "has length of 0" do
        subject.length.should == 0
      end

      it "doesn't load count after loading the collection" do
        subject.length
        Beer.should_not_receive(:count)
        subject.should be_empty
        subject.size.should == 0
      end

      it "yields no items on each" do
        count = 0
        subject.each { |i| count += 1 }
        count.should == 0
      end

      it "returns empty Array on to_a" do
        subject.to_a.should == []
      end
    end
  end

  context "(with 5 records)" do
    def records
      @records ||= (1..5).map { |i| Beer.new }
    end

    describe "(count methods)" do
      before { Beer.stub!(:count).and_return(records.size) }

      it "is not empty" do
        subject.should_not be_empty
      end

      it "has a size of 5" do
        subject.size.should == 5
      end

      it "has total_entries of 5" do
        subject.total_entries.should == 5
      end
    end

    describe "(collection loading methods)" do
      before do
        Beer.stub!(:all).and_return(records)
      end

      it "has length of 5" do
        subject.length.should == 5
      end

      it "doesn't load count after loading the collection" do
        subject.length
        Beer.should_not_receive(:count)
        subject.should_not be_empty
        subject.size.should == 5
      end

      it "yields 5 items to each" do
        count = 0
        subject.each { |i| count += 1 }
        count.should == 5
      end

      it "returns all objects in an Array on to_a" do
        subject.to_a.should == records
      end

      it "loads the collection on length" do
        subject.should_not be_loaded
        subject.length
        subject.should be_loaded
      end

      it "unloads a loaded collection on unload!" do
        subject.to_a
        subject.should be_loaded
        subject.unload!
        subject.should_not be_loaded
      end
    end
  end
end
