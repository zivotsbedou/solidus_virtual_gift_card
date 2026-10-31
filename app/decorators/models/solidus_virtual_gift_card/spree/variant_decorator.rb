# frozen_string_literal: true

module SolidusVirtualGiftCard
  module Spree
    module VariantDecorator
      def self.prepended(base)
        base.belongs_to :gift_card_template, class_name: 'Spree::GiftCardTemplate', optional: true, inverse_of: :variants
      end

      ::Spree::Variant.prepend self
    end
  end
end
