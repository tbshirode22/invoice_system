class Payment < ApplicationRecord
  METHODS = {
    cash:   1,
    check:  2,
    charge: 3
  }.freeze

  belongs_to :invoice, inverse_of: :payments

  # Virtual attribute used by external callers (e.g., :cash / "cash")
  attr_accessor :raw_payment_method

  validates :invoice, presence: true
  validates :amount, 
            presence: true,
            numericality: { only_integer: true, greater_than: 0 }
  validates :payment_method_id, 
            presence: true,
            inclusion: { in: METHODS.values }

  validate :raw_payment_method_is_valid, if: -> { raw_payment_method.present? }

  before_validation :set_payment_method_id, if: -> { raw_payment_method.present? }

  # Returns :cash/:check/:charge based on stored payment_method_id
  def payment_method
    METHODS.key(payment_method_id)
  end

  private

  def set_payment_method_id
    key = normalize_method(raw_payment_method)
    self.payment_method_id = METHODS[key]
  end

  def raw_payment_method_is_valid
    key = normalize_method(raw_payment_method)
    errors.add(:raw_payment_method, "is not supported") unless METHODS.key?(key)
  end

  def normalize_method(value)
    value.is_a?(String) ? value.strip.downcase.to_sym : value.to_sym
  rescue NoMethodError
    nil
  end
end