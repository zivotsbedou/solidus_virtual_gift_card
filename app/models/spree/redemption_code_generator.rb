# frozen_string_literal: true

module Spree::RedemptionCodeGenerator
  def self.generate_redemption_code
    SecureRandom.alphanumeric(24).upcase
  end

  def self.format_redemption_code_for_lookup(redemption_code)
    redemption_code.to_s.strip.delete('-').upcase
  end
end
