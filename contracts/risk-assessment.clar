;; risk-assessment.clar
;; This contract evaluates likelihood of invoice payment

(define-data-var admin principal tx-sender)
(define-map risk-scores
  { invoice-id: (string-ascii 64), business: principal }
  {
    score: uint,
    timestamp: uint,
    assessor: principal
  }
)

;; Risk score ranges from 0 to 100, where 100 is lowest risk
(define-constant MIN_RISK_SCORE u0)
(define-constant MAX_RISK_SCORE u100)

;; Error codes
(define-constant ERR_UNAUTHORIZED u100)
(define-constant ERR_INVALID_SCORE u101)
(define-constant ERR_ASSESSMENT_EXISTS u102)

;; Check if caller is admin or authorized assessor
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

;; Assess risk for an invoice
(define-public (assess-risk
  (invoice-id (string-ascii 64))
  (business principal)
  (score uint)
)
  (let ((assessment-key { invoice-id: invoice-id, business: business }))
    (asserts! (is-admin) (err ERR_UNAUTHORIZED))
    (asserts! (and (>= score MIN_RISK_SCORE) (<= score MAX_RISK_SCORE)) (err ERR_INVALID_SCORE))
    (asserts! (is-none (map-get? risk-scores assessment-key)) (err ERR_ASSESSMENT_EXISTS))

    (map-set risk-scores assessment-key {
      score: score,
      timestamp: block-height,
      assessor: tx-sender
    })
    (ok true)
  )
)

;; Update risk assessment
(define-public (update-risk-assessment
  (invoice-id (string-ascii 64))
  (business principal)
  (score uint)
)
  (let ((assessment-key { invoice-id: invoice-id, business: business }))
    (asserts! (is-admin) (err ERR_UNAUTHORIZED))
    (asserts! (and (>= score MIN_RISK_SCORE) (<= score MAX_RISK_SCORE)) (err ERR_INVALID_SCORE))
    (asserts! (is-some (map-get? risk-scores assessment-key)) (err ERR_ASSESSMENT_EXISTS))

    (map-set risk-scores assessment-key {
      score: score,
      timestamp: block-height,
      assessor: tx-sender
    })
    (ok true)
  )
)

;; Get risk score for an invoice
(define-read-only (get-risk-score (invoice-id (string-ascii 64)) (business principal))
  (map-get? risk-scores { invoice-id: invoice-id, business: business })
)

