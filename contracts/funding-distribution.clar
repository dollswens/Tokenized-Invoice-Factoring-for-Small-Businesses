;; funding-distribution.clar
;; This contract manages early payment to small businesses

(define-data-var admin principal tx-sender)
(define-data-var fee-percentage uint u5) ;; 5% default fee
(define-map funded-invoices
  { invoice-id: (string-ascii 64), business: principal }
  {
    amount: uint,
    fee-amount: uint,
    funder: principal,
    funded-at: uint,
    repaid: bool
  }
)

;; Error codes
(define-constant ERR_UNAUTHORIZED u100)
(define-constant ERR_ALREADY_FUNDED u101)
(define-constant ERR_NOT_FUNDED u102)
(define-constant ERR_INSUFFICIENT_FUNDS u103)
(define-constant ERR_INVALID_FEE u104)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

;; Set a new admin
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-admin) (err ERR_UNAUTHORIZED))
    (ok (var-set admin new-admin))
  )
)

;; Set fee percentage (admin only)
(define-public (set-fee-percentage (new-fee-percentage uint))
  (begin
    (asserts! (is-admin) (err ERR_UNAUTHORIZED))
    (asserts! (<= new-fee-percentage u20) (err ERR_INVALID_FEE)) ;; Max 20% fee
    (ok (var-set fee-percentage new-fee-percentage))
  )
)

;; Calculate fee amount
(define-private (calculate-fee (amount uint))
  (/ (* amount (var-get fee-percentage)) u100)
)

;; Fund an invoice
(define-public (fund-invoice
  (invoice-id (string-ascii 64))
  (business principal)
  (amount uint)
)
  (let (
    (invoice-key { invoice-id: invoice-id, business: business })
    (fee (calculate-fee amount))
    (net-amount (- amount fee))
  )
    (asserts! (is-none (map-get? funded-invoices invoice-key)) (err ERR_ALREADY_FUNDED))

    ;; Transfer funds to business (would use actual token transfer in production)
    ;; This is a simplified version without actual token transfers

    (map-set funded-invoices invoice-key {
      amount: amount,
      fee-amount: fee,
      funder: tx-sender,
      funded-at: block-height,
      repaid: false
    })
    (ok true)
  )
)

;; Mark invoice as repaid (when payer pays the invoice)
(define-public (mark-invoice-repaid (invoice-id (string-ascii 64)) (business principal))
  (let (
    (invoice-key { invoice-id: invoice-id, business: business })
    (funding-data (unwrap! (map-get? funded-invoices invoice-key) (err ERR_NOT_FUNDED)))
  )
    (asserts! (or (is-admin) (is-eq tx-sender (get funder funding-data))) (err ERR_UNAUTHORIZED))

    (map-set funded-invoices invoice-key (merge funding-data { repaid: true }))
    (ok true)
  )
)

;; Get funding details for an invoice
(define-read-only (get-funding-details (invoice-id (string-ascii 64)) (business principal))
  (map-get? funded-invoices { invoice-id: invoice-id, business: business })
)

;; Get current fee percentage
(define-read-only (get-fee-percentage)
  (var-get fee-percentage)
)

