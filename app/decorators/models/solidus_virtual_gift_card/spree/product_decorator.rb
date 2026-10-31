# frozen_string_literal: true

module SolidusVirtualGiftCard
  module Spree
    module ProductDecorator
      # A gift card without option variants is bought as its master variant, so the product form
      # picks the master's card template.
      def self.prepended(base)
        base.delegate :gift_card_template_id, :gift_card_template_id=, to: :find_or_build_master
      end

      ::Spree::Product.prepend self
    end
  end
end
