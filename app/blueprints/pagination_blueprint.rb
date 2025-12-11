class PaginationBlueprint < Blueprinter::Base
  field :page
  field :count, name: :record_count
  field :pages
  field :limit, name: :per_page

  field :records do |_, options|
    options[:records]
  end
end
