class CreateOrders < ActiveRecord::Migration[7.0]
  def change
    create_table :orders do |t|
      t.string :paypal_order_id
      t.string :paypal_transaction_id
      t.decimal :amount
      t.string :currency
      t.string :status

      t.timestamps
    end
  end
end
