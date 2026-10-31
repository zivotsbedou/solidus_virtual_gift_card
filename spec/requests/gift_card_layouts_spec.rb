# frozen_string_literal: true

require 'spec_helper'

describe 'Gift card layout administration', type: :request do
  stub_authorization!

  let(:product) { create(:product, gift_card: true) }
  let(:variant) { create(:variant, product: product) }

  before do
    require 'vips'
    stub_spree_preferences(SolidusVirtualGiftCard::Config, card_image: true)
  end

  it 'saves a layout for a gift card variant' do
    patch "/admin/gift_card_layouts/#{variant.id}", params: { variant: { gift_card_layout: '{"code":{"y":0.1}}' } }

    expect(response).to redirect_to("/admin/gift_card_layouts/#{variant.id}/edit")
    expect(variant.reload.gift_card_layout).to eq('code' => { 'y' => 0.1 })
  end

  it 'previews an unsaved layout without saving it' do
    get "/admin/gift_card_layouts/#{variant.id}/preview", params: { variant: { gift_card_layout: '{"code":{"y":0.1,"color":"#ae9ac6"}}' } }

    expect(response.media_type).to eq('image/png')
    expect(variant.reload.gift_card_layout).to be_nil
  end

  it 'ignores an invalid layout in the preview' do
    get "/admin/gift_card_layouts/#{variant.id}/preview", params: { variant: { gift_card_layout: '{"code":{"y":7}}' } }

    expect(response.media_type).to eq('image/png')
  end

  it 'does not place fields on other products' do
    other = create(:variant)

    expect { get "/admin/gift_card_layouts/#{other.id}/edit" }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
