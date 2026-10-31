# frozen_string_literal: true

module SolidusVirtualGiftCard
  # Draws a gift card's details onto its variant's image (the card design), or a plain card, as a PNG.
  #
  # Each card_image_layout field is a text field, or :qr for the redemption QR code, drawn in its
  # color on its background. A colour is [r, g, b] or "#rrggbb".
  class CardImage
    def initialize(gift_card, config: SolidusVirtualGiftCard::Config)
      @gift_card = gift_card
      @variant = gift_card.line_item&.variant
      @config = config
    end

    def to_png
      require 'vips'

      layout = @variant ? @variant.card_layout(@config.card_image_layout) : @config.card_image_layout
      canvas = layout.reduce(background) do |image, (field, style)|
        field.to_sym == :qr ? draw_qr(image, style) : draw_field(image, field, style)
      end
      canvas.write_to_buffer('.png')
    end

    def filename
      "#{I18n.t('solidus_virtual_gift_card.card_image.filename')}-#{@gift_card.formatted_redemption_code}.png"
    end

    private

    def background
      image = @variant && ::Spree::Config.variant_gallery_class.new(@variant).images.first
      return opaque(Vips::Image.new_from_buffer(image.attachment.download, '')) if image

      width, height = @config.card_image_size
      Vips::Image.black(width, height).new_from_image(@config.card_image_background).copy(interpretation: :srgb)
    end

    def draw_field(image, field, style)
      markup = markup_for(field.to_sym)
      markup.blank? ? image : draw(image, markup, style)
    end

    # Pango markup, with customer-entered text escaped.
    def markup_for(field)
      value = case field
              when :amount then @gift_card.formatted_amount
              when :code then @gift_card.formatted_redemption_code
              else @gift_card.public_send(field)
              end
      ERB::Util.html_escape(I18n.t("solidus_virtual_gift_card.card_image.#{field}", value: value)) if value.present?
    end

    def draw(image, markup, style)
      # A field is a box: text wraps at its width, centres within it, and is cut at its height.
      align = style.fetch(:align, :low)
      width = (style.fetch(:width) * image.width).round
      mask = Vips::Image.text(
        markup,
        font: "#{style.fetch(:font, 'sans')} #{(style.fetch(:size) * image.height).round}",
        fontfile: style[:fontfile],
        width: width,
        align: align,
        dpi: 72,
        wrap: :word
      )
      height = style[:height] && (style[:height] * image.height).round
      mask = mask.crop(0, 0, mask.width, height) if height && mask.height > height
      x = (style.fetch(:x) * image.width).round
      x += (width - mask.width) / 2 if align == :centre
      ink = mask.new_from_image(color(style.fetch(:color, [33, 33, 33]))).copy(interpretation: :srgb).bandjoin(mask)
      opaque(image.bandjoin(255).composite2(ink, :over, x: x, y: (style.fetch(:y) * image.height).round))
    end

    def color(value)
      value.is_a?(String) ? value.delete('#').scan(/../).map(&:hex) : value
    end

    # A code with a quiet zone in its background colour, so phones read it on any artwork.
    def draw_qr(image, style)
      url = @config.card_qr_url&.call(@gift_card)
      return image if url.blank? || @gift_card.redemption_code.blank?

      require 'rqrcode'
      modules = RQRCode::QRCode.new(url, level: :m).modules
      quiet = 2
      cells = modules.size + (2 * quiet)
      rows = Array.new(cells) do |row|
        Array.new(cells) do |column|
          inside = (row - quiet).between?(0, modules.size - 1) && (column - quiet).between?(0, modules.size - 1)
          inside && modules[row - quiet][column - quiet] ? 0 : 255
        end
      end
      size = (style.fetch(:size) * image.height).round
      code = Vips::Image.new_from_array(rows).cast(:uchar).resize(size.to_f / cells, kernel: :nearest)
      code = (code > 127).ifthenelse(color(style.fetch(:background, [255, 255, 255])), color(style.fetch(:color, [45, 49, 66])))
      code = code.cast(:uchar).copy(interpretation: :srgb)
      opaque(image.bandjoin(255).composite2(code.bandjoin(255), :over, x: (style.fetch(:x) * image.width).round,
                                                                        y: (style.fetch(:y) * image.height).round))
    end

    # Three 8-bit sRGB bands, so every field composites the same way.
    def opaque(image)
      image = image.colourspace(:srgb)
      image = image.flatten(background: @config.card_image_background) if image.has_alpha?
      image.cast(:uchar)
    end
  end
end
