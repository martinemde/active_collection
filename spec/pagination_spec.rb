require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

class BeerCollection < ActiveCollection::Base
end

class Beer
end

describe "an empty collection", :shared => true do
  it "is empty" do
    subject.should be_empty
  end

  it "has 0 total entries" do
    subject.total_entries.should == 0
  end

  it "has 0 total_pages" do
    subject.total_pages.should == 0
  end

  it "has length of 0" do
    subject.length.should == 0
  end

  it "yields no items on each" do
    count = 0
    subject.each { |i| count += 1 }
    count.should == 0
  end
end

describe ActiveCollection do
  subject { BeerCollection.new(:page => 1) }

  context "(empty)" do
    before do
      Beer.stub!(:count).and_return(0)
      Beer.stub!(:all).and_return([])
    end

    describe "(page 1)" do
      it_should_behave_like "an empty collection"

      it "is on page 1" do
        subject.current_page.should == 1
      end
    end

    describe "(page 2)" do
      subject { BeerCollection.new(:page => 2) }

      it_should_behave_like "an empty collection"

      it "should be out of bounds" do
        subject.should be_out_of_bounds
      end

      it "is on page 2" do
        subject.current_page.should == 2
      end

      it "is empty" do
        subject.should be_empty
      end

      it "has 0 size" do
        subject.size.should == 0
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
    before { Beer.stub!(:count).and_return(records.size) }

    describe "(default per_page)" do
      before do
        Beer.stub!(:all).with(
          :limit => ActiveCollection::Base.per_page,
          :offset => 0
        ).and_return(records)
      end

      describe "(page 1)" do
        it "is not empty" do
          subject.should_not be_empty
        end

        it "has a size of 5" do
          subject.size.should == 5
        end

        it "has total_entries of 5" do
          subject.total_entries.should == 5
        end

        it "has length of 5" do
          subject.length.should == 5
        end

        it "doesn't load count after loading the collection" do
          subject.length
          Beer.should_not_receive(:count)
          subject.empty?
          subject.size
          subject.total_entries
        end

        it "yields 5 items to each" do
          count = 0
          subject.each { |i| count += 1 }
          count.should == 5
        end

        it "has 1 total pages" do
          subject.total_pages.should == 1
        end

        it "is on page 1" do
          subject.current_page.should == 1
        end

        it "is the last page" do
          subject.should be_last_page
        end

        it "has no next page" do
          subject.next_page.should be_nil
        end

        it "has no previous page" do
          subject.previous_page.should be_nil
        end

        it "returs nil next page collection" do
          subject.next_page_collection.should be_nil
        end

        it "returs nil previous page collection" do
          subject.previous_page_collection.should be_nil
        end

        it "has default per_page" do
          subject.per_page.should == ActiveCollection::Base.per_page
        end

        it "is not out of bounds" do
          subject.should_not be_out_of_bounds
        end

        it "has a 0 offset" do
          subject.offset.should == 0
        end

        it "loads records using default limit and 0 offset" do
          Beer.should_receive(:all).with(:limit => ActiveCollection::Base.per_page, :offset => 0).and_return(records)
          subject.length
        end
      end
    end

    context "(2 per page)" do
      describe "(page 1)" do
        before { Beer.stub!(:all).with(:limit => 2, :offset => 0).and_return(records[0..1]) }
        subject { BeerCollection.new(:page => 1, :per_page => 2) }

        it "is not empty" do
          subject.should_not be_empty
        end

        it "has a size of 2" do
          subject.size.should == 2
        end

        it "has a length of 2" do
          subject.length.should == 2
        end

        it "has 5 total entries" do
          subject.total_entries.should == 5
        end

        it "has 3 total pages" do
          subject.total_pages.should == 3
        end

        it "is on page 1" do
          subject.current_page.should == 1
        end

        it "is not the last page" do
          subject.should_not be_last_page
        end

        it "has next page of 2" do
          subject.next_page.should == 2
        end

        it "has no previous page" do
          subject.previous_page.should be_nil
        end

        it "returs a next page collection for page 2" do
          nex = subject.next_page_collection
          nex.should_not be_nil
          nex.current_page.should == 2
        end

        it "returs nil previous page collection" do
          subject.previous_page_collection.should be_nil
        end

        it "has per_page of 2" do
          subject.per_page.should == 2
        end

        it "is not out of bounds" do
          subject.should_not be_out_of_bounds
        end

        it "has a 0 offset" do
          subject.offset.should == 0
        end

        it "calls count to find total_entries even when collection is loaded" do
          subject.length
          Beer.should_receive(:count).and_return(5)
          subject.total_entries.should == 5
        end

        it "loads records using default limit and 0 offset" do
          Beer.should_receive(:all).with(:limit => 2, :offset => 0).and_return(records)
          subject.length
        end
      end

      describe "(page 3)" do
        before { Beer.stub!(:all).with(:limit => 2, :offset => 4).and_return(records[4..4]) }
        subject { BeerCollection.new(:page => 3, :per_page => 2) }

        it "is not empty" do
          subject.should_not be_empty
        end

        it "has a size of 1" do
          subject.size.should == 1
        end

        it "has a length of 1" do
          subject.length.should == 1
        end

        it "has 5 total entries" do
          subject.total_entries.should == 5
        end

        it "has 3 total pages" do
          subject.total_pages.should == 3
        end

        it "is on page 3" do
          subject.current_page.should == 3
        end

        it "is the last page" do
          subject.should be_last_page
        end

        it "has no next page" do
          subject.next_page.should be_nil
        end

        it "has previous page of 2" do
          subject.previous_page.should == 2
        end

        it "returs nil next page collection" do
          subject.next_page_collection.should be_nil
        end

        it "returs nil previous page collection" do
          prev = subject.previous_page_collection
          prev.should_not be_nil
          prev.current_page.should == 2
        end

        it "has per_page of 2" do
          subject.per_page.should == 2
        end

        it "is not out of bounds" do
          subject.should_not be_out_of_bounds
        end

        it "has a 0 offset" do
          subject.offset.should == 4
        end

        it "does not call count to find total_entries when collection is loaded" do
          subject.length
          Beer.should_not_receive(:count).and_return(5)
          subject.total_entries.should == 5
        end

        it "loads records using default limit and 0 offset" do
          Beer.should_receive(:all).with(:limit => 2, :offset => 4).and_return(records)
          subject.length
        end
      end
    end
  end
end
