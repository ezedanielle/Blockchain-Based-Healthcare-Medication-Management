;; Prescriber Verification Contract
;; This contract validates authorized healthcare providers

(define-data-var admin principal tx-sender)

;; Map of authorized prescribers
(define-map prescribers
  { prescriber-id: (string-utf8 64) }
  {
    principal: principal,
    name: (string-utf8 256),
    license-number: (string-utf8 64),
    specialty: (string-utf8 64),
    is-active: bool
  }
)

;; Initialize contract
(define-public (initialize)
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok true)
  )
)

;; Register a new prescriber
(define-public (register-prescriber
    (prescriber-id (string-utf8 64))
    (name (string-utf8 256))
    (license-number (string-utf8 64))
    (specialty (string-utf8 64)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (map-set prescribers
      { prescriber-id: prescriber-id }
      {
        principal: tx-sender,
        name: name,
        license-number: license-number,
        specialty: specialty,
        is-active: true
      }
    )
    (ok true)
  )
)

;; Check if a prescriber is authorized
(define-read-only (is-authorized-prescriber (prescriber-id (string-utf8 64)))
  (let ((prescriber (map-get? prescribers { prescriber-id: prescriber-id })))
    (if (is-some prescriber)
      (get is-active (unwrap-panic prescriber))
      false
    )
  )
)

;; Deactivate a prescriber
(define-public (deactivate-prescriber (prescriber-id (string-utf8 64)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (let ((prescriber (map-get? prescribers { prescriber-id: prescriber-id })))
      (asserts! (is-some prescriber) (err u404))
      (map-set prescribers
        { prescriber-id: prescriber-id }
        (merge (unwrap-panic prescriber) { is-active: false })
      )
      (ok true)
    )
  )
)

;; Reactivate a prescriber
(define-public (reactivate-prescriber (prescriber-id (string-utf8 64)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (let ((prescriber (map-get? prescribers { prescriber-id: prescriber-id })))
      (asserts! (is-some prescriber) (err u404))
      (map-set prescribers
        { prescriber-id: prescriber-id }
        (merge (unwrap-panic prescriber) { is-active: true })
      )
      (ok true)
    )
  )
)

;; Get prescriber details
(define-read-only (get-prescriber (prescriber-id (string-utf8 64)))
  (map-get? prescribers { prescriber-id: prescriber-id })
)
