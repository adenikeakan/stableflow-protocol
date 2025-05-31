;; StableFlow Security Utils Contract - Foundation
;; Provides basic security controls and initialization

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u2001))
(define-constant ERR-CONTRACT-PAUSED (err u2002))
(define-constant ERR-INVALID-AMOUNT (err u2003))
(define-constant ERR-INVALID-ADDRESS (err u2004))
(define-constant ERR-ALREADY-INITIALIZED (err u2005))
(define-constant ERR-NOT-INITIALIZED (err u2006))

;; Contract constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant MIN-AMOUNT u1) ;; Minimum transaction amount
(define-constant MAX-AMOUNT u1000000000000) ;; Maximum transaction amount

;; Data variables
(define-data-var contract-paused bool false)
(define-data-var initialized bool false)
(define-data-var emergency-contact principal CONTRACT-OWNER)

;; Initialize the contract (can only be called once)
(define-public (initialize)
  (begin
    (asserts! (not (var-get initialized)) ERR-ALREADY-INITIALIZED)
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set initialized true)
    (ok true)
  )
)

;; Check if contract is initialized
(define-read-only (is-initialized)
  (var-get initialized)
)

;; Emergency pause - only contract owner or emergency contact
(define-public (emergency-pause)
  (begin
    (asserts! (var-get initialized) ERR-NOT-INITIALIZED)
    (asserts! (or (is-eq tx-sender CONTRACT-OWNER) 
                  (is-eq tx-sender (var-get emergency-contact))) ERR-NOT-AUTHORIZED)
    (var-set contract-paused true)
    (ok true)
  )
)

;; Resume operations - only contract owner
(define-public (resume-operations)
  (begin
    (asserts! (var-get initialized) ERR-NOT-INITIALIZED)
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set contract-paused false)
    (ok true)
  )
)

;; Check if contract is paused
(define-read-only (is-paused)
  (var-get contract-paused)
)

;; Check if caller is contract owner
(define-read-only (is-contract-owner (caller principal))
  (is-eq caller CONTRACT-OWNER)
)

;; Update emergency contact
(define-public (update-emergency-contact (new-contact principal))
  (begin
    (asserts! (var-get initialized) ERR-NOT-INITIALIZED)
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-standard new-contact) ERR-INVALID-ADDRESS)
    (var-set emergency-contact new-contact)
    (ok true)
  )
)

;; Get emergency contact
(define-read-only (get-emergency-contact)
  (var-get emergency-contact)
)

;; Get contract owner
(define-read-only (get-contract-owner)
  CONTRACT-OWNER
)

;; Check if operations are allowed (not paused and initialized)
(define-read-only (are-operations-allowed)
  (and (var-get initialized) (not (var-get contract-paused)))
)
