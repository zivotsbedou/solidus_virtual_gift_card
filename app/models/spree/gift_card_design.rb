# frozen_string_literal: true

# A card look customers choose at purchase: background artwork plus the texts and colours drawn on it.
class Spree::GiftCardDesign < Spree::Base
  COLOR = /\A#\h{6}\z/
  # What staff may change per field: its box and font size as fractions of the card, its font and
  # colour, and the QR code's background colour.
  PLACEMENT = %w[x y width height size].freeze
  STYLE = %w[font color background].freeze

  has_one_attached :background
  has_many :virtual_gift_cards, class_name: 'Spree::VirtualGiftCard', foreign_key: :design_id, inverse_of: :design,
                                dependent: :restrict_with_error

  validates :name, presence: true
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :background_is_image, if: -> { background.attached? }
  validate :layout_is_placement

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :id) }

  # The configured card layout with this design's field boxes, fonts and colours.
  def card_layout(base = SolidusVirtualGiftCard::Config.card_image_layout)
    base.to_h { |field, style| [field, style.merge((layout || {}).fetch(field.to_s, {}).slice(*PLACEMENT, *STYLE).symbolize_keys)] }
  end

  # The layout editor submits JSON; a blank value goes back to the configured layout.
  def layout=(value)
    value = value.presence && JSON.parse(value) if value.is_a?(String)
    super
  rescue JSON::ParserError
    @invalid_layout = true
  end

  private

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

  def background_is_image
    errors.add(:background, :invalid) unless background.content_type.in?(%w[image/png image/jpeg])
  end
end
