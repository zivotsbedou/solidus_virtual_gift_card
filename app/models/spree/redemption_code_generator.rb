# frozen_string_literal: true

module Spree::RedemptionCodeGenerator
  # No 0/O, 1/I/L or U, so printed codes read and type without mix-ups.
  ALPHABET = "23456789ABCDEFGHJKMNPQRSTVWXYZ".chars.freeze

  def self.generate_redemption_code
    Array.new(SolidusVirtualGiftCard::Config.redemption_code_length) { ALPHABET[SecureRandom.random_number(ALPHABET.size)] }.join
  end

  # Typed codes may differ in case, spacing and dashes.
  def self.format_redemption_code_for_lookup(redemption_code)
    redemption_code.to_s.upcase.gsub(/[^0-9A-Z]/, '')
  end
end
