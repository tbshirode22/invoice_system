class Invoice < ApplicationRecord
  has_many :payments, dependent: :destroy, inverse_of: :invoice

  # invoice_total is stored as cents (integer).
  validates :invoice_total, 
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # --- Public API (dollar-friendly) ----------------------------------------

  # Optional convenience accessors for human-friendly usage (dollars).
  def invoice_total_dollars
    cents_to_dollars(invoice_total)
  end

  def invoice_total_dollars=(value)
    self.invoice_total = dollars_to_cents(value)
  end

  # True when the invoice is fully paid (or overpaid).
  def fully_paid?
    amount_owed_cents <= 0
  end

  # Remaining amount owed in cents (never negative).
  def amount_owed_cents
    [0, invoice_total - payments.sum(:amount)].max
  end

  # Remaining amount owed in dollars.
  def amount_owed_dollars
    cents_to_dollars(amount_owed_cents)
  end

  # Records a payment against this invoice.
  def record_payment(amount_dollars, payment_method)
    payment = payments.build(
      amount: dollars_to_cents(amount_dollars),
      raw_payment_method: payment_method
    )

    Payment.transaction { payment.save }
    payment
  rescue ActiveRecord::ActiveRecordError => e
    payment ||= payments.build
    payment.errors.add(:base, "Unable to record payment: #{e.message}")
    payment
  end

  private

  def dollars_to_cents(value)
    raise ArgumentError, "Amount is required" if value.nil?

    bd = BigDecimal(value.to_s)
    raise ArgumentError, "Amount must be >= 0" if bd.negative?

    (bd * 100).round(0).to_i
  end

  def cents_to_dollars(cents)
    BigDecimal(cents.to_i) / 100
  end
end