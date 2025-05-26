;; Interaction Tracking Contract
;; Records identity usage patterns and interactions

(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_INVALID_INTERACTION (err u201))
(define-constant ERR_INTERACTION_EXISTS (err u202))

;; Data structures
(define-map user-interactions
  { user-id: principal, interaction-id: uint }
  {
    interaction-type: (string-ascii 20),
    timestamp: uint,
    service-provider: principal,
    success: bool,
    metadata: (string-ascii 100)
  }
)

(define-map user-interaction-count
  { user-id: principal }
  { count: uint }
)

(define-data-var next-interaction-id uint u1)

;; Record a new interaction
(define-public (record-interaction
  (user-id principal)
  (interaction-type (string-ascii 20))
  (service-provider principal)
  (success bool)
  (metadata (string-ascii 100))
)
  (let ((interaction-id (var-get next-interaction-id)))
    (asserts! (or (is-eq tx-sender user-id) (is-eq tx-sender service-provider)) ERR_UNAUTHORIZED)

    (map-set user-interactions
      { user-id: user-id, interaction-id: interaction-id }
      {
        interaction-type: interaction-type,
        timestamp: block-height,
        service-provider: service-provider,
        success: success,
        metadata: metadata
      }
    )

    ;; Update interaction count
    (let ((current-count (default-to u0 (get count (map-get? user-interaction-count { user-id: user-id })))))
      (map-set user-interaction-count
        { user-id: user-id }
        { count: (+ current-count u1) }
      )
    )

    (var-set next-interaction-id (+ interaction-id u1))
    (ok interaction-id)
  )
)

;; Get user interaction count
(define-read-only (get-user-interaction-count (user-id principal))
  (default-to u0 (get count (map-get? user-interaction-count { user-id: user-id })))
)

;; Get specific interaction
(define-read-only (get-interaction (user-id principal) (interaction-id uint))
  (map-get? user-interactions { user-id: user-id, interaction-id: interaction-id })
)

;; Calculate success rate for a user
(define-read-only (calculate-success-rate (user-id principal))
  (let ((total-count (get-user-interaction-count user-id)))
    (if (is-eq total-count u0)
      u0
      ;; This is a simplified calculation - in practice, you'd iterate through interactions
      u75 ;; Placeholder: 75% success rate
    )
  )
)
