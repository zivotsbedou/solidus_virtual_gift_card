require 'spec_helper'
require File.expand_path('../db/migrate/20250520072803_change_amount_to_virtual_gift_card', __dir__)

RSpec.describe ChangeAmountToVirtualGiftCard do
  it 'rolls down and up on an isolated SQLite database' do
    stub_const('GiftMigrationRecord', Class.new(ActiveRecord::Base))
    GiftMigrationRecord.establish_connection(adapter: 'sqlite3', database: ':memory:')
    GiftMigrationRecord.connection_pool.with_connection do |connection|
      connection.create_table(:spree_virtual_gift_cards) { |table| table.decimal :amount, precision: 10, scale: 2 }
      connection.execute('INSERT INTO spree_virtual_gift_cards (amount) VALUES (500)')
      migration = described_class.new
      migration.exec_migration(connection, :down)
      expect(connection.columns(:spree_virtual_gift_cards).find { |column| column.name == 'amount' }.type).to eq(:integer)
      expect(connection.select_value('SELECT amount FROM spree_virtual_gift_cards')).to eq(500)
      migration.exec_migration(connection, :up)
      expect(connection.columns(:spree_virtual_gift_cards).find { |column| column.name == 'amount' }.type).to eq(:decimal)
      expect(connection.select_value('SELECT amount FROM spree_virtual_gift_cards')).to eq(500)
    end
  ensure
    GiftMigrationRecord.connection_pool.disconnect!
  end
end
