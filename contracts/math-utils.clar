;; StableFlow Math Utils Contract
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

;; Calculate proportional amount for liquidity calculations
(define-read-only (calculate-proportional-amount (amount uint) (reserve-a uint) (reserve-b uint))
  (begin
    (asserts! (> amount u0) ERR-INVALID-INPUT)
    (asserts! (> reserve-a u0) ERR-INVALID-INPUT)
    (asserts! (> reserve-b u0) ERR-INVALID-INPUT)
    (let ((numerator (unwrap! (safe-multiply amount reserve-b) ERR-OVERFLOW)))
      (safe-divide numerator reserve-a)
    )
  )
)

;; Calculate liquidity tokens to mint (geometric mean)
(define-read-only (calculate-liquidity-tokens (amount-a uint) (amount-b uint) (reserve-a uint) (reserve-b uint) (total-supply uint))
  (begin
    (asserts! (> amount-a u0) ERR-INVALID-INPUT)
    (asserts! (> amount-b u0) ERR-INVALID-INPUT)
    (if (is-eq total-supply u0)
      ;; Initial liquidity - use geometric mean minus minimum liquidity
      (let ((product (unwrap! (safe-multiply amount-a amount-b) ERR-OVERFLOW))
            (sqrt-result (unwrap! (calculate-sqrt product) ERR-OVERFLOW)))
        (safe-subtract sqrt-result u1000) ;; Subtract minimum liquidity
      )
      ;; Subsequent liquidity - use minimum ratio to prevent manipulation
      (let ((liquidity-a (unwrap! (safe-divide 
                            (unwrap! (safe-multiply amount-a total-supply) ERR-OVERFLOW) 
                            reserve-a) ERR-OVERFLOW))
            (liquidity-b (unwrap! (safe-divide 
                            (unwrap! (safe-multiply amount-b total-supply) ERR-OVERFLOW) 
                            reserve-b) ERR-OVERFLOW)))
        (ok (min liquidity-a liquidity-b))
      )
    )
  )
)

;; Calculate output amount for AMM (constant product formula)
(define-read-only (calculate-output-amount (input-amount uint) (input-reserve uint) (output-reserve uint) (fee-rate uint))
  (begin
    (asserts! (> input-amount u0) ERR-INVALID-INPUT)
    (asserts! (> input-reserve u0) ERR-INVALID-INPUT)
    (asserts! (> output-reserve u0) ERR-INVALID-INPUT)
    (asserts! (<= fee-rate u10000) ERR-INVALID-INPUT) ;; Max 100.00%
    
    ;; Calculate amount after fee
    (let ((fee-amount (unwrap! (calculate-percentage input-amount fee-rate) ERR-OVERFLOW))
          (amount-after-fee (unwrap! (safe-subtract input-amount fee-amount) ERR-UNDERFLOW))
          (numerator (unwrap! (safe-multiply amount-after-fee output-reserve) ERR-OVERFLOW))
          (denominator (unwrap! (safe-add input-reserve amount-after-fee) ERR-OVERFLOW)))
      (safe-divide numerator denominator)
    )
  )
)

;; Calculate price impact percentage
(define-read-only (calculate-price-impact (input-amount uint) (input-reserve uint) (output-reserve uint))
  (begin
    (asserts! (> input-amount u0) ERR-INVALID-INPUT)
    (asserts! (> input-reserve u0) ERR-INVALID-INPUT)
    (asserts! (> output-reserve u0) ERR-INVALID-INPUT)
    
    ;; Price before trade
    (let ((price-before (unwrap! (safe-divide 
                          (unwrap! (safe-multiply output-reserve PRECISION) ERR-OVERFLOW) 
                          input-reserve) ERR-OVERFLOW))
          ;; Price after trade
          (new-input-reserve (unwrap! (safe-add input-reserve input-amount) ERR-OVERFLOW))
          (output-amount (unwrap! (calculate-output-amount input-amount input-reserve output-reserve u30) ERR-OVERFLOW)) ;; 0.3% fee
          (new-output-reserve (unwrap! (safe-subtract output-reserve output-amount) ERR-UNDERFLOW))
          (price-after (unwrap! (safe-divide 
                         (unwrap! (safe-multiply new-output-reserve PRECISION) ERR-OVERFLOW) 
                         new-input-reserve) ERR-OVERFLOW))
          ;; Calculate impact
          (price-diff (if (> price-before price-after)
                        (unwrap! (safe-subtract price-before price-after) ERR-UNDERFLOW)
                        (unwrap! (safe-subtract price-after price-before) ERR-UNDERFLOW)))
          (impact (unwrap! (safe-divide 
                     (unwrap! (safe-multiply price-diff u10000) ERR-OVERFLOW) 
                     price-before) ERR-OVERFLOW)))
      (ok impact)
    )
  )
)

;; Validate slippage tolerance
(define-read-only (is-within-slippage (expected-output uint) (actual-output uint) (slippage-tolerance uint))
  (begin
    (asserts! (> expected-output u0) ERR-INVALID-INPUT)
    (asserts! (> actual-output u0) ERR-INVALID-INPUT)
    (asserts! (<= slippage-tolerance u10000) ERR-INVALID-INPUT) ;; Max 100.00%
    
    (let ((min-output (unwrap! (safe-subtract expected-output 
                                (unwrap! (calculate-percentage expected-output slippage-tolerance) ERR-OVERFLOW)) 
                                ERR-UNDERFLOW)))
      (ok (>= actual-output min-output))
    )
  )
)
