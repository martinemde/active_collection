require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

class BeerCollection < ActiveCollection::Base
end

class Beer
  def self.human_name(*args)
    "Beer"
  end
end

describe ActiveCollection do
  subject { BeerCollection.new }

  it "passes human_name to the member class and then pluralizes" do
    subject.human_name(:locale => 'en-us').should == "Beers"
  end

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
      end

      it "doesn't load count after loading the collection" do
        subject.length
        Beer.should_not_receive(:count)
        subject.size.should == 0
      end

      it "yields no items on each" do
        count = 0
        subject.each { |i| count += 1 }
        count.should == 0
      end
    end
  end

  context "(simple collection with 5 records)" do
    def records
      @records ||= begin
                     beers = []
                     5.times { beers << Beer.new }
                     beers
                   end
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
      end

      it "doesn't load count after loading the collection" do
        subject.length
        Beer.should_not_receive(:count)
        subject.size.should == 5
      end

      it "yields 5 items to each" do
        count = 0
        subject.each { |i| count += 1 }
        count.should == 5
      end
    end
  end
end
