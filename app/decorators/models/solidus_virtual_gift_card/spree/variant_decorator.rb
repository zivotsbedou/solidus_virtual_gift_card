# frozen_string_literal: true

module SolidusVirtualGiftCard
  module Spree
    # A gift card variant is a card design: its image is the artwork and gift_card_layout places
    # the card's fields on it.
    module VariantDecorator
      COLOR = /\A#\h{6}\z/
      # What staff may change per field: its box and font size as fractions of the card, its font
      # and colour, and the QR code's background colour.
      PLACEMENT = %w[x y width height size].freeze
      STYLE = %w[font color background].freeze

      def self.prepended(base)
        base.validate :gift_card_layout_is_placement
      end

      # The configured card layout with this variant's field boxes, fonts and colours.
      def card_layout(base = SolidusVirtualGiftCard::Config.card_image_layout)
        base.to_h do |field, style|
          [field, style.merge((gift_card_layout || {}).fetch(field.to_s, {}).slice(*PLACEMENT, *STYLE).symbolize_keys)]
        end
      end

      # The layout editor submits JSON; a blank value goes back to the configured layout.
      def gift_card_layout=(value)
        value = value.presence && JSON.parse(value) if value.is_a?(String)
        super(value.is_a?(Hash) ? value.deep_stringify_keys : value)
      rescue JSON::ParserError
        @invalid_gift_card_layout = true
      end

      private

      def gift_card_layout_is_placement
        layout = gift_card_layout
        valid = !@invalid_gift_card_layout && (layout.nil? || (layout.is_a?(Hash) && layout.values.all? { |field| card_field_valid?(field) }))
        errors.add(:gift_card_layout, :invalid) unless valid
      end

      def card_field_valid?(field)
        field.is_a?(Hash) && field.all? do |key, value|
          case key
          when *PLACEMENT then value.is_a?(Numeric) && value.between?(0, 1)
          when 'font' then value.in?(SolidusVirtualGiftCard::Config.card_image_fonts)
          when 'color', 'background' then value.is_a?(String) && value.match?(COLOR)
          else false
          end
        end
      end

      ::Spree::Variant.prepend self
    end
  end
end
