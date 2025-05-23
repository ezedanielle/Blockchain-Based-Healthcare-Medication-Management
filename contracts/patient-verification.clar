;; Patient Verification Contract
;; This contract securely manages patient identities

(define-data-var admin principal tx-sender)

;; Map of registered patients
;; Note: In a real system, we would use more secure methods to store patient data
;; and implement proper access controls
(define-map patients
  { patient-id: (string-utf8 64) }
  {
    principal: principal,
    name-hash: (buff 32), ;; Store hash of name for privacy
    dob-hash: (buff 32),  ;; Store hash of date of birth for privacy
    is-active: bool
  }
)

;; Map of authorized access to patient data
(define-map patient-access
  {
    patient-id: (string-utf8 64),
    accessor: principal
  }
  {
    can-read: bool,
    can-write: bool,
    expiration: uint
  }
)

;; Initialize contract
(define-public (initialize)
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok true)
  )
)

;; Register a new patient (can only be done by admin or authorized healthcare provider)
(define-public (register-patient
    (patient-id (string-utf8 64))
    (name-hash (buff 32))
    (dob-hash (buff 32)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (map-set patients
      { patient-id: patient-id }
      {
        principal: tx-sender,
        name-hash: name-hash,
        dob-hash: dob-hash,
        is-active: true
      }
    )
    (ok true)
  )
)

;; Check if a patient is registered
(define-read-only (is-patient-registered (patient-id (string-utf8 64)))
  (let ((patient (map-get? patients { patient-id: patient-id })))
    (if (is-some patient)
      (get is-active (unwrap-panic patient))
      false
    )
  )
)

;; Grant access to patient data
(define-public (grant-access
    (patient-id (string-utf8 64))
    (accessor principal)
    (can-read bool)
    (can-write bool)
    (expiration uint))
  (begin
    ;; Only the patient or admin can grant access
    (let ((patient (map-get? patients { patient-id: patient-id })))
      (asserts! (is-some patient) (err u404))
      (asserts! (or
                  (is-eq tx-sender (var-get admin))
                  (is-eq tx-sender (get principal (unwrap-panic patient)))
                )
                (err u403))
      (map-set patient-access
        {
          patient-id: patient-id,
          accessor: accessor
        }
        {
          can-read: can-read,
          can-write: can-write,
          expiration: expiration
        }
      )
      (ok true)
    )
  )
)

;; Check if a principal has access to patient data
(define-read-only (has-access
    (patient-id (string-utf8 64))
    (accessor principal))
  (let ((access (map-get? patient-access { patient-id: patient-id, accessor: accessor })))
    (if (is-some access)
      (let ((access-data (unwrap-panic access)))
        (if (> (get expiration access-data) block-height)
          (get can-read access-data)
          false
        )
      )
      false
    )
  )
)

;; Revoke access to patient data
(define-public (revoke-access
    (patient-id (string-utf8 64))
    (accessor principal))
  (begin
    ;; Only the patient or admin can revoke access
    (let ((patient (map-get? patients { patient-id: patient-id })))
      (asserts! (is-some patient) (err u404))
      (asserts! (or
                  (is-eq tx-sender (var-get admin))
                  (is-eq tx-sender (get principal (unwrap-panic patient)))
                )
                (err u403))
      (map-delete patient-access
        {
          patient-id: patient-id,
          accessor: accessor
        }
      )
      (ok true)
    )
  )
)

;; Deactivate a patient
(define-public (deactivate-patient (patient-id (string-utf8 64)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (let ((patient (map-get? patients { patient-id: patient-id })))
      (asserts! (is-some patient) (err u404))
      (map-set patients
        { patient-id: patient-id }
        (merge (unwrap-panic patient) { is-active: false })
      )
      (ok true)
    )
  )
)
