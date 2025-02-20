;; Movie Box Office Prediction Market Contract 
;; Basic version with simple winner-takes-all predictions

;; Error Constants
(define-constant contract-owner tx-sender)
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-DOES-NOT-EXIST (err u102))
(define-constant ERR-PREDICTION-CLOSED (err u103))
(define-constant ERR-INSUFFICIENT-FUNDS (err u104))
(define-constant ERR-ALREADY-SETTLED (err u105))
(define-constant ERR-INVALID-RANGE-COUNT (err u108))
(define-constant ERR-INVALID-CLOSE-HEIGHT (err u109))
(define-constant ERR-INVALID-MOVIE-DETAILS (err u120))
(define-constant ERR-INVALID-PREDICTION-AMOUNT (err u121))

;; Data variables
(define-data-var next-prediction-id uint u0)

;; Define prediction structure
(define-map predictions
  { prediction-id: uint }
  {
    creator: principal,
    movie-details: (string-ascii 256),
    revenue-ranges: (list 10 (string-ascii 64)),
    total-predicted-amount: uint,
    is-prediction-open: bool,
    correct-range: uint,
    prediction-close-height: uint
  }
)

;; Define predictions structure
(define-map user-predictions
  { prediction-id: uint, predictor: principal }
  { chosen-range: uint, predicted-amount: uint }
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
(define-public (create-prediction (movie-details (string-ascii 256)) (revenue-ranges (list 10 (string-ascii 64))) (prediction-close-height uint))
  (let
    (
      (new-prediction-id (var-get next-prediction-id))
    )
    (asserts! (> (len movie-details) u0) ERR-INVALID-MOVIE-DETAILS)
    (asserts! (> (len revenue-ranges) u1) ERR-INVALID-RANGE-COUNT)
    (asserts! (> prediction-close-height block-height) ERR-INVALID-CLOSE-HEIGHT)
    (map-set predictions
      { prediction-id: new-prediction-id }
      {
        creator: tx-sender,
        movie-details: movie-details,
        revenue-ranges: revenue-ranges,
        total-predicted-amount: u0,
        is-prediction-open: true,
        correct-range: u0,
        prediction-close-height: prediction-close-height
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

(define-public (settle-prediction (prediction-id uint) (winning-range uint))
  (let
    (
      (prediction (unwrap! (get-prediction prediction-id) ERR-DOES-NOT-EXIST))
    )
    (asserts! (is-eq contract-owner tx-sender) ERR-UNAUTHORIZED)
    (asserts! (get is-prediction-open prediction) ERR-PREDICTION-CLOSED)
    (asserts! (is-eq (get correct-range prediction) u0) ERR-ALREADY-SETTLED)
    (map-set predictions
      { prediction-id: prediction-id }
      (merge prediction { is-prediction-open: false, correct-range: winning-range })
    )
    (ok true)
  )
)

(define-public (claim-reward (prediction-id uint))
  (let
    (
      (prediction (unwrap! (get-prediction prediction-id) ERR-DOES-NOT-EXIST))
      (user-pred (unwrap! (get-user-prediction prediction-id tx-sender) ERR-DOES-NOT-EXIST))
    )
    (asserts! (is-eq (get chosen-range user-pred) (get correct-range prediction)) ERR-UNAUTHORIZED)
    (try! (as-contract (stx-transfer? (get predicted-amount user-pred) tx-sender tx-sender)))
    (map-delete user-predictions { prediction-id: prediction-id, predictor: tx-sender })
    (ok true)
  )
)

;; Contract initialization
(begin
  (var-set next-prediction-id u0)
)

;; Export the Component function (required for v0)
(define-public (Component)
  (ok true))