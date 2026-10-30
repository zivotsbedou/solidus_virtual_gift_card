# frozen_string_literal: true

module SolidusVirtualGiftCard
  class VoidExpiredAuthorizedEventsJob < ActiveJob::Base
    queue_as :default

    def perform
      ::Spree::VirtualGiftCardEvent.where(action: 'authorize')
        .where('created_at < ?', SolidusVirtualGiftCard::Config.authorize_timeout.ago).find_each do |event|
        payment = ::Spree::Payment.find_by(source: event.virtual_gift_card, response_code: event.authorization_code)
        next unless payment

        payment.with_lock { payment.void_transaction! if payment.pending? }
      end
    end
  end
end
