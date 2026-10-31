# frozen_string_literal: true

require 'spec_helper'

describe 'Gift card template administration', type: :request do
  stub_authorization!

  let(:png) do
    image = Vips::Image.black(300, 200).new_from_image([250, 237, 200]).copy(interpretation: :srgb)
    Rack::Test::UploadedFile.new(StringIO.new(image.write_to_buffer('.png')), 'image/png', original_filename: 'card.png')
  end

  before do
    require 'vips'
    stub_spree_preferences(SolidusVirtualGiftCard::Config, card_image: true)
  end

  it 'creates a template with its artwork and previews the card' do
    post '/admin/gift_card_templates', params: { gift_card_template: { name: 'Champagne', background: png } }
    template = Spree::GiftCardTemplate.last

    expect(response).to redirect_to("/admin/gift_card_templates/#{template.id}/edit")
    expect(template.background).to be_attached

    get "/admin/gift_card_templates/#{template.id}/preview"

    expect(response.media_type).to eq('image/png')
    expect(Vips::Image.new_from_buffer(response.body, '').width).to eq(300)
  end

  it 'renames a template and saves its layout' do
    template = Spree::GiftCardTemplate.create!(name: 'Old')

    patch "/admin/gift_card_templates/#{template.id}", params: { gift_card_template: { name: 'New', layout: '{"code":{"y":0.1}}' } }

    expect(template.reload).to have_attributes(name: 'New', layout: { 'code' => { 'y' => 0.1 } })
  end

  it 'previews an unsaved layout without saving it' do
    template = Spree::GiftCardTemplate.create!(name: 'Champagne')

    get "/admin/gift_card_templates/#{template.id}/preview", params: { gift_card_template: { layout: '{"code":{"y":0.1,"color":"#ae9ac6"}}' } }

    expect(response.media_type).to eq('image/png')
    expect(template.reload.layout).to be_nil
  end

  it 'ignores an invalid layout in the preview' do
    template = Spree::GiftCardTemplate.create!(name: 'Champagne')

    get "/admin/gift_card_templates/#{template.id}/preview", params: { gift_card_template: { layout: '{"code":{"y":7}}' } }

    expect(response.media_type).to eq('image/png')
  end

  it 'lets a gift card variant pick its template' do
    template = Spree::GiftCardTemplate.create!(name: 'Christmas')
    variant = create(:variant, product: create(:product, gift_card: true))

    patch "/admin/products/#{variant.product.slug}/variants/#{variant.id}", params: { variant: { gift_card_template_id: template.id } }

    expect(variant.reload.gift_card_template).to eq(template)
  end

  it 'lets a gift card without variants pick its template on the product' do
    template = Spree::GiftCardTemplate.create!(name: 'Plain')
    product = create(:product, gift_card: true)

    patch "/admin/products/#{product.slug}", params: { product: { gift_card_template_id: template.id } }

    expect(product.master.reload.gift_card_template).to eq(template)
  end
end
