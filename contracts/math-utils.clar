;; StableFlow Math Utils Contract - Foundation
;; Provides basic constants and error definitions

;; Error constants
(define-constant ERR-DIVISION-BY-ZERO (err u1001))
(define-constant ERR-OVERFLOW (err u1002))
(define-constant ERR-UNDERFLOW (err u1003))
(define-constant ERR-INVALID-INPUT (err u1004))

;; Constants
(define-constant MAX-UINT u340282366920938463463374607431768211455)
(define-constant PRECISION u1000000) ;; 6 decimal places for calculations

;; Basic validation function
(define-read-only (is-positive (value uint))
  (> value u0)
)

;; Get precision constant
(define-read-only (get-precision)
  PRECISION
)

;; Validate input is not zero
(define-read-only (is-non-zero (value uint))
  (> value u0)
)
