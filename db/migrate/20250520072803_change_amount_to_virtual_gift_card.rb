class ChangeAmountToVirtualGiftCard < ActiveRecord::Migration[7.0]
  def up
    add_column :spree_virtual_gift_cards, :amount_temp, :decimal, precision: 10, scale: 2, default: 0.0
    execute "UPDATE spree_virtual_gift_cards SET amount_temp = amount"
    remove_column :spree_virtual_gift_cards, :amount
    rename_column :spree_virtual_gift_cards, :amount_temp, :amount
  end

  def down
    add_column :spree_virtual_gift_cards, :amount_temp, :integer
    integer_type = connection.adapter_name.match?(/mysql|trilogy/i) ? "SIGNED" : "INTEGER"
    execute "UPDATE spree_virtual_gift_cards SET amount_temp = CAST(amount AS #{integer_type})"
    remove_column :spree_virtual_gift_cards, :amount
    rename_column :spree_virtual_gift_cards, :amount_temp, :amount
  end
end
