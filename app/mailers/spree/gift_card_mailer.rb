# frozen_string_literal: true

class Spree::GiftCardMailer < Spree::BaseMailer
  def gift_card_email(gift_card)
    @gift_card = gift_card.respond_to?(:id) ? gift_card : Spree::VirtualGiftCard.find(gift_card)
    @order = @gift_card.line_item.order

    store = @order.store
    subject = "#{store} #{I18n.t('spree.gift_card_mailer.gift_card_email.subject')}"

    if SolidusVirtualGiftCard::Config.card_image
      card = SolidusVirtualGiftCard::Config.card_image_class.new(@gift_card)
      attachments.inline[card.filename] = { mime_type: 'image/png', content: card.to_png }
      @card_image = attachments[card.filename]
    end

    mail(to: @gift_card.delivery_email, from: from_address(store), subject: subject)
  end
end
