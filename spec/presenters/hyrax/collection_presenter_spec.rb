RSpec.describe Hyrax::CollectionPresenter do
  describe ".terms" do
    subject { described_class.terms }

    it do
      is_expected.to eq [:total_items, :size, :resource_type, :creator,
                         :contributor, :keyword, :license, :publisher,
                         :date_created, :subject, :language, :identifier,
                         :based_near, :related_url]
    end
  end

  let(:collection) do
    build(:collection,
          id: 'adc12v',
          description: ['a nice collection'],
          based_near: ['Over there'],
          title: ['A clever title'],
          keyword: ['neologism'],
          resource_type: ['Collection'],
          related_url: ['http://example.com/'],
          date_created: ['some date'])
  end
  let(:ability) { double }
  let(:presenter) { described_class.new(solr_doc, ability) }
  let(:solr_doc) { SolrDocument.new(collection.to_solr) }

  # Mock bytes so collection does not have to be saved.
  before { allow(collection).to receive(:bytes).and_return(0) }

  describe "collection type methods" do
    subject { presenter }

    it { is_expected.to delegate_method(:collection_type_is_nestable?).to(:collection_type).as(:nestable?) }
    it { is_expected.to delegate_method(:collection_type_is_discoverable?).to(:collection_type).as(:discoverable?) }
    it { is_expected.to delegate_method(:collection_type_is_sharable?).to(:collection_type).as(:sharable?) }
    it { is_expected.to delegate_method(:collection_type_is_share_applies_to_new_works?).to(:collection_type).as(:share_applies_to_new_works?) }
    it { is_expected.to delegate_method(:collection_type_is_allow_multiple_membership?).to(:collection_type).as(:allow_multiple_membership?) }
    it { is_expected.to delegate_method(:collection_type_is_require_membership?).to(:collection_type).as(:require_membership?) }
    it { is_expected.to delegate_method(:collection_type_is_assigns_workflow?).to(:collection_type).as(:assigns_workflow?) }
    it { is_expected.to delegate_method(:collection_type_is_assigns_visibility?).to(:collection_type).as(:assigns_visibility?) }
  end

  describe '#collection_type' do
    let(:collection_type) { create(:collection_type) }

    describe 'when solr_document#collection_type_gid exists' do
      let(:collection) { build(:collection, collection_type_gid: collection_type.gid) }
      let(:solr_doc) { SolrDocument.new(collection.to_solr) }

      it 'finds the collection type based on the solr_document#collection_type_gid if one exists' do
        expect(presenter.collection_type).to eq(collection_type)
      end
    end
  end

  describe "#resource_type" do
    subject { presenter.resource_type }

    it { is_expected.to eq ['Collection'] }
  end

  describe "#terms_with_values" do
    subject { presenter.terms_with_values }

    it do
      is_expected.to eq [:total_items,
                         :size,
                         :resource_type,
                         :keyword,
                         :date_created,
                         :based_near,
                         :related_url]
    end
  end

  describe '#to_s' do
    subject { presenter.to_s }

    it { is_expected.to eq 'A clever title' }
  end

  describe "#title" do
    subject { presenter.title }

    it { is_expected.to eq ['A clever title'] }
  end

  describe '#keyword' do
    subject { presenter.keyword }

    it { is_expected.to eq ['neologism'] }
  end

  describe "#based_near" do
    subject { presenter.based_near }

    it { is_expected.to eq ['Over there'] }
  end

  describe "#related_url" do
    subject { presenter.related_url }

    it { is_expected.to eq ['http://example.com/'] }
  end

  describe '#to_key' do
    subject { presenter.to_key }

    it { is_expected.to eq ['adc12v'] }
  end

  describe "#size", :clean_repo do
    subject { presenter.size }

    it { is_expected.to eq '0 Bytes' }
  end

  describe "#total_items", :clean_repo do
    subject { presenter.total_items }

    context "empty collection" do
      it { is_expected.to eq 0 }
    end

    context "collection with work" do
      let!(:work) { create(:work, member_of_collections: [collection]) }

      it { is_expected.to eq 1 }
    end

    context "null members" do
      let(:presenter) { described_class.new(SolrDocument.new(id: '123'), nil) }

      it { is_expected.to eq 0 }
    end
  end

  describe "#total_viewable_items", :clean_repo do
    subject { presenter.total_viewable_items }

    let(:user) { create(:user) }

    before do
      allow(ability).to receive(:user_groups).and_return(['public'])
      allow(ability).to receive(:current_user).and_return(user)
    end

    context "empty collection" do
      it { is_expected.to eq 0 }
    end

    context "collection with private work" do
      let!(:work) { create(:private_work, member_of_collections: [collection]) }

      it { is_expected.to eq 0 }
    end

    context "collection with private collection" do
      let!(:work) { create(:private_collection, member_of_collections: [collection]) }

      it { is_expected.to eq 0 }
    end

    context "collection with public work" do
      let!(:work) { create(:public_work, member_of_collections: [collection]) }

      it { is_expected.to eq 1 }
    end

    context "collection with public collection" do
      let!(:subcollection) { create(:public_collection, member_of_collections: [collection]) }

      it { is_expected.to eq 1 }
    end

    context "collection with public work and sub-collection" do
      let!(:work) { create(:public_work, member_of_collections: [collection]) }
      let!(:subcollection) { create(:public_collection, member_of_collections: [collection]) }

      it { is_expected.to eq 2 }
    end

    context "null members" do
      let(:presenter) { described_class.new(SolrDocument.new(id: '123'), ability) }

      it { is_expected.to eq 0 }
    end
  end

  describe "#total_viewable_works", :clean_repo do
    subject { presenter.total_viewable_works }

    let(:user) { create(:user) }

    before do
      allow(ability).to receive(:user_groups).and_return(['public'])
      allow(ability).to receive(:current_user).and_return(user)
    end

    context "empty collection" do
      it { is_expected.to eq 0 }
    end

    context "collection with private work" do
      let!(:work) { create(:private_work, member_of_collections: [collection]) }

      it { is_expected.to eq 0 }
    end

    context "collection with public work" do
      let!(:work) { create(:public_work, member_of_collections: [collection]) }

      it { is_expected.to eq 1 }
    end

    context "collection with public work and sub-collection" do
      let!(:work) { create(:public_work, member_of_collections: [collection]) }
      let!(:subcollection) { create(:public_collection, member_of_collections: [collection]) }

      it { is_expected.to eq 1 }
    end

    context "null members" do
      let(:presenter) { described_class.new(SolrDocument.new(id: '123'), ability) }

      it { is_expected.to eq 0 }
    end
  end

  describe "#total_viewable_collections", :clean_repo do
    subject { presenter.total_viewable_collections }

    let(:user) { create(:user) }

    before do
      allow(ability).to receive(:user_groups).and_return(['public'])
      allow(ability).to receive(:current_user).and_return(user)
    end

    context "empty collection" do
      it { is_expected.to eq 0 }
    end

    context "collection with private collection" do
      let!(:subcollection) { create(:private_collection, member_of_collections: [collection]) }

      it { is_expected.to eq 0 }
    end

    context "collection with public collection" do
      let!(:subcollection) { create(:public_collection, member_of_collections: [collection]) }

      it { is_expected.to eq 1 }
    end

    context "collection with public work and sub-collection" do
      let!(:work) { create(:public_work, member_of_collections: [collection]) }
      let!(:subcollection) { create(:public_collection, member_of_collections: [collection]) }

      it { is_expected.to eq 1 }
    end

    context "null members" do
      let(:presenter) { described_class.new(SolrDocument.new(id: '123'), ability) }

      it { is_expected.to eq 0 }
    end
  end

  describe "#size", :clean_repo do
    subject { presenter.size }

    it { is_expected.to eq '0 Bytes' }
  end

  describe "#parent_collection_count" do
    subject { presenter.parent_collection_count }

    let(:parent_collections) { double(Object, documents: parent_docs, response: { "numFound" => parent_docs.size }, total_pages: 1) }

    context('when parent_collections is nil') do
      before do
        allow(presenter).to receive(:parent_collections).and_return(nil)
      end

      it { is_expected.to eq 0 }
    end

    context('when parent_collections is has no collections') do
      let(:parent_docs) { [] }

      it { is_expected.to eq 0 }
    end

    context('when parent_collections is has collections') do
      let(:collection1) { build(:collection, title: ['col1']) }
      let(:collection2) { build(:collection, title: ['col2']) }
      let!(:parent_docs) { [collection1, collection2] }

      before do
        presenter.parent_collections = parent_collections
      end

      it { is_expected.to eq 2 }
    end
  end

  describe "#more_parent_collections?" do
    subject { presenter.more_parent_collections? }

    context('when parent_collections is has no collections') do
      before do
        allow(presenter).to receive(:parent_collection_count).and_return(0)
      end

      it { is_expected.to eq false }
    end

    context('when parent_collections has less than or equal to show limit') do
      before do
        allow(presenter).to receive(:parent_collection_count).and_return(3)
      end

      it { is_expected.to eq false }
    end

    context('when parent_collections has more than show limit') do
      before do
        allow(presenter).to receive(:parent_collection_count).and_return(4)
      end

      it { is_expected.to eq true }
    end
  end

  describe "#visible_parent_collections" do
    subject { presenter.visible_parent_collections }

    let(:collection1) { build(:collection, title: ['col1']) }
    let(:collection2) { build(:collection, title: ['col2']) }
    let(:collection3) { build(:collection, title: ['col3']) }
    let(:collection4) { build(:collection, title: ['col4']) }
    let(:collection5) { build(:collection, title: ['col5']) }
    let(:parent_collections) { double(Object, documents: parent_docs, response: { "numFound" => parent_docs.size }, total_pages: 1) }

    before do
      presenter.parent_collections = parent_collections
    end

    context('when parent_collections is nil') do
      let(:parent_collections) { nil }

      it { is_expected.to eq [] }
    end

    context('when parent_collections has less than or equal to show limit') do
      let(:parent_docs) { [collection1, collection2, collection3] }

      it { is_expected.to include(collection1, collection2, collection3) }
    end

    context('when parent_collections has more than show limit') do
      let(:parent_docs) { [collection1, collection2, collection3, collection4, collection5] }

      it { is_expected.to include(collection1, collection2, collection3) }
    end
  end

  describe "#more_parent_collections" do
    subject { presenter.more_parent_collections }

    let(:collection1) { build(:collection, title: ['col1']) }
    let(:collection2) { build(:collection, title: ['col2']) }
    let(:collection3) { build(:collection, title: ['col3']) }
    let(:collection4) { build(:collection, title: ['col4']) }
    let(:collection5) { build(:collection, title: ['col5']) }
    let(:parent_collections) { double(Object, documents: parent_docs, response: { "numFound" => parent_docs.size }, total_pages: 1) }

    before do
      presenter.parent_collections = parent_collections
    end

    context('when parent_collections is nil') do
      let(:parent_collections) { nil }

      it { is_expected.to eq [] }
    end

    context('when parent_collections is empty') do
      let(:parent_docs) { [] }

      it { is_expected.to eq [] }
    end

    context('when parent_collections has less than or equal to show limit') do
      let(:parent_docs) { [collection1, collection2, collection3] }

      it { is_expected.to eq [] }
    end

    context('when parent_collections has more than show limit') do
      let(:parent_docs) { [collection1, collection2, collection3, collection4, collection5] }

      it { is_expected.to include(collection4, collection5) }
    end
  end

  describe "#user_can_nest_collection?" do
    before do
      allow(ability).to receive(:can?).with(:deposit, solr_doc).and_return(true)
    end

    subject { presenter.user_can_nest_collection? }

    it { is_expected.to eq true }
  end

  describe "#user_can_create_new_nest_collection?" do
    before do
      allow(ability).to receive(:can?).with(:create_collection_of_type, collection.collection_type).and_return(true)
    end

    subject { presenter.user_can_create_new_nest_collection? }

    it { is_expected.to eq true }
  end

  describe '#show_path' do
    subject { presenter.show_path }

    it { is_expected.to eq "/dashboard/collections/#{solr_doc.id}" }
  end

  describe "banner_file" do
    let(:banner_info) do
      CollectionBrandingInfo.new(
        collection_id: "123",
        filename: "banner.gif",
        role: "banner",
        target_url: ""
      )
    end

    let(:logo_info) do
      CollectionBrandingInfo.new(
        collection_id: "123",
        filename: "logo.gif",
        role: "logo",
        alt_txt: "This is the logo",
        target_url: "http://logo.com"
      )
    end

    before do
      allow(presenter).to receive(:id).and_return('123')
      allow(CollectionBrandingInfo).to receive(:where).with(collection_id: '123', role: 'banner').and_return([banner_info])
      allow(banner_info).to receive(:local_path).and_return("/temp/public/branding/123/banner/banner.gif")
      allow(CollectionBrandingInfo).to receive(:where).with(collection_id: '123', role: 'logo').and_return([logo_info])
      allow(logo_info).to receive(:local_path).and_return("/temp/public/branding/123/logo/logo.gif")
    end

    it "banner check" do
      expect(presenter.banner_file).to eq("/branding/123/banner/banner.gif")
    end

    it "logo check" do
      expect(presenter.logo_record).to eq([{ file: "logo.gif", file_location: "/branding/123/logo/logo.gif", alttext: "This is the logo", linkurl: "http://logo.com" }])
    end
  end

  subject { presenter }

  it { is_expected.to delegate_method(:resource_type).to(:solr_document) }
  it { is_expected.to delegate_method(:based_near).to(:solr_document) }
  it { is_expected.to delegate_method(:related_url).to(:solr_document) }
  it { is_expected.to delegate_method(:identifier).to(:solr_document) }
  it { is_expected.to delegate_method(:date_created).to(:solr_document) }
end
