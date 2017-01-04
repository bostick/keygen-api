class Product < ApplicationRecord
  include Limitable
  include Pageable
  include Roleable

  belongs_to :account
  has_many :policies, dependent: :destroy
  has_many :keys, through: :policies, source: :pool
  has_many :licenses, through: :policies
  has_many :machines, -> { distinct }, through: :licenses
  has_many :users, -> { distinct }, through: :licenses
  has_many :tokens, as: :bearer, dependent: :destroy
  has_one :role, as: :resource, dependent: :destroy

  after_create :set_role

  validates :account, presence: { message: "must exist" }
  validates :name, presence: true

  private

  def set_role
    grant :product
  end
end

# == Schema Information
#
# Table name: products
#
#  id         :uuid             not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  deleted_at :datetime
#  platforms  :jsonb
#  metadata   :jsonb
#  account_id :uuid
#
# Indexes
#
#  index_products_on_account_id  (account_id)
#
