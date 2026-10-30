require 'spec_helper'

RSpec.describe SolidusVirtualGiftCard::VoidExpiredAuthorizedEventsJob, type: :job do
  it 'voids the matching expired reservation once, preserving another payment on the same card' do
    card = create(:redeemable_virtual_gift_card, amount: 100)
    expired = create(:gift_card_payment, source: card, amount: 20)
    current = create(:gift_card_payment, source: card, amount: 30)
    expired.authorize!
    current.authorize!
    card.events.where(authorization_code: expired.response_code).update_all(created_at: 2.months.ago)
    2.times { described_class.perform_now }
    expect(expired.reload).to be_void
    expect(current.reload).to be_pending
    expect(card.reload.amount_authorized).to eq(30)
  end

  it 'keeps a captured payment captured' do
    payment = create(:gift_card_payment, amount: 10)
    payment.authorize!
    payment.capture!
    payment.source.events.update_all(created_at: 2.months.ago)
    described_class.perform_now
    expect(payment.reload).to be_completed
    expect(payment.source.reload.amount_used).to eq(10)
  end
end
