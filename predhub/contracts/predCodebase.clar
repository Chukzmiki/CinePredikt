;; Movie Box Office Prediction Market Contract - V3 (Final)
;; Added support for multiple correct ranges and fixed multiplier predictions

;; Error Constants
(define-constant contract-owner tx-sender)
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-DOES-NOT-EXIST (err u102))
(define-constant ERR-PREDICTION-CLOSED (err u103))
(define-constant ERR-INSUFFICIENT-FUNDS (err u104))
(define-constant ERR-ALREADY-SETTLED (err u105))
(define-constant ERR-PREDICTION-NOT-CANCELABLE (err u107))
(define-constant ERR-INVALID-RANGE-COUNT (err u108))
(define-constant ERR-INVALID-CLOSE-HEIGHT (err u109))
(define-constant ERR-INVALID-PREDICTION-TYPE (err u110))
(define-constant ERR-MISSING-MULTIPLIERS (err u111))
(define-constant ERR-INVALID-RANGE (err u112))
(define-constant ERR-NO-CORRECT-PREDICTIONS (err u114))
(define-constant ERR-TOO-MANY-OUTCOMES (err u115))
(define-constant ERR-INVALID-OUTCOME (err u116))
(define-constant ERR-NOT-CORRECT (err u117))
(define-constant ERR-REFUND-FAILED (err u118))
(define-constant ERR-INVALID-MOVIE-DETAILS (err u120))
(define-constant ERR-INVALID-PREDICTION-AMOUNT (err u121))

;; Data variables
(define-data-var next-prediction-id uint u0)

;; Prediction types
(define-data-var prediction-types (list 10 (string-ascii 20)) (list "winner-takes-all" "weighted-share" "fixed-multiplier"))

;; Define prediction structure
(define-map predictions
  { prediction-id: uint }
  {
    creator: principal,
    movie-details: (string-ascii 256),
    revenue-ranges: (list 10 (string-ascii 64)),
    total-predicted-amount: uint,
    is-prediction-open: bool,
    correct-ranges: (list 5 uint),
    prediction-close-height: uint,
    prediction-type: (string-ascii 20),
    multipliers: (optional (list 10 uint))
  }
)

;; Define predictions structure
(define-map user-predictions
  { prediction-id: uint, predictor: principal }
  { chosen-range: uint, predicted-amount: uint }
)

;; Private functions
(define-private (calculate-reward (prediction { creator: principal, movie-details: (string-ascii 256), revenue-ranges: (list 10 (string-ascii 64)), total-predicted-amount: uint, is-prediction-open: bool, correct-ranges: (list 5 uint), prediction-close-height: uint, prediction-type: (string-ascii 20), multipliers: (optional (list 10 uint)) }) (user-pred { chosen-range: uint, predicted-amount: uint }) (correct-range-ids (list 5 uint)))
  (let
    (
      (pred-type (get prediction-type prediction))
      (total-pool (get total-predicted-amount prediction))
      (user-amount (get predicted-amount user-pred))
    )
    (if (is-eq pred-type "winner-takes-all")
      (/ total-pool (len correct-range-ids))
      (if (is-eq pred-type "weighted-share")
        (/ (* user-amount total-pool) total-pool)
        (let
          (
            (multiplier-list (unwrap! (get multipliers prediction) u0))
            (chosen-multiplier (unwrap! (element-at multiplier-list (- (get chosen-range user-pred) u1)) u0))
          )
          (+ user-amount (* user-amount (/ chosen-multiplier u100)))
        )
      )
    )
  )
)

(define-private (validate-ranges-helper (ranges (list 5 uint)) (max-range uint))
  (let
    (
      (range-1 (element-at ranges u0))
      (range-2 (element-at ranges u1))
      (range-3 (element-at ranges u2))
      (range-4 (element-at ranges u3))
      (range-5 (element-at ranges u4))
    )
    (and
      (match range-1
        value (and (> value u0) (<= value max-range))
        true)
      (match range-2
        value (and (> value u0) (<= value max-range))
        true)
      (match range-3
        value (and (> value u0) (<= value max-range))
        true)
      (match range-4
        value (and (> value u0) (<= value max-range))
        true)
      (match range-5
        value (and (> value u0) (<= value max-range))
        true)
    )
  )
)

(define-private (process-refund (prediction-id uint))
  (let
    ((user-pred (get-user-prediction prediction-id tx-sender)))
    (match user-pred
      pred-data (match (as-contract (stx-transfer? (get predicted-amount pred-data) tx-sender tx-sender))
        success (begin
          (map-delete user-predictions { prediction-id: prediction-id, predictor: tx-sender })
          (ok true)
        )
        error ERR-REFUND-FAILED
      )
      (ok true)
    )
  )
)

;; Read-only functions
(define-read-only (get-prediction (prediction-id uint))
  (map-get? predictions { prediction-id: prediction-id })
)

(define-read-only (get-user-prediction (prediction-id uint) (predictor principal))
  (map-get? user-predictions { prediction-id: prediction-id, predictor: predictor })
)

(define-read-only (get-current-block-height)
  block-height
)

;; Public functions
(define-public (create-prediction (movie-details (string-ascii 256)) (revenue-ranges (list 10 (string-ascii 64))) (prediction-close-height uint) (prediction-type (string-ascii 20)) (multipliers (optional (list 10 uint))))
  (let
    (
      (new-prediction-id (var-get next-prediction-id))
    )
    (asserts! (> (len movie-details) u0) ERR-INVALID-MOVIE-DETAILS)
    (asserts! (> (len revenue-ranges) u1) ERR-INVALID-RANGE-COUNT)
    (asserts! (> prediction-close-height block-height) ERR-INVALID-CLOSE-HEIGHT)
    (asserts! (is-some (index-of (var-get prediction-types) prediction-type)) ERR-INVALID-PREDICTION-TYPE)
    (asserts! (or (is-eq prediction-type "winner-takes-all") (is-eq prediction-type "weighted-share") (is-some multipliers)) ERR-MISSING-MULTIPLIERS)
    (map-set predictions
      { prediction-id: new-prediction-id }
      {
        creator: tx-sender,
        movie-details: movie-details,
        revenue-ranges: revenue-ranges,
        total-predicted-amount: u0,
        is-prediction-open: true,
        correct-ranges: (list),
        prediction-close-height: prediction-close-height,
        prediction-type: prediction-type,
        multipliers: multipliers
      }
    )
    (var-set next-prediction-id (+ new-prediction-id u1))
    (ok new-prediction-id)
  )
)

(define-public (make-prediction (prediction-id uint) (chosen-range uint) (prediction-amount uint))
  (let
    (
      (prediction (unwrap! (get-prediction prediction-id) ERR-DOES-NOT-EXIST))
    )
    (asserts! (> prediction-amount u0) ERR-INVALID-PREDICTION-AMOUNT)
    (asserts! (get is-prediction-open prediction) ERR-PREDICTION-CLOSED)
    (asserts! (>= (len (get revenue-ranges prediction)) chosen-range) ERR-INVALID-RANGE)
    (try! (stx-transfer? prediction-amount tx-sender (as-contract tx-sender)))
    (map-set user-predictions
      { prediction-id: prediction-id, predictor: tx-sender }
      { chosen-range: chosen-range, predicted-amount: prediction-amount }
    )
    (map-set predictions
      { prediction-id: prediction-id }
      (merge prediction { total-predicted-amount: (+ (get total-predicted-amount prediction) prediction-amount) })
    )
    (ok true)
  )
)

(define-public (cancel-prediction (prediction-id uint))
  (let
    (
      (prediction (unwrap! (get-prediction prediction-id) ERR-DOES-NOT-EXIST))
    )
    (asserts! (is-eq (get creator prediction) tx-sender) ERR-UNAUTHORIZED)
    (asserts! (get is-prediction-open prediction) ERR-PREDICTION-CLOSED)
    (asserts! (< block-height (get prediction-close-height prediction)) ERR-PREDICTION-NOT-CANCELABLE)
    (map-set predictions
      { prediction-id: prediction-id }
      (merge prediction { is-prediction-open: false })
    )
    (process-refund prediction-id)
  )
)

(define-public (settle-prediction (prediction-id uint) (winning-ranges (list 5 uint)))
  (let
    (
      (prediction (unwrap! (get-prediction prediction-id) ERR-DOES-NOT-EXIST))
    )
    (asserts! (is-eq contract-owner tx-sender) ERR-UNAUTHORIZED)
    (asserts! (get is-prediction-open prediction) ERR-PREDICTION-CLOSED)
    (asserts! (is-eq (len (get correct-ranges prediction)) u0) ERR-ALREADY-SETTLED)
    (asserts! (> (len winning-ranges) u0) ERR-NO-CORRECT-PREDICTIONS)
    (asserts! (<= (len winning-ranges) u5) ERR-TOO-MANY-OUTCOMES)
    (asserts! (validate-ranges-helper winning-ranges (len (get revenue-ranges prediction))) ERR-INVALID-OUTCOME)
    (map-set predictions
      { prediction-id: prediction-id }
      (merge prediction 
        { 
          is-prediction-open: false,
          correct-ranges: winning-ranges
        }
      )
    )
    (ok true)
  )
)

(define-public (claim-reward (prediction-id uint))
  (let
    (
      (prediction (unwrap! (get-prediction prediction-id) ERR-DOES-NOT-EXIST))
      (user-pred (unwrap! (get-user-prediction prediction-id tx-sender) ERR-DOES-NOT-EXIST))
      (correct-range-ids (get correct-ranges prediction))
    )
    (asserts! (is-some (index-of correct-range-ids (get chosen-range user-pred))) ERR-NOT-CORRECT)
    (let
      (
        (reward (calculate-reward prediction user-pred correct-range-ids))
      )
      (try! (as-contract (stx-transfer? reward tx-sender tx-sender)))
      (map-delete user-predictions { prediction-id: prediction-id, predictor: tx-sender })
      (ok reward)
    )
  )
)

;; Contract initialization
(begin
  (var-set next-prediction-id u0)
)

;; Export the Component function (required for v0)
(define-public (Component)
  (ok true))