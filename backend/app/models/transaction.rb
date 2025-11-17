class Transaction < ApplicationRecord
  has_one_attached :payment_screenshot
end
