# frozen_string_literal: true

# A card look customers choose at purchase: background artwork plus the texts and colours drawn on it.
class Spree::GiftCardDesign < Spree::Base
  COLOR = /\A#\h{6}\z/
  ALIGNMENTS = %w[low centre].freeze
  ROLES = %i[amount ink box].freeze

  has_one_attached :background
  has_many :virtual_gift_cards, class_name: 'Spree::VirtualGiftCard', foreign_key: :design_id, inverse_of: :design,
                                dependent: :restrict_with_error

  validates :name, presence: true
  validates :amount_color, :ink_color, :box_color, format: { with: COLOR }
  validates :footer_align, inclusion: { in: ALIGNMENTS }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :background_is_image, if: -> { background.attached? }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :id) }

  # Colour of a text role as [r, g, b].
  def rgb(role)
    public_send("#{role}_color").delete('#').scan(/../).map(&:hex)
  end

  private

  def background_is_image
    errors.add(:background, :invalid) unless background.content_type.in?(%w[image/png image/jpeg])
  end
end
