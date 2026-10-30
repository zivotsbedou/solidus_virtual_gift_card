# Solidus Virtual Gift Card

Maintained fork of `solidusio-contrib/solidus_virtual_gift_card` for Solidus 4.8,
Rails 8.1, Ruby 3.2–4.x and SQLite. The extension keeps its existing models,
payment method, legacy backend and migration history.

## Install

Add the gem from this repository, bundle, then run:

```sh
bundle exec rails g solidus_virtual_gift_card:install
```

Back up persistent data and rehearse migrations on a disposable copy first.
Create a Gift Card payment method, with customer/admin availability disabled and
auto-capture enabled. Mark a product as Gift Card in the legacy product editor.
Use variants for fixed denominations, disable inventory tracking, and configure
free shipping in a dedicated virtual-gift-card shipping category.

The application owns storefront forms. Pass recipient_name, recipient_email,
purchaser_name and gift_message under `gift_card_details` in the options hash to
`order.contents.add`. Apply codes through `order.apply_gift_card_code(code)`.
Authorize access to the current order before accepting any code. The extension
allocates gift payments on the transition to confirmation; Solidus processes them
at checkout. Bank/payment integrations must charge only their payment amount,
not the original order total.

## Behavior

- Each purchased unit creates one inactive card at the variant price.
- Solidus order-finalized/recalculated events enqueue activation only for paid,
  completed orders. Guest purchases work without an account.
- The recipient email defaults to the buyer. Messages and recipient names are
  available to mail views. Jobs check payment status again before activation.
- Delivery is enqueued once per card; staff can explicitly resend. `sent_at`
  records enqueueing, not confirmed receipt. Configure an Active Job backend.
- Gift-only shipments are shipped automatically after payment without a separate
  shipment email. Mixed shipments remain under normal fulfillment.
- Redemption supports a remaining balance, multiple cards and a second payment
  for the remainder. Currency and card status are checked at payment time.
- Gateway mutations lock the card. Captures and voids are idempotent; cumulative
  refunds cannot exceed a capture. Refunds restore the existing card by default.
- An original purchase that becomes unpaid or canceled cannot fund new payments.
  Review refunds of already-spent gift-card purchases manually.

If scheduled delivery is configured in the admin, run
`solidus_virtual_gift_card:send_current_emails` daily; it catches overdue unsent
cards too. If using authorization instead of immediate capture, schedule
`SolidusVirtualGiftCard::VoidExpiredAuthorizedEventsJob` to release expired
reservations through their matching Solidus payment.

Account store-credit redemption remains available. It locks the card and refuses
conversion while payment reservations are outstanding.

## Development

```sh
mise trust
mise exec -- bundle install
mise exec -- bundle exec rake extension:test_app
mise run test
```

The test app uses Solidus 4.8, Rails 8.1 and SQLite. Admin browser tests require
Chrome. The legacy backend uses Deface; no CoffeeScript dependency is required.
The generated Solidus storefront and new SolidusAdmin require application-owned
integration; this gem does not install a second frontend.
