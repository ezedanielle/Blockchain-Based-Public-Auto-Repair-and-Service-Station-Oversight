;; Consumer Protection Compliance Contract
;; Ensures fair pricing and prevents fraudulent repair practices

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u500))
(define-constant ERR-INVALID-COMPLAINT (err u501))
(define-constant ERR-COMPLAINT-NOT-FOUND (err u502))
(define-constant ERR-INVALID-RATING (err u503))
(define-constant ERR-SHOP-NOT-FOUND (err u504))
(define-constant ERR-INVALID-PRICING-DATA (err u505))
(define-constant ERR-FRAUD-ALERT-EXISTS (err u506))

;; Contract owner (consumer protection authority)
(define-data-var contract-owner principal tx-sender)

;; Customer complaints
(define-map customer-complaints
  { complaint-id: uint }
  {
    shop-id: uint,
    customer-address: principal,
    complaint-type: (string-ascii 50),
    complaint-description: (string-ascii 300),
    complaint-date: uint,
    severity: (string-ascii 20),
    status: (string-ascii 20),
    resolution-date: (optional uint),
    resolution-description: (optional (string-ascii 200))
  }
)

;; Shop ratings and reviews
(define-map shop-ratings
  { rating-id: uint }
  {
    shop-id: uint,
    customer-address: principal,
    rating: uint,
    review-text: (string-ascii 200),
    review-date: uint,
    verified-customer: bool
  }
)

;; Pricing transparency records
(define-map pricing-records
  { record-id: uint }
  {
    shop-id: uint,
    service-type: (string-ascii 100),
    quoted-price: uint,
    final-price: uint,
    price-difference: uint,
    justification: (string-ascii 200),
    customer-approved: bool,
    record-date: uint
  }
)

;; Fraud alerts
(define-map fraud-alerts
  { alert-id: uint }
  {
    shop-id: uint,
    alert-type: (string-ascii 50),
    alert-description: (string-ascii 300),
    alert-date: uint,
    severity: (string-ascii 20),
    investigated: bool,
    investigation-result: (optional (string-ascii 200))
  }
)

;; Shop compliance scores
(define-map compliance-scores
  { shop-id: uint }
  {
    overall-score: uint,
    pricing-score: uint,
    service-score: uint,
    complaint-score: uint,
    last-updated: uint,
    compliance-level: (string-ascii 20)
  }
)

;; Counters
(define-data-var next-complaint-id uint u1)
(define-data-var next-rating-id uint u1)
(define-data-var next-record-id uint u1)
(define-data-var next-alert-id uint u1)

;; Pricing variance thresholds
(define-data-var max-price-variance uint u20) ;; 20% maximum variance

;; Submit customer complaint
(define-public (submit-complaint
  (shop-id uint)
  (complaint-type (string-ascii 50))
  (complaint-description (string-ascii 300))
  (severity (string-ascii 20)))
  (let
    (
      (complaint-id (var-get next-complaint-id))
      (current-block block-height)
    )
    (asserts! (> (len complaint-type) u0) ERR-INVALID-COMPLAINT)
    (asserts! (> (len complaint-description) u0) ERR-INVALID-COMPLAINT)
    (asserts! (> shop-id u0) ERR-SHOP-NOT-FOUND)

    ;; Store complaint
    (map-set customer-complaints
      { complaint-id: complaint-id }
      {
        shop-id: shop-id,
        customer-address: tx-sender,
        complaint-type: complaint-type,
        complaint-description: complaint-description,
        complaint-date: current-block,
        severity: severity,
        status: "open",
        resolution-date: none,
        resolution-description: none
      }
    )

    ;; Increment complaint ID
    (var-set next-complaint-id (+ complaint-id u1))

    (ok complaint-id)
  )
)

;; Resolve customer complaint
(define-public (resolve-complaint
  (complaint-id uint)
  (resolution-description (string-ascii 200)))
  (let
    (
      (complaint-data (map-get? customer-complaints { complaint-id: complaint-id }))
      (current-block block-height)
    )
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (asserts! (is-some complaint-data) ERR-COMPLAINT-NOT-FOUND)
    (asserts! (> (len resolution-description) u0) ERR-INVALID-COMPLAINT)

    ;; Update complaint status
    (map-set customer-complaints
      { complaint-id: complaint-id }
      (merge (unwrap-panic complaint-data)
        {
          status: "resolved",
          resolution-date: (some current-block),
          resolution-description: (some resolution-description)
        }
      )
    )

    (ok true)
  )
)

;; Submit shop rating and review
(define-public (submit-rating
  (shop-id uint)
  (rating uint)
  (review-text (string-ascii 200)))
  (let
    (
      (rating-id (var-get next-rating-id))
      (current-block block-height)
    )
    (asserts! (> shop-id u0) ERR-SHOP-NOT-FOUND)
    (asserts! (and (>= rating u1) (<= rating u5)) ERR-INVALID-RATING)

    ;; Store rating
    (map-set shop-ratings
      { rating-id: rating-id }
      {
        shop-id: shop-id,
        customer-address: tx-sender,
        rating: rating,
        review-text: review-text,
        review-date: current-block,
        verified-customer: false ;; Would need verification logic
      }
    )

    ;; Increment rating ID
    (var-set next-rating-id (+ rating-id u1))

    (ok rating-id)
  )
)

;; Record pricing information
(define-public (record-pricing
  (shop-id uint)
  (service-type (string-ascii 100))
  (quoted-price uint)
  (final-price uint)
  (justification (string-ascii 200))
  (customer-approved bool))
  (let
    (
      (record-id (var-get next-record-id))
      (current-block block-height)
      (price-diff (if (> final-price quoted-price)
                     (- final-price quoted-price)
                     u0))
    )
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (asserts! (> shop-id u0) ERR-SHOP-NOT-FOUND)
    (asserts! (> quoted-price u0) ERR-INVALID-PRICING-DATA)
    (asserts! (> final-price u0) ERR-INVALID-PRICING-DATA)

    ;; Store pricing record
    (map-set pricing-records
      { record-id: record-id }
      {
        shop-id: shop-id,
        service-type: service-type,
        quoted-price: quoted-price,
        final-price: final-price,
        price-difference: price-diff,
        justification: justification,
        customer-approved: customer-approved,
        record-date: current-block
      }
    )

    ;; Increment record ID
    (var-set next-record-id (+ record-id u1))

    (ok record-id)
  )
)

;; Issue fraud alert
(define-public (issue-fraud-alert
  (shop-id uint)
  (alert-type (string-ascii 50))
  (alert-description (string-ascii 300))
  (severity (string-ascii 20)))
  (let
    (
      (alert-id (var-get next-alert-id))
      (current-block block-height)
    )
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (asserts! (> shop-id u0) ERR-SHOP-NOT-FOUND)
    (asserts! (> (len alert-type) u0) ERR-INVALID-COMPLAINT)

    ;; Store fraud alert
    (map-set fraud-alerts
      { alert-id: alert-id }
      {
        shop-id: shop-id,
        alert-type: alert-type,
        alert-description: alert-description,
        alert-date: current-block,
        severity: severity,
        investigated: false,
        investigation-result: none
      }
    )

    ;; Increment alert ID
    (var-set next-alert-id (+ alert-id u1))

    (ok alert-id)
  )
)

;; Update compliance score
(define-public (update-compliance-score
  (shop-id uint)
  (overall-score uint)
  (pricing-score uint)
  (service-score uint)
  (complaint-score uint))
  (let
    (
      (current-block block-height)
      (compliance-level (determine-compliance-level overall-score))
    )
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (asserts! (> shop-id u0) ERR-SHOP-NOT-FOUND)
    (asserts! (<= overall-score u100) ERR-INVALID-RATING)
    (asserts! (<= pricing-score u100) ERR-INVALID-RATING)
    (asserts! (<= service-score u100) ERR-INVALID-RATING)
    (asserts! (<= complaint-score u100) ERR-INVALID-RATING)

    ;; Store compliance score
    (map-set compliance-scores
      { shop-id: shop-id }
      {
        overall-score: overall-score,
        pricing-score: pricing-score,
        service-score: service-score,
        complaint-score: complaint-score,
        last-updated: current-block,
        compliance-level: compliance-level
      }
    )

    (ok true)
  )
)

;; Determine compliance level based on overall score
(define-read-only (determine-compliance-level (score uint))
  (if (>= score u90)
    "excellent"
    (if (>= score u75)
      "good"
      (if (>= score u60)
        "fair"
        "poor"
      )
    )
  )
)

;; Check pricing compliance
(define-read-only (check-pricing-compliance (quoted-price uint) (final-price uint))
  (let
    (
      (variance (if (> final-price quoted-price)
                  (/ (* (- final-price quoted-price) u100) quoted-price)
                  u0))
    )
    (<= variance (var-get max-price-variance))
  )
)

;; Get customer complaint
(define-read-only (get-complaint (complaint-id uint))
  (map-get? customer-complaints { complaint-id: complaint-id })
)

;; Get shop rating
(define-read-only (get-rating (rating-id uint))
  (map-get? shop-ratings { rating-id: rating-id })
)

;; Get pricing record
(define-read-only (get-pricing-record (record-id uint))
  (map-get? pricing-records { record-id: record-id })
)

;; Get fraud alert
(define-read-only (get-fraud-alert (alert-id uint))
  (map-get? fraud-alerts { alert-id: alert-id })
)

;; Get compliance score
(define-read-only (get-compliance-score (shop-id uint))
  (map-get? compliance-scores { shop-id: shop-id })
)

;; Update price variance threshold
(define-public (update-price-variance-threshold (new-threshold uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (asserts! (<= new-threshold u50) ERR-INVALID-PRICING-DATA) ;; Max 50% variance
    (var-set max-price-variance new-threshold)
    (ok true)
  )
)

;; Get current price variance threshold
(define-read-only (get-price-variance-threshold)
  (var-get max-price-variance)
)

;; Investigate fraud alert
(define-public (investigate-fraud-alert
  (alert-id uint)
  (investigation-result (string-ascii 200)))
  (let
    (
      (alert-data (map-get? fraud-alerts { alert-id: alert-id }))
    )
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (asserts! (is-some alert-data) ERR-COMPLAINT-NOT-FOUND)
    (asserts! (> (len investigation-result) u0) ERR-INVALID-COMPLAINT)

    ;; Update fraud alert
    (map-set fraud-alerts
      { alert-id: alert-id }
      (merge (unwrap-panic alert-data)
        {
          investigated: true,
          investigation-result: (some investigation-result)
        }
      )
    )

    (ok true)
  )
)
