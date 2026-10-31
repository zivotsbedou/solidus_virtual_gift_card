# frozen_string_literal: true

# A card template: artwork carrying the fixed texts, and where the card's fields are drawn on it.
# Gift card variants pick a template; customers choose the variant.
class Spree::GiftCardTemplate < Spree::Base
  COLOR = /\A#\h{6}\z/
  # What staff may change per field: its box and font size as fractions of the card, its font and
  # colour, and the QR code's background colour.
  PLACEMENT = %w[x y width height size].freeze
  STYLE = %w[font color background].freeze

  has_one_attached :background
  has_many :variants, class_name: 'Spree::Variant', inverse_of: :gift_card_template, dependent: :restrict_with_error
  has_many :virtual_gift_cards, class_name: 'Spree::VirtualGiftCard', dependent: :restrict_with_error

  validates :name, presence: true
  validate :background_is_image, if: -> { background.attached? }
  validate :layout_is_placement

  # The configured card layout with this template's field boxes, fonts and colours.
  # An invalid layout (shown back with its error) leaves the configured one.
  def card_layout(base = SolidusVirtualGiftCard::Config.card_image_layout)
    overrides = layout.is_a?(Hash) ? layout : {}
    base.to_h do |field, style|
      override = overrides[field.to_s]
      [field, override.is_a?(Hash) ? style.merge(override.slice(*PLACEMENT, *STYLE).symbolize_keys) : style]
    end
  end

  # The layout editor submits JSON; a blank value goes back to the configured layout.
  def layout=(value)
    value = value.presence && JSON.parse(value) if value.is_a?(String)
    super(value.is_a?(Hash) ? value.deep_stringify_keys : value)
  rescue JSON::ParserError
    @invalid_layout = true
  end

  private

  def background_is_image
    errors.add(:background, :invalid) unless background.content_type.in?(%w[image/png image/jpeg])
  end

  def layout_is_placement
    valid = !@invalid_layout && (layout.nil? || (layout.is_a?(Hash) && layout.values.all? { |field| field_valid?(field) }))
    errors.add(:layout, :invalid) unless valid
  end

  def field_valid?(field)
    field.is_a?(Hash) && field.all? do |key, value|
      case key
      when *PLACEMENT then value.is_a?(Numeric) && value.between?(0, 1)
      when 'font' then value.in?(SolidusVirtualGiftCard::Config.card_image_fonts)
      when 'color', 'background' then value.is_a?(String) && value.match?(COLOR)
      else false
      end
    end
  end
end
