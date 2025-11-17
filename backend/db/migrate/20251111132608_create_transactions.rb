class CreateTransactions < ActiveRecord::Migration[7.1]
  def change
    create_table :transactions do |t|
      t.string :note
      t.decimal :amount
      t.string :category

      t.timestamps
    end
  end
end
