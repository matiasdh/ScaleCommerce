require "rails_helper"

RSpec.describe V2::PaginationBlueprint do
  describe ".render_as_hash" do
    subject(:result) { described_class.render_as_hash(pagination, records: records) }

    let(:pagination) do
      instance_double(
        "Pagination",
        limit: 20,
        next: 3,
        previous: 1
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
        per_page: 20,
        next: 3,
        previous: 1
      )

      # Keyset specific: ensure offset fields are absent
      expect(result).not_to have_key(:page)
      expect(result).not_to have_key(:pages)
      expect(result).not_to have_key(:record_count)
    end

    it "serializes records from options" do
      expect(result[:records]).to eq(records)
    end

    context "when on last page" do
      let(:pagination) do
        instance_double("Pagination", limit: 20, next: nil, previous: 2)
      end

      it "returns nil for next" do
        expect(result[:next]).to be_nil
        expect(result[:previous]).to eq(2)
      end
    end
  end
end
