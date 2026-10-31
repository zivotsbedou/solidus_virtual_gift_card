# frozen_string_literal: true

require 'spec_helper'

describe 'Gift card image download', type: :request do
  let(:gift_card) { create(:redeemable_virtual_gift_card) }
  let(:token) { gift_card.order.guest_token }

  before { stub_spree_preferences(SolidusVirtualGiftCard::Config, card_image: true) }

  it 'serves the paid card to the order token holder' do
    get "/gift_cards/#{gift_card.id}/card", params: { token: token }

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq('image/png')
    expect(response.headers['Cache-Control']).to include('no-store')
    expect(response.headers['Content-Disposition']).to include('attachment')
  end

  it 'hides the card without the right token' do
    get "/gift_cards/#{gift_card.id}/card", params: { token: 'wrong' }

    expect(response).to have_http_status(:not_found)
  end

  it 'hides an unpaid card' do
    gift_card.update!(redeemable: false)
    get "/gift_cards/#{gift_card.id}/card", params: { token: token }

    expect(response).to have_http_status(:not_found)
  end

  it 'hides cards when card images are off' do
    stub_spree_preferences(SolidusVirtualGiftCard::Config, card_image: false)
    get "/gift_cards/#{gift_card.id}/card", params: { token: token }

    expect(response).to have_http_status(:not_found)
  end
end
