(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-insufficient-balance (err u103))
(define-constant err-invalid-amount (err u104))
(define-constant err-unauthorized (err u105))

(define-data-var min-commission-rate uint u50)
(define-data-var max-commission-rate uint u2000)
(define-data-var platform-fee-rate uint u100)
(define-data-var total-affiliates uint u0)
(define-data-var total-referrals uint u0)

(define-map affiliates
  { affiliate: principal }
  {
    commission-rate: uint,
    total-referrals: uint,
    total-earnings: uint,
    active: bool,
    joined-at: uint
  }
)

(define-map merchants
  { merchant: principal }
  {
    active: bool,
    total-sales: uint,
    total-commissions-paid: uint,
    joined-at: uint
  }
)

(define-map referrals
  { referral-id: uint }
  {
    affiliate: principal,
    merchant: principal,
    customer: principal,
    sale-amount: uint,
    commission-amount: uint,
    status: (string-ascii 10),
    created-at: uint,
    completed-at: (optional uint)
  }
)

(define-map affiliate-earnings
  { affiliate: principal, merchant: principal }
  { pending-balance: uint, total-earned: uint }
)

(define-data-var next-referral-id uint u1)

(define-read-only (get-affiliate (affiliate principal))
  (map-get? affiliates { affiliate: affiliate })
)

(define-read-only (get-merchant (merchant principal))
  (map-get? merchants { merchant: merchant })
)

(define-read-only (get-referral (referral-id uint))
  (map-get? referrals { referral-id: referral-id })
)

(define-read-only (get-affiliate-earnings (affiliate principal) (merchant principal))
  (default-to
    { pending-balance: u0, total-earned: u0 }
    (map-get? affiliate-earnings { affiliate: affiliate, merchant: merchant })
  )
)

(define-read-only (calculate-commission (sale-amount uint) (commission-rate uint))
  (/ (* sale-amount commission-rate) u10000)
)

(define-read-only (calculate-platform-fee (commission-amount uint))
  (/ (* commission-amount (var-get platform-fee-rate)) u10000)
)

(define-read-only (get-contract-stats)
  {
    total-affiliates: (var-get total-affiliates),
    total-referrals: (var-get total-referrals),
    min-commission-rate: (var-get min-commission-rate),
    max-commission-rate: (var-get max-commission-rate),
    platform-fee-rate: (var-get platform-fee-rate)
  }
)

(define-public (register-affiliate (commission-rate uint))
  (let
    (
      (affiliate tx-sender)
      (current-block stacks-block-height)
    )
    (asserts! (is-none (map-get? affiliates { affiliate: affiliate })) err-already-exists)
    (asserts! (>= commission-rate (var-get min-commission-rate)) err-invalid-amount)
    (asserts! (<= commission-rate (var-get max-commission-rate)) err-invalid-amount)
    
    (map-set affiliates
      { affiliate: affiliate }
      {
        commission-rate: commission-rate,
        total-referrals: u0,
        total-earnings: u0,
        active: true,
        joined-at: current-block
      }
    )
    (var-set total-affiliates (+ (var-get total-affiliates) u1))
    (ok affiliate)
  )
)

(define-public (register-merchant)
  (let
    (
      (merchant tx-sender)
      (current-block stacks-block-height)
    )
    (asserts! (is-none (map-get? merchants { merchant: merchant })) err-already-exists)
    
    (map-set merchants
      { merchant: merchant }
      {
        active: true,
        total-sales: u0,
        total-commissions-paid: u0,
        joined-at: current-block
      }
    )
    (ok merchant)
  )
)

(define-public (create-referral (affiliate principal) (customer principal) (sale-amount uint))
  (let
    (
      (merchant tx-sender)
      (referral-id (var-get next-referral-id))
      (current-block stacks-block-height)
      (affiliate-data (unwrap! (map-get? affiliates { affiliate: affiliate }) err-not-found))
      (merchant-data (unwrap! (map-get? merchants { merchant: merchant }) err-not-found))
      (commission-amount (calculate-commission sale-amount (get commission-rate affiliate-data)))
    )
    (asserts! (> sale-amount u0) err-invalid-amount)
    (asserts! (get active affiliate-data) err-unauthorized)
    (asserts! (get active merchant-data) err-unauthorized)
    
    (map-set referrals
      { referral-id: referral-id }
      {
        affiliate: affiliate,
        merchant: merchant,
        customer: customer,
        sale-amount: sale-amount,
        commission-amount: commission-amount,
        status: "pending",
        created-at: current-block,
        completed-at: none
      }
    )
    
    (var-set next-referral-id (+ referral-id u1))
    (var-set total-referrals (+ (var-get total-referrals) u1))
    (ok referral-id)
  )
)

(define-public (complete-referral (referral-id uint))
  (let
    (
      (referral-data (unwrap! (map-get? referrals { referral-id: referral-id }) err-not-found))
      (merchant (get merchant referral-data))
      (affiliate (get affiliate referral-data))
      (commission-amount (get commission-amount referral-data))
      (current-block stacks-block-height)
      (current-earnings (get-affiliate-earnings affiliate merchant))
      (affiliate-data (unwrap! (map-get? affiliates { affiliate: affiliate }) err-not-found))
      (merchant-data (unwrap! (map-get? merchants { merchant: merchant }) err-not-found))
    )
    (asserts! (is-eq tx-sender merchant) err-unauthorized)
    (asserts! (is-eq (get status referral-data) "pending") err-unauthorized)
    
    (map-set referrals
      { referral-id: referral-id }
      (merge referral-data { status: "completed", completed-at: (some current-block) })
    )
    
    (map-set affiliate-earnings
      { affiliate: affiliate, merchant: merchant }
      {
        pending-balance: (+ (get pending-balance current-earnings) commission-amount),
        total-earned: (+ (get total-earned current-earnings) commission-amount)
      }
    )
    
    (map-set affiliates
      { affiliate: affiliate }
      (merge affiliate-data {
        total-referrals: (+ (get total-referrals affiliate-data) u1),
        total-earnings: (+ (get total-earnings affiliate-data) commission-amount)
      })
    )
    
    (map-set merchants
      { merchant: merchant }
      (merge merchant-data {
        total-sales: (+ (get total-sales merchant-data) (get sale-amount referral-data)),
        total-commissions-paid: (+ (get total-commissions-paid merchant-data) commission-amount)
      })
    )
    
    (ok true)
  )
)

(define-public (withdraw-earnings (merchant principal))
  (let
    (
      (affiliate tx-sender)
      (current-earnings (get-affiliate-earnings affiliate merchant))
      (pending-balance (get pending-balance current-earnings))
      (platform-fee (calculate-platform-fee pending-balance))
      (net-amount (- pending-balance platform-fee))
    )
    (asserts! (> pending-balance u0) err-insufficient-balance)
    
    (map-set affiliate-earnings
      { affiliate: affiliate, merchant: merchant }
      (merge current-earnings { pending-balance: u0 })
    )
    
    (try! (stx-transfer? net-amount contract-owner affiliate))
    (if (> platform-fee u0)
      (try! (stx-transfer? platform-fee contract-owner contract-owner))
      true
    )
    
    (ok net-amount)
  )
)

(define-public (set-commission-rates (min-rate uint) (max-rate uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (< min-rate max-rate) err-invalid-amount)
    (var-set min-commission-rate min-rate)
    (var-set max-commission-rate max-rate)
    (ok true)
  )
)

(define-public (set-platform-fee-rate (fee-rate uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= fee-rate u1000) err-invalid-amount)
    (var-set platform-fee-rate fee-rate)
    (ok true)
  )
)

(define-public (toggle-affiliate-status (affiliate principal))
  (let
    (
      (affiliate-data (unwrap! (map-get? affiliates { affiliate: affiliate }) err-not-found))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set affiliates
      { affiliate: affiliate }
      (merge affiliate-data { active: (not (get active affiliate-data)) })
    )
    (ok (not (get active affiliate-data)))
  )
)
