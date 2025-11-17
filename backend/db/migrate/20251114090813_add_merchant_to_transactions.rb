class AddMerchantToTransactions < ActiveRecord::Migration[7.1]
  def change
    add_column :transactions, :merchant, :string
  end
end
