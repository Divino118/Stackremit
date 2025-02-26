;; StackRemit - Decentralized Money Transfer Protocol

;; Constants
(define-constant contract-owner tx-sender)
(define-constant error-unauthorized (err u100))
(define-constant error-account-not-found (err u101))
(define-constant error-insufficient-balance (err u102))
(define-constant error-invalid-amount (err u103))
(define-constant error-transfer-failed (err u104))
(define-constant error-permission-denied (err u105))
(define-constant error-invalid-exchange-rate (err u106))
(define-constant error-account-exists (err u107))
(define-constant error-invalid-input (err u108))

;; Data Variables
(define-data-var exchange-rate uint u0)
(define-data-var fee-percentage uint u100) ;; 1% fee, represented in basis points

;; Data Maps
(define-map user-balances principal uint)
(define-map user-profiles 
  principal 
  { name: (string-ascii 50), 
    account-number: (string-ascii 20) })
(define-map rate-update-permissions principal bool)

;; Read-only Functions
(define-read-only (get-balance (user principal))
  (default-to u0 (map-get? user-balances user)))

(define-read-only (get-profile (user principal))
  (map-get? user-profiles user))

(define-read-only (get-exchange-rate)
  (ok (var-get exchange-rate)))

(define-read-only (can-update-rate (user principal))
  (default-to false (map-get? rate-update-permissions user)))

;; Private Functions
(define-private (validate-name (name-input (string-ascii 50)))
  (and (> (len name-input) u0) (<= (len name-input) u50)))

(define-private (validate-account-number (account-number (string-ascii 20)))
  (and (> (len account-number) u0) (<= (len account-number) u20)))

;; Public Functions
(define-public (register-user (name (string-ascii 50)) (account-number (string-ascii 20)))
  (begin
    (asserts! (is-none (get-profile tx-sender)) error-account-exists)
    (asserts! (validate-name name) error-invalid-input)
    (asserts! (validate-account-number account-number) error-invalid-input)
    (ok (map-set user-profiles tx-sender {name: name, account-number: account-number}))))

(define-public (deposit-funds (amount uint))
  (let ((current-balance (get-balance tx-sender)))
    (asserts! (> amount u0) error-invalid-amount)
    (ok (map-set user-balances tx-sender (+ current-balance amount)))))

(define-public (send-remittance (recipient principal) (amount uint))
  (let
    (
      (sender-balance (get-balance tx-sender))
      (fee-amount (/ (* amount (var-get fee-percentage)) u10000))
      (total-amount (+ amount fee-amount))
      (current-rate (var-get exchange-rate))
    )
    (asserts! (is-some (get-profile tx-sender)) error-account-not-found)
    (asserts! (is-some (get-profile recipient)) error-account-not-found)
    (asserts! (>= sender-balance total-amount) error-insufficient-balance)
    (asserts! (> current-rate u0) error-invalid-exchange-rate)
    (try! (stx-transfer? amount tx-sender recipient))
    (try! (stx-transfer? fee-amount tx-sender contract-owner))
    (map-set user-balances tx-sender (- sender-balance total-amount))
    (ok (/ (* amount current-rate) u100000000)))) ;; Return local currency amount, assuming 8 decimal places

(define-public (withdraw-funds (amount uint))
  (let ((user-balance (get-balance tx-sender)))
    (asserts! (>= user-balance amount) error-insufficient-balance)
    (try! (as-contract (stx-transfer? amount contract-owner tx-sender)))
    (ok (map-set user-balances tx-sender (- user-balance amount)))))

(define-public (set-exchange-rate (new-rate uint))
  (begin
    (asserts! (can-update-rate tx-sender) error-permission-denied)
    (asserts! (> new-rate u0) error-invalid-exchange-rate)
    (ok (var-set exchange-rate new-rate))))

;; Admin Functions
(define-public (update-fee-percentage (new-percentage uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) error-unauthorized)
    (asserts! (<= new-percentage u10000) error-invalid-amount) ;; Ensure fee does not exceed 100%
    (ok (var-set fee-percentage new-percentage))))

(define-public (grant-rate-update-permission (user principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) error-unauthorized)
    (asserts! (is-none (map-get? rate-update-permissions user)) error-invalid-input)
    (ok (map-set rate-update-permissions user true))))

(define-public (revoke-rate-update-permission (user principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) error-unauthorized)
    (asserts! (is-some (map-get? rate-update-permissions user)) error-invalid-input)
    (ok (map-delete rate-update-permissions user))))
