# spec/requests/api/v2/base_controller_spec.rb
require "rails_helper"

RSpec.describe "Api::V2::BaseController", type: :request do
  describe "error handling" do
    context "when an unexpected error occurs" do
      before do
        allow(Product).to receive(:find).and_raise(StandardError, "Something went wrong")
        get "/api/v2/products/1"
      end

      it "returns 500 Internal Server Error" do
        expect(response).to have_http_status(:internal_server_error)
      end

      it "returns generic error message (hides internal details)" do
        json_response = JSON.parse(response.body)

        expect(json_response).to match({
          "error" => {
            "code" => 500,
            "messages" => [ "Internal server error" ]
          }
        })
      end
    end
  end
end
