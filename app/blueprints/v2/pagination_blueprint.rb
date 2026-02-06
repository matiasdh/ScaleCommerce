module V2
  class PaginationBlueprint < Blueprinter::Base
    field :limit, name: :per_page
    field :next
    field :previous

    field :records do |_, options|
      options[:records]
    end
  end
end
