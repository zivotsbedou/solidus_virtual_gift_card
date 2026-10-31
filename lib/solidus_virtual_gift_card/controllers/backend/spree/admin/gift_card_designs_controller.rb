# frozen_string_literal: true

module Spree
  module Admin
    class GiftCardDesignsController < ResourceController
      # The design drawn with sample details, so staff see the finished card before customers do.
      def preview
        sample = Spree::VirtualGiftCard.new(
          design: @object, amount: 1500, currency: current_store&.default_currency.presence || Spree::Config.currency,
          redemption_code: 'K7M2PQ9X', recipient_name: t('spree.admin.gift_card_designs.sample.recipient_name'),
          purchaser_name: t('spree.admin.gift_card_designs.sample.purchaser_name'),
          gift_message: t('spree.admin.gift_card_designs.sample.gift_message')
        )
        response.headers['Cache-Control'] = 'no-store'
        send_data SolidusVirtualGiftCard::Config.card_image_class.new(sample).to_png, type: 'image/png', disposition: 'inline'
      end

      private

      def collection
        super.ordered
      end

      def permitted_resource_params
        params.require(:gift_card_design).permit(:name, :heading, :footer, :footer_align, :amount_color, :ink_color,
                                                 :box_color, :active, :position, :background)
      end

      def location_after_save
        edit_admin_gift_card_design_path(@object)
      end
    end
  end
end
