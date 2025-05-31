;; StableFlow Math Utils Contract - Utility Functions
;; Provides safe mathematical operations and utility functions

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

;; Calculate percentage with precision
(define-read-only (calculate-percentage (amount uint) (percentage uint))
  (begin
    (asserts! (> amount u0) ERR-INVALID-INPUT)
    (asserts! (<= percentage u10000) ERR-INVALID-INPUT) ;; Max 100.00%
    (let ((numerator (unwrap! (safe-multiply amount percentage) ERR-OVERFLOW)))
      (safe-divide numerator u10000)
    )
  )
)

;; Calculate square root using lookup table and approximation
(define-read-only (calculate-sqrt (x uint))
  (begin
    (asserts! (> x u0) ERR-INVALID-INPUT)
    (if (<= x u1)
      (ok x)
      (if (<= x u4)
        (ok u2)
        (if (<= x u9)
          (ok u3)
          (if (<= x u16)
            (ok u4)
            (if (<= x u25)
              (ok u5)
              (if (<= x u36)
                (ok u6)
                (if (<= x u49)
                  (ok u7)
                  (if (<= x u64)
                    (ok u8)
                    (if (<= x u81)
                      (ok u9)
                      (if (<= x u100)
                        (ok u10)
                        ;; For larger numbers, use approximation
                        (let ((approx (/ x u10)))
                          (ok approx)
                        )
                      )
                    )
                  )
                )
              )
            )
          )
        )
      )
    )
  )
)

;; Get minimum of two values
(define-read-only (min (a uint) (b uint))
  (if (<= a b) a b)
)

;; Get maximum of two values
(define-read-only (max (a uint) (b uint))
  (if (>= a b) a b)
)
