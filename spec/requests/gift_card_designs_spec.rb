# frozen_string_literal: true

require 'spec_helper'

describe 'Gift card design administration', type: :request do
  stub_authorization!

  let(:png) do
    image = Vips::Image.black(300, 200).new_from_image([250, 237, 200]).copy(interpretation: :srgb)
    Rack::Test::UploadedFile.new(StringIO.new(image.write_to_buffer('.png')), 'image/png', original_filename: 'card.png')
  end

  before do
    require 'vips'
    stub_spree_preferences(SolidusVirtualGiftCard::Config, card_image: true)
  end

  it 'creates a design with its artwork and previews the finished card' do
    post '/admin/gift_card_designs', params: { gift_card_design: { name: 'Champagne', heading: 'Milý dáreček pro:', background: png, ink_color: '#2d3142' } }
    design = Spree::GiftCardDesign.last

    expect(response).to redirect_to("/admin/gift_card_designs/#{design.id}/edit")
    expect(design.background).to be_attached

    get "/admin/gift_card_designs/#{design.id}/preview"

    expect(response.media_type).to eq('image/png')
    expect(Vips::Image.new_from_buffer(response.body, '').width).to eq(300)
  end

  it 'lists designs with their previews' do
    design = Spree::GiftCardDesign.create!(name: 'Vánoční')

    get '/admin/gift_card_designs'

    expect(response.body).to include('Vánoční', "/admin/gift_card_designs/#{design.id}/preview")
  end
end
