require 'rails_helper'

RSpec.describe Address, type: :model do
  subject { build(:address) }

  describe "Associations" do
    it { should have_one(:order) }
  end

  describe "Validations" do
    it { should validate_presence_of(:line_1) }
    it { should validate_presence_of(:city) }
    it { should validate_presence_of(:state) }
    it { should validate_presence_of(:zip) }
    it { should validate_presence_of(:country) }
  end
end
