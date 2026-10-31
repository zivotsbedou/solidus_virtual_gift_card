# frozen_string_literal: true

module Spree
  # Lets the buyer download a paid card to print. The order's guest token proves access.
  class GiftCardImagesController < Spree::BaseController
    def show
      gift_card = Spree::VirtualGiftCard.find_by(id: params[:id])
      return head :not_found unless gift_card && downloadable?(gift_card)

      card = SolidusVirtualGiftCard::Config.card_image_class.new(gift_card)
      response.headers['Cache-Control'] = 'no-store'
      send_data card.to_png, type: 'image/png', disposition: 'attachment', filename: card.filename
    end

    private

    def downloadable?(gift_card)
      SolidusVirtualGiftCard::Config.card_image &&
        gift_card.redeemable? && !gift_card.deactivated? &&
        ActiveSupport::SecurityUtils.secure_compare(gift_card.order.guest_token.to_s, params[:token].to_s)
    end
  end
end
