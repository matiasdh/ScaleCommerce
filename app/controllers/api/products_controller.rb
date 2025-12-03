module Api
  class ProductsController < BaseController
    def index
      products = Product.all
      render status: :ok, json: products
    end

    def show
      product = Product.find(params[:id])
      render status: :ok, json: product
    end
  end
end
