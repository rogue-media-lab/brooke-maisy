class AddClientToPurchaseOrders < ActiveRecord::Migration[8.1]
  class PurchaseOrder < ApplicationRecord
    self.table_name = "purchase_orders"
  end

  class Quote < ApplicationRecord
    self.table_name = "quotes"
  end

  def up
    add_reference :purchase_orders, :client, foreign_key: true, null: true

    # Backfill: set client_id from the linked quote's client
    PurchaseOrder.find_each do |po|
      next unless po.quote_id.present?
      quote = Quote.find_by(id: po.quote_id)
      next unless quote&.client_id.present?
      po.update_column(:client_id, quote.client_id)
    end

    # Enforce not null now that data is backfilled
    change_column_null :purchase_orders, :client_id, false

    # Make quote_id nullable (PO can exist without a quote)
    change_column_null :purchase_orders, :quote_id, true

    # Make line item FKs nullable (manual PO items may not have a quote_line_item)
    change_column_null :purchase_order_line_items, :quote_line_item_id, true
    change_column_null :purchase_order_line_items, :product_id, true
  end

  def down
    change_column_null :purchase_order_line_items, :product_id, false
    change_column_null :purchase_order_line_items, :quote_line_item_id, false
    change_column_null :purchase_orders, :quote_id, false
    remove_reference :purchase_orders, :client
  end
end
