# frozen_string_literal: true

module Spree
  module Admin
    class GiftCardTemplatesController < ResourceController
      # L and 0 are not in the code alphabet, so the sample never matches a real card.
      SAMPLE_CODE = 'SAMPLE00'

      # The card drawn with sample details on the template, with the unsaved layout from the editor.
      def preview
        layout = params.dig(:gift_card_template, :layout)
        @object.layout = layout if layout
        @object.restore_attributes if @object.invalid?
        sample = Spree::VirtualGiftCard.new(
          amount: 1500,
          currency: current_store&.default_currency.presence || Spree::Config.currency, redemption_code: SAMPLE_CODE,
          recipient_name: t('spree.admin.gift_card_templates.sample.recipient_name'),
          purchaser_name: t('spree.admin.gift_card_templates.sample.purchaser_name'),
          gift_message: t('spree.admin.gift_card_templates.sample.gift_message')
        )
        response.headers['Cache-Control'] = 'no-store'
        send_data SolidusVirtualGiftCard::Config.card_image_class.new(sample, template: @object).to_png, type: 'image/png', disposition: 'inline'
      end

      private

      def collection
        super.order(:name)
      end

      def permitted_resource_params
        params.require(:gift_card_template).permit(:name, :background, :layout)
      end

      def location_after_save
        edit_admin_gift_card_template_path(@object)
      end
    end
  end
end
