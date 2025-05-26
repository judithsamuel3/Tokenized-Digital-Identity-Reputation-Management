;; Feedback Aggregation Contract
;; Collects and aggregates reputation assessments

(define-constant ERR_UNAUTHORIZED (err u400))
(define-constant ERR_INVALID_RATING (err u401))
(define-constant ERR_SELF_RATING (err u402))
(define-constant ERR_DUPLICATE_FEEDBACK (err u403))

;; Data structures
(define-map user-feedback
  { user-id: principal, rater-id: principal }
  {
    rating: uint,
    comment: (string-ascii 200),
    timestamp: uint,
    interaction-context: (string-ascii 50)
  }
)

(define-map user-rating-summary
  { user-id: principal }
  {
    total-ratings: uint,
    sum-ratings: uint,
    average-rating: uint,
    last-updated: uint
  }
)

;; Submit feedback
(define-public (submit-feedback
  (user-id principal)
  (rating uint)
  (comment (string-ascii 200))
  (interaction-context (string-ascii 50))
)
  (begin
    (asserts! (not (is-eq tx-sender user-id)) ERR_SELF_RATING)
    (asserts! (and (>= rating u1) (<= rating u5)) ERR_INVALID_RATING)
    (asserts! (is-none (map-get? user-feedback { user-id: user-id, rater-id: tx-sender })) ERR_DUPLICATE_FEEDBACK)

    ;; Store feedback
    (map-set user-feedback
      { user-id: user-id, rater-id: tx-sender }
      {
        rating: rating,
        comment: comment,
        timestamp: block-height,
        interaction-context: interaction-context
      }
    )

    ;; Update rating summary
    (let (
      (current-summary (default-to
        { total-ratings: u0, sum-ratings: u0, average-rating: u0, last-updated: u0 }
        (map-get? user-rating-summary { user-id: user-id })
      ))
    )
      (let (
        (new-total (+ (get total-ratings current-summary) u1))
        (new-sum (+ (get sum-ratings current-summary) rating))
        (new-average (/ new-sum new-total))
      )
        (map-set user-rating-summary
          { user-id: user-id }
          {
            total-ratings: new-total,
            sum-ratings: new-sum,
            average-rating: new-average,
            last-updated: block-height
          }
        )
      )
    )

    (ok true)
  )
)

;; Get average rating for a user
(define-read-only (get-average-rating (user-id principal))
  (match (map-get? user-rating-summary { user-id: user-id })
    summary-data (ok (get average-rating summary-data))
    (ok u0)
  )
)

;; Get feedback details
(define-read-only (get-feedback (user-id principal) (rater-id principal))
  (map-get? user-feedback { user-id: user-id, rater-id: rater-id })
)

;; Get rating summary
(define-read-only (get-rating-summary (user-id principal))
  (map-get? user-rating-summary { user-id: user-id })
)
