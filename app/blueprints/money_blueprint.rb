class MoneyBlueprint < Blueprinter::Base
  field :cents
  field :currency do |money|
    money.currency.iso_code
  end
end
