class CreatePayments < ActiveRecord::Migration[8.0]
  def change
    create_table :payments do |t|
      t.string :reference, null: false, index: { unique: true }
      t.references :user, null: false, foreign_key: true
      t.references :address, null: false, foreign_key: true
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.string :status, null: false, default: 'UNPAID'
      t.string :payment_method, null: false
      t.string :payment_channel
      t.text :checkout_url
      t.text :qr_url
      t.datetime :expired_at
      t.datetime :paid_at
      t.jsonb :tripay_response, default: {}
      t.text :notes

      t.timestamps
    end

    add_index :payments, :status
  end
end
