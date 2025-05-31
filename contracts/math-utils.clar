;; StableFlow Math Utils Contract - Safe Arithmetic Operations
;; Provides safe mathematical operations for the StableFlow protocol

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

;; Safe multiplication - prevents overflow
(define-read-only (safe-multiply (a uint) (b uint))
  (begin
    (asserts! (> a u0) ERR-INVALID-INPUT)
    (asserts! (> b u0) ERR-INVALID-INPUT)
    (let ((result (* a b)))
      (asserts! (>= result a) ERR-OVERFLOW)
      (asserts! (>= result b) ERR-OVERFLOW)
      (ok result)
    )
  )
)

;; Safe addition - prevents overflow
(define-read-only (safe-add (a uint) (b uint))
  (let ((result (+ a b)))
    (asserts! (>= result a) ERR-OVERFLOW)
    (asserts! (>= result b) ERR-OVERFLOW)
    (ok result)
  )
)

;; Safe subtraction - prevents underflow
(define-read-only (safe-subtract (a uint) (b uint))
  (begin
    (asserts! (>= a b) ERR-UNDERFLOW)
    (ok (- a b))
  )
)

;; Safe division - prevents division by zero
(define-read-only (safe-divide (a uint) (b uint))
  (begin
    (asserts! (> b u0) ERR-DIVISION-BY-ZERO)
    (ok (/ a b))
  )
)
