# frozen_string_literal: true

require 'spree/preferences/configuration'
require 'active_support/all'

module SolidusVirtualGiftCard
  class Configuration < Spree::Preferences::Configuration
    preference :send_gift_card_emails, :boolean, default: true
    preference :credit_to_new_gift_card, :boolean, default: false

    preference :authorize_timeout, :time, default: 1.month
    # Codes are printed on cards; shorter is easier to type. Rate-limit redemption when lowering it.
    preference :redemption_code_length, :integer, default: 24
    class_name_attribute :schedule_job_class, default: 'SolidusVirtualGiftCard::VoidExpiredAuthorizedEventsJob'

    # Amounts customers may choose for open-amount gift card products; either end may be nil.
    attr_writer :open_amount_range

    def open_amount_range
      @open_amount_range ||= 1..
    end

    # Render each card as an image, attach it to the gift card email and offer it for download.
    # The default renderer needs libvips and the ruby-vips gem.
    preference :card_image, :boolean, default: false
    class_name_attribute :card_image_class, default: 'SolidusVirtualGiftCard::CardImage'

    # Card size when the gift card product has no image to draw on.
    attr_writer :card_image_size, :card_image_background, :card_image_layout, :card_image_fonts

    # URL the card's QR code opens, given the gift card; nil leaves out the QR code.
    attr_accessor :card_qr_url

    def card_image_size
      @card_image_size ||= [1748, 1240]
    end

    def card_image_background
      @card_image_background ||= [255, 255, 255]
    end

    # Fonts staff can pick for a field in a card design.
    def card_image_fonts
      @card_image_fonts ||= ['sans', 'sans bold', 'monospace bold']
    end

    # Each field is a box, as fractions of the card: x and width of its width; y, height and the
    # font size (or QR code size) of its height. Text wraps at the width and is cut at the height.
    # Each field's text comes from the solidus_virtual_gift_card.card_image.<field> translation.
    def card_image_layout
      @card_image_layout ||= {
        amount: { x: 0.08, y: 0.12, width: 0.84, size: 0.12, color: [33, 33, 33], font: 'sans bold' },
        code: { x: 0.08, y: 0.36, width: 0.84, size: 0.055, color: [33, 33, 33], font: 'monospace bold' },
        recipient_name: { x: 0.08, y: 0.52, width: 0.84, size: 0.05, color: [33, 33, 33], font: 'sans' },
        gift_message: { x: 0.08, y: 0.62, width: 0.84, size: 0.04, color: [33, 33, 33], font: 'sans' },
        purchaser_name: { x: 0.08, y: 0.86, width: 0.84, size: 0.04, color: [33, 33, 33], font: 'sans' }
      }
    end
  end
end
