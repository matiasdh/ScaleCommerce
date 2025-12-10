# config/initializers/money.rb
MoneyRails.configure do |config|
  # set the default currency
  config.default_currency = :usd
  config.locale_backend = :i18n
end
