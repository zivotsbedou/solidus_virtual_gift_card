# frozen_string_literal: true

module SolidusVirtualGiftCard
  # Draws a gift card's details onto its product image (or a plain card) as a PNG.
  class CardImage
    def initialize(gift_card, config: SolidusVirtualGiftCard::Config)
      @gift_card = gift_card
      @config = config
    end

    def to_png
      require 'vips'

      canvas = @config.card_image_layout.reduce(background) do |image, (field, style)|
        text = text_for(field)
        text.blank? ? image : draw(image, text, style)
      end
      canvas.write_to_buffer('.png')
    end

    def filename
      "#{I18n.t('solidus_virtual_gift_card.card_image.filename')}-#{@gift_card.formatted_redemption_code}.png"
    end

    private

    def background
      image = ::Spree::Config.variant_gallery_class.new(@gift_card.line_item.variant).images.first
      return opaque(Vips::Image.new_from_buffer(image.attachment.download, '')) if image

      width, height = @config.card_image_size
      Vips::Image.black(width, height).new_from_image(@config.card_image_background).copy(interpretation: :srgb)
    end

    def text_for(field)
      value = case field.to_sym
              when :amount then @gift_card.formatted_amount
              when :code then @gift_card.formatted_redemption_code
              else @gift_card.public_send(field)
              end
      I18n.t("solidus_virtual_gift_card.card_image.#{field}", value: value) if value.present?
    end

    def draw(image, text, style)
      mask = Vips::Image.text(
        ERB::Util.html_escape(text),
        font: "#{style.fetch(:font, 'sans')} #{(style.fetch(:size) * image.height).round}",
        fontfile: style[:fontfile],
        width: (style.fetch(:width) * image.width).round,
        align: style.fetch(:align, :low),
        dpi: 72,
        wrap: :word
      )
      ink = mask.new_from_image(style.fetch(:color)).copy(interpretation: :srgb).bandjoin(mask)
      opaque(image.bandjoin(255).composite2(ink, :over, x: (style.fetch(:x) * image.width).round, y: (style.fetch(:y) * image.height).round))
    end

    # Three 8-bit sRGB bands, so every field composites the same way.
    def opaque(image)
      image = image.colourspace(:srgb)
      image = image.flatten(background: @config.card_image_background) if image.has_alpha?
      image.cast(:uchar)
    end
  end
end
