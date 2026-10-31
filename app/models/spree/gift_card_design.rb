# frozen_string_literal: true

# A card look customers choose at purchase: background artwork plus the texts and colours drawn on it.
class Spree::GiftCardDesign < Spree::Base
  COLOR = /\A#\h{6}\z/
  ALIGNMENTS = %w[low centre].freeze
  ROLES = %i[amount ink box].freeze
  # Where a field sits, as fractions of the card: x and width of its width, y and size of its height.
  PLACEMENT = %w[x y width size].freeze

  has_one_attached :background
  has_many :virtual_gift_cards, class_name: 'Spree::VirtualGiftCard', foreign_key: :design_id, inverse_of: :design,
                                dependent: :restrict_with_error

  validates :name, presence: true
  validates :amount_color, :ink_color, :box_color, format: { with: COLOR }
  validates :footer_align, inclusion: { in: ALIGNMENTS }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :background_is_image, if: -> { background.attached? }
  validate :layout_is_placement

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :id) }

  # Colour of a text role as [r, g, b].
  def rgb(role)
    public_send("#{role}_color").delete('#').scan(/../).map(&:hex)
  end

  # The configured card layout with this design's footer alignment and field placement.
  def card_layout(base = SolidusVirtualGiftCard::Config.card_image_layout)
    base.to_h do |field, style|
      style = style.dup
      style[:align] = footer_align.to_sym if style[:align] == :design
      style[:x] = style.dig(:x_by_align, style.fetch(:align, :low)) || style[:x]
      style.delete(:x_by_align)
      [field, style.merge((layout || {}).fetch(field.to_s, {}).slice(*PLACEMENT).symbolize_keys)]
    end
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
    valid = !@invalid_layout && (layout.nil? || (layout.is_a?(Hash) && layout.values.all? do |placement|
      placement.is_a?(Hash) && placement.keys.all?(PLACEMENT.method(:include?)) &&
        placement.values.all? { |value| value.is_a?(Numeric) && value.between?(0, 1) }
    end))
    errors.add(:layout, :invalid) unless valid
  end

  def background_is_image
    errors.add(:background, :invalid) unless background.content_type.in?(%w[image/png image/jpeg])
  end
end
