;; Identity Provider Verification Contract
;; Validates credential issuers and manages their registration

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_PROVIDER_EXISTS (err u101))
(define-constant ERR_PROVIDER_NOT_FOUND (err u102))
(define-constant ERR_INVALID_PROVIDER (err u103))

;; Data structures
(define-map identity-providers
  { provider-id: uint }
  {
    name: (string-ascii 50),
    issuer-address: principal,
    verification-level: uint,
    is-active: bool,
    registration-block: uint
  }
)

(define-map provider-by-address
  { issuer-address: principal }
  { provider-id: uint }
)

(define-data-var next-provider-id uint u1)

;; Register a new identity provider
(define-public (register-provider (name (string-ascii 50)) (issuer-address principal) (verification-level uint))
  (let ((provider-id (var-get next-provider-id)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-none (map-get? provider-by-address { issuer-address: issuer-address })) ERR_PROVIDER_EXISTS)
    (asserts! (<= verification-level u5) ERR_INVALID_PROVIDER)

    (map-set identity-providers
      { provider-id: provider-id }
      {
        name: name,
        issuer-address: issuer-address,
        verification-level: verification-level,
        is-active: true,
        registration-block: block-height
      }
    )

    (map-set provider-by-address
      { issuer-address: issuer-address }
      { provider-id: provider-id }
    )

    (var-set next-provider-id (+ provider-id u1))
    (ok provider-id)
  )
)

;; Verify if an address is a registered provider
(define-read-only (is-verified-provider (issuer-address principal))
  (match (map-get? provider-by-address { issuer-address: issuer-address })
    provider-data
      (match (map-get? identity-providers { provider-id: (get provider-id provider-data) })
        provider-info (get is-active provider-info)
        false
      )
    false
  )
)

;; Get provider information
(define-read-only (get-provider-info (provider-id uint))
  (map-get? identity-providers { provider-id: provider-id })
)

;; Deactivate a provider
(define-public (deactivate-provider (provider-id uint))
  (let ((provider-info (unwrap! (map-get? identity-providers { provider-id: provider-id }) ERR_PROVIDER_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)

    (map-set identity-providers
      { provider-id: provider-id }
      (merge provider-info { is-active: false })
    )
    (ok true)
  )
)
