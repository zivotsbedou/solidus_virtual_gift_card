# frozen_string_literal: true

# Card designs are gift card variants: staff place the card's fields on each variant's image.
class Spree::Admin::GiftCardLayoutsController < Spree::Admin::BaseController # rubocop:disable Style/ClassAndModuleChildren
  before_action :load_variant, except: :index

  def index
    @variants = Spree::Product.where(gift_card: true).includes(variants_including_master: :images)
                              .flat_map { |product| product.variants.presence || [product.master] }
  end

  def edit; end

  def update
    if @variant.update(gift_card_layout: params.dig(:variant, :gift_card_layout))
      flash[:success] = flash_message_for(@variant, :successfully_updated)
    else
      flash[:error] = @variant.errors.full_messages.to_sentence
    end
    redirect_to edit_admin_gift_card_layout_path(@variant)
  end

  # The card drawn with sample details and the unsaved layout from the editor.
  def preview
    @variant.gift_card_layout = params.dig(:variant, :gift_card_layout) if params.dig(:variant, :gift_card_layout)
    @variant.restore_attributes if @variant.invalid?
    sample = Spree::VirtualGiftCard.new(
      line_item: Spree::LineItem.new(variant: @variant), amount: 1500,
      currency: current_store&.default_currency.presence || Spree::Config.currency, redemption_code: 'K7M2PQ9X',
      recipient_name: t('spree.admin.gift_card_layouts.sample.recipient_name'),
      purchaser_name: t('spree.admin.gift_card_layouts.sample.purchaser_name'),
      gift_message: t('spree.admin.gift_card_layouts.sample.gift_message')
    )
    response.headers['Cache-Control'] = 'no-store'
    send_data SolidusVirtualGiftCard::Config.card_image_class.new(sample).to_png, type: 'image/png', disposition: 'inline'
  end

  private

  def load_variant
    @variant = Spree::Variant.joins(:product).merge(Spree::Product.where(gift_card: true)).find(params[:id])
  end

  def model_class
    Spree::Variant
  end

  def action
    { preview: :show, index: :index }.fetch(params[:action].to_sym, :update)
  end
end
