# frozen_string_literal: true

require 'solidus_core'
require 'solidus_support'

module SolidusVirtualGiftCard
  class Engine < Rails::Engine
    include SolidusSupport::EngineExtensions

    isolate_namespace ::Spree

    engine_name 'solidus_virtual_gift_card'

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    if SolidusSupport.backend_available?
      paths["app/controllers"] << "lib/solidus_virtual_gift_card/controllers/backend"
    end

    initializer 'solidus_virtual_gift_card.environment', before: :load_config_initializers do
      SolidusVirtualGiftCard::Config = SolidusVirtualGiftCard::Configuration.new
    end

    initializer "virtual_gift_card.add_static_preference", after: "spree.register.payment_methods" do |app|
      app.config.spree.payment_methods << 'Spree::PaymentMethod::GiftCard'
      app.config.to_prepare do
        ::Spree::Config.static_model_preferences.add(
          ::Spree::PaymentMethod::GiftCard,
          'gift_card_payment_method',
          {}
        )
      end
    end

    initializer "solidus_virtual_gift_card.pub_sub", after: "spree.core.pub_sub" do |app|
      app.reloader.to_prepare do
        SolidusVirtualGiftCard::DeliverySubscriber.new.subscribe_to(::Spree::Bus)
      end
    end

    initializer "solidus_virtual_gift_card.ignore_overrides", before: :eager_load! do |app|
      app.autoloaders.main.ignore(root.join("app/overrides"))
    end
  end
end
