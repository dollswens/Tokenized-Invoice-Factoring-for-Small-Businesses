;; business-verification.clar
;; This contract validates the legitimacy of small enterprises

(define-data-var admin principal tx-sender)
(define-map verified-businesses principal bool)

;; Error codes
(define-constant ERR_UNAUTHORIZED u100)
(define-constant ERR_ALREADY_VERIFIED u101)
(define-constant ERR_NOT_VERIFIED u102)

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

;; Verify a business
(define-public (verify-business (business principal))
  (begin
    (asserts! (is-admin) (err ERR_UNAUTHORIZED))
    (asserts! (is-none (map-get? verified-businesses business)) (err ERR_ALREADY_VERIFIED))
    (map-set verified-businesses business true)
    (ok true)
  )
)

;; Revoke verification
(define-public (revoke-verification (business principal))
  (begin
    (asserts! (is-admin) (err ERR_UNAUTHORIZED))
    (asserts! (is-some (map-get? verified-businesses business)) (err ERR_NOT_VERIFIED))
    (map-delete verified-businesses business)
    (ok true)
  )
)

;; Check if a business is verified
(define-read-only (is-business-verified (business principal))
  (default-to false (map-get? verified-businesses business))
)

