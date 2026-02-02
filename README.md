# invoice_system

# What I changed (and why):

1. The original code had a few correctness bugs that would cause wrong behavior immediately. "fully_paid?" was inverted (it returned true when you still owed money), amount_owed summed a non-existent column (:amount_paid instead of :amount), and the associations were backwards (Payment should belongs_to :invoice, not has_one). Fixing these makes the model reflect our schema and the stated rules (partial payments, multiple payments). 

2. The currency handling was also risky: multiplying floats (amount_paid * 100) can introduce rounding errors (e.g., 0.29 * 100 can become 28.999...). I moved all conversions through BigDecimal, which is the typical Ruby way to avoid floating-point money bugs. 

3. I also made the “human-friendly dollars” API explicit via invoice_total_dollars and amount_owed_dollars so it’s always clear when you’re dealing with cents vs. dollars. 

4. Finally, I made error handling and validations more Rails-like. Rails 7 doesn’t use attr_accessible (that was old mass-assignment protection); modern Rails relies on strong parameters at the controller boundary. 

5. In record_payment, I return the Payment object whether it saves or not, so the caller can inspect payment.errors instead of silently failing. 

6. In Payment, I validate raw_payment_method more directly (and normalize string/symbol inputs), while still storing only the integer ID in the database.