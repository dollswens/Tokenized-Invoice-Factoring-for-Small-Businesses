;; invoice-certification.clar
;; This contract confirms delivery of goods or services

(define-data-var admin principal tx-sender)
(define-map invoices
  { invoice-id: (string-ascii 64), business: principal }
  {
    amount: uint,
    due-date: uint,
    payer: principal,
    certified: bool
  }
)

;; Error codes
(define-constant ERR_UNAUTHORIZED u100)
(define-constant ERR_INVOICE_EXISTS u101)
(define-constant ERR_INVOICE_NOT_FOUND u102)
(define-constant ERR_ALREADY_CERTIFIED u103)

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

;; Register a new invoice
(define-public (register-invoice
  (invoice-id (string-ascii 64))
  (amount uint)
  (due-date uint)
  (payer principal)
)
  (let ((invoice-key { invoice-id: invoice-id, business: tx-sender }))
    (asserts! (is-none (map-get? invoices invoice-key)) (err ERR_INVOICE_EXISTS))
    (map-set invoices invoice-key {
      amount: amount,
      due-date: due-date,
      payer: payer,
      certified: false
    })
    (ok true)
  )
)

;; Certify an invoice (by admin or authorized party)
(define-public (certify-invoice (invoice-id (string-ascii 64)) (business principal))
  (let (
    (invoice-key { invoice-id: invoice-id, business: business })
    (invoice-data (unwrap! (map-get? invoices invoice-key) (err ERR_INVOICE_NOT_FOUND)))
  )
    (asserts! (is-admin) (err ERR_UNAUTHORIZED))
    (asserts! (not (get certified invoice-data)) (err ERR_ALREADY_CERTIFIED))

    (map-set invoices invoice-key (merge invoice-data { certified: true }))
    (ok true)
  )
)

;; Get invoice details
(define-read-only (get-invoice (invoice-id (string-ascii 64)) (business principal))
  (map-get? invoices { invoice-id: invoice-id, business: business })
)

;; Check if an invoice is certified
(define-read-only (is-invoice-certified (invoice-id (string-ascii 64)) (business principal))
  (match (map-get? invoices { invoice-id: invoice-id, business: business })
    invoice-data (get certified invoice-data)
    false
  )
)

