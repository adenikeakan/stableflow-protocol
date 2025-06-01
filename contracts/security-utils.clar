;; StableFlow Security Utils Contract
;; Provides security controls and access management for the StableFlow protocol

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u2001))
(define-constant ERR-CONTRACT-PAUSED (err u2002))
(define-constant ERR-INVALID-AMOUNT (err u2003))
(define-constant ERR-INVALID-ADDRESS (err u2004))
(define-constant ERR-ALREADY-INITIALIZED (err u2005))
(define-constant ERR-NOT-INITIALIZED (err u2006))
(define-constant ERR-INVALID-PARAMETER (err u2007))

;; Contract constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant MIN-AMOUNT u1) ;; Minimum transaction amount
(define-constant MAX-AMOUNT u1000000000000) ;; Maximum transaction amount (1M tokens with 6 decimals)

;; Data variables
(define-data-var contract-paused bool false)
(define-data-var initialized bool false)
(define-data-var emergency-contact principal CONTRACT-OWNER)

;; Data maps
(define-map authorized-operators principal bool)
(define-map authorized-contracts principal bool)

;; Initialize the contract (can only be called once)
(define-public (initialize)
  (begin
    (asserts! (not (var-get initialized)) ERR-ALREADY-INITIALIZED)
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set initialized true)
    (map-set authorized-operators CONTRACT-OWNER true)
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

;; Add authorized operator
(define-public (add-authorized-operator (operator principal))
  (begin
    (asserts! (var-get initialized) ERR-NOT-INITIALIZED)
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-standard operator) ERR-INVALID-ADDRESS)
    (map-set authorized-operators operator true)
    (ok true)
  )
)

;; Remove authorized operator
(define-public (remove-authorized-operator (operator principal))
  (begin
    (asserts! (var-get initialized) ERR-NOT-INITIALIZED)
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (not (is-eq operator CONTRACT-OWNER)) ERR-NOT-AUTHORIZED) ;; Cannot remove contract owner
    (map-delete authorized-operators operator)
    (ok true)
  )
)

;; Check if address is authorized operator
(define-read-only (is-authorized-operator (operator principal))
  (default-to false (map-get? authorized-operators operator))
)

;; Add authorized contract
(define-public (add-authorized-contract (contract principal))
  (begin
    (asserts! (var-get initialized) ERR-NOT-INITIALIZED)
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-standard contract) ERR-INVALID-ADDRESS)
    (map-set authorized-contracts contract true)
    (ok true)
  )
)

;; Remove authorized contract
(define-public (remove-authorized-contract (contract principal))
  (begin
    (asserts! (var-get initialized) ERR-NOT-INITIALIZED)
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (map-delete authorized-contracts contract)
    (ok true)
  )
)

;; Check if contract is authorized
(define-read-only (is-authorized-contract (contract principal))
  (default-to false (map-get? authorized-contracts contract))
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

;; Check if caller is contract owner
(define-read-only (is-contract-owner (caller principal))
  (is-eq caller CONTRACT-OWNER)
)

;; Validate transaction amount
(define-read-only (is-valid-amount (amount uint))
  (and (>= amount MIN-AMOUNT) (<= amount MAX-AMOUNT))
)

;; Validate address
(define-read-only (is-valid-address (address principal))
  (is-standard address)
)

;; Validate percentage (0-10000 for 0.00%-100.00%)
(define-read-only (is-valid-percentage (percentage uint))
  (<= percentage u10000)
)

;; Validate fee rate (0-1000 for 0.00%-10.00%)
(define-read-only (is-valid-fee-rate (fee-rate uint))
  (<= fee-rate u1000)
)

;; Check if operations are allowed (not paused and initialized)
(define-read-only (are-operations-allowed)
  (and (var-get initialized) (not (var-get contract-paused)))
)

;; Check if caller can perform admin operations
(define-read-only (can-perform-admin-operation (caller principal))
  (and (var-get initialized)
       (not (var-get contract-paused))
       (or (is-eq caller CONTRACT-OWNER)
           (is-authorized-operator caller)))
)

;; Check if caller can perform contract operations
(define-read-only (can-perform-contract-operation (caller principal))
  (and (var-get initialized)
       (not (var-get contract-paused))
       (or (is-eq caller CONTRACT-OWNER)
           (is-authorized-operator caller)
           (is-authorized-contract caller)))
)

;; Validate pool parameters
(define-read-only (are-valid-pool-params (token-a principal) (token-b principal) (fee-rate uint))
  (and (is-valid-address token-a)
       (is-valid-address token-b)
       (not (is-eq token-a token-b))
       (is-valid-fee-rate fee-rate))
)

;; Validate liquidity amounts
(define-read-only (are-valid-liquidity-amounts (amount-a uint) (amount-b uint))
  (and (is-valid-amount amount-a)
       (is-valid-amount amount-b)
       (> amount-a u0)
       (> amount-b u0))
)

;; Validate swap parameters
(define-read-only (are-valid-swap-params (amount-in uint) (min-amount-out uint) (slippage-tolerance uint))
  (and (is-valid-amount amount-in)
       (is-valid-amount min-amount-out)
       (is-valid-percentage slippage-tolerance)
       (> amount-in u0)
       (>= amount-in min-amount-out)) ;; Input should be >= minimum output for reasonable swaps
)

;; Get contract owner
(define-read-only (get-contract-owner)
  CONTRACT-OWNER
)

;; Get contract status
(define-read-only (get-contract-status)
  {
    initialized: (var-get initialized),
    paused: (var-get contract-paused),
    owner: CONTRACT-OWNER,
    emergency-contact: (var-get emergency-contact)
  }
)
