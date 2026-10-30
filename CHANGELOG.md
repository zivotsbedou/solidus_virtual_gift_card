# Changelog

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
