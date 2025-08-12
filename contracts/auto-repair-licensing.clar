;; Auto Repair Shop Licensing Contract
;; Manages repair facility permits and technician certifications

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-SHOP-NOT-FOUND (err u101))
(define-constant ERR-INVALID-LICENSE (err u102))
(define-constant ERR-LICENSE-EXPIRED (err u103))
(define-constant ERR-TECHNICIAN-NOT-FOUND (err u104))
(define-constant ERR-INVALID-CERTIFICATION (err u105))
(define-constant ERR-SHOP-ALREADY-EXISTS (err u106))

;; Contract owner (regulatory authority)
(define-data-var contract-owner principal tx-sender)

;; Shop license data structure
(define-map shop-licenses
  { shop-id: uint }
  {
    owner: principal,
    shop-name: (string-ascii 100),
    address: (string-ascii 200),
    license-type: (string-ascii 50),
    issue-date: uint,
    expiry-date: uint,
    status: (string-ascii 20),
    fee-paid: uint
  }
)

;; Technician certification data structure
(define-map technician-certifications
  { technician-id: uint }
  {
    name: (string-ascii 100),
    shop-id: uint,
    certification-type: (string-ascii 50),
    issue-date: uint,
    expiry-date: uint,
    status: (string-ascii 20)
  }
)

;; Counters for IDs
(define-data-var next-shop-id uint u1)
(define-data-var next-technician-id uint u1)

;; License fees
(define-data-var basic-license-fee uint u1000000) ;; 1 STX in microSTX
(define-data-var premium-license-fee uint u2000000) ;; 2 STX in microSTX

;; Issue new shop license
(define-public (issue-shop-license
  (shop-name (string-ascii 100))
  (address (string-ascii 200))
  (license-type (string-ascii 50))
  (duration-blocks uint))
  (let
    (
      (shop-id (var-get next-shop-id))
      (current-block block-height)
      (expiry-block (+ current-block duration-blocks))
      (fee (if (is-eq license-type "premium")
             (var-get premium-license-fee)
             (var-get basic-license-fee)))
    )
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (asserts! (> (len shop-name) u0) ERR-INVALID-LICENSE)
    (asserts! (> duration-blocks u0) ERR-INVALID-LICENSE)

    ;; Store shop license
    (map-set shop-licenses
      { shop-id: shop-id }
      {
        owner: tx-sender,
        shop-name: shop-name,
        address: address,
        license-type: license-type,
        issue-date: current-block,
        expiry-date: expiry-block,
        status: "active",
        fee-paid: fee
      }
    )

    ;; Increment shop ID counter
    (var-set next-shop-id (+ shop-id u1))

    (ok shop-id)
  )
)

;; Certify technician
(define-public (certify-technician
  (name (string-ascii 100))
  (shop-id uint)
  (certification-type (string-ascii 50))
  (duration-blocks uint))
  (let
    (
      (technician-id (var-get next-technician-id))
      (current-block block-height)
      (expiry-block (+ current-block duration-blocks))
      (shop-data (map-get? shop-licenses { shop-id: shop-id }))
    )
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (asserts! (is-some shop-data) ERR-SHOP-NOT-FOUND)
    (asserts! (> (len name) u0) ERR-INVALID-CERTIFICATION)
    (asserts! (> duration-blocks u0) ERR-INVALID-CERTIFICATION)

    ;; Store technician certification
    (map-set technician-certifications
      { technician-id: technician-id }
      {
        name: name,
        shop-id: shop-id,
        certification-type: certification-type,
        issue-date: current-block,
        expiry-date: expiry-block,
        status: "active"
      }
    )

    ;; Increment technician ID counter
    (var-set next-technician-id (+ technician-id u1))

    (ok technician-id)
  )
)

;; Suspend shop license
(define-public (suspend-shop-license (shop-id uint))
  (let
    (
      (shop-data (map-get? shop-licenses { shop-id: shop-id }))
    )
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (asserts! (is-some shop-data) ERR-SHOP-NOT-FOUND)

    (map-set shop-licenses
      { shop-id: shop-id }
      (merge (unwrap-panic shop-data) { status: "suspended" })
    )

    (ok true)
  )
)

;; Renew shop license
(define-public (renew-shop-license (shop-id uint) (duration-blocks uint))
  (let
    (
      (shop-data (map-get? shop-licenses { shop-id: shop-id }))
      (current-block block-height)
      (new-expiry (+ current-block duration-blocks))
    )
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (asserts! (is-some shop-data) ERR-SHOP-NOT-FOUND)
    (asserts! (> duration-blocks u0) ERR-INVALID-LICENSE)

    (map-set shop-licenses
      { shop-id: shop-id }
      (merge (unwrap-panic shop-data)
        {
          expiry-date: new-expiry,
          status: "active"
        }
      )
    )

    (ok true)
  )
)

;; Check if shop license is valid
(define-read-only (is-shop-license-valid (shop-id uint))
  (match (map-get? shop-licenses { shop-id: shop-id })
    shop-data
      (and
        (is-eq (get status shop-data) "active")
        (> (get expiry-date shop-data) block-height)
      )
    false
  )
)

;; Get shop license details
(define-read-only (get-shop-license (shop-id uint))
  (map-get? shop-licenses { shop-id: shop-id })
)

;; Get technician certification details
(define-read-only (get-technician-certification (technician-id uint))
  (map-get? technician-certifications { technician-id: technician-id })
)

;; Check if technician certification is valid
(define-read-only (is-technician-certified (technician-id uint))
  (match (map-get? technician-certifications { technician-id: technician-id })
    cert-data
      (and
        (is-eq (get status cert-data) "active")
        (> (get expiry-date cert-data) block-height)
      )
    false
  )
)

;; Update license fees
(define-public (update-license-fees (basic-fee uint) (premium-fee uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (var-set basic-license-fee basic-fee)
    (var-set premium-license-fee premium-fee)
    (ok true)
  )
)

;; Get current license fees
(define-read-only (get-license-fees)
  {
    basic: (var-get basic-license-fee),
    premium: (var-get premium-license-fee)
  }
)
