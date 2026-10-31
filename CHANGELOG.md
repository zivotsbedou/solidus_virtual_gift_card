# Changelog

## Unreleased

- Configurable redemption code length; codes avoid look-alike characters and
  ignore case, spaces and dashes when typed.
- Customer-chosen amounts for gift card products, within a configured range.
- Optional card images drawn with libvips, attached to the email and downloadable
  by the buyer with the order token.
- Deliver a card to the recipient or to the buyer to print.

## 2.0.0

- Support Solidus 4.8, Rails 8.1, Ruby 4 and SQLite.
- Activate and email cards only after payment; support guest purchasers.
- Generate codes with SecureRandom; validate recipient email and redemption.
- Fix duplicate cards with legacy promotions and synchronize cart quantities.
- Capture gift payments directly, reject inactive cards, make capture/void
  idempotent and cap cumulative refunds.
- Lock account-credit conversion and reject outstanding reservations.
- Match expiry to the correct payment authorization.
- Preserve the legacy admin with a native date field and explicit email resend.
- Preserve upstream migrations and existing tests, updating their payment and
  authentication assumptions. Add safety regression tests.

Earlier history: https://github.com/solidusio-contrib/solidus_virtual_gift_card/releases
