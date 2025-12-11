# spec/blueprints/pagination_blueprint_spec.rb
require "rails_helper"

RSpec.describe PaginationBlueprint do
  describe ".render_as_hash" do
    subject(:result) { described_class.render_as_hash(pagination, records: records) }

    let(:pagination) do
      instance_double(
        "Pagination",
        page: 2,
        count: 50,
        pages: 5,
        limit: 10
      )
    end

    let(:records) do
      [
        { id: 1, name: "Record 1" },
        { id: 2, name: "Record 2" }
      ]
    end

    it "serializes pagination fields with the correct names" do
      expect(result).to include(
        page: 2,
        record_count: 50,
        pages: 5,
        per_page: 10
      )
    end

    it "serializes records from options" do
      expect(result[:records]).to eq(records)
    end
  end
end
