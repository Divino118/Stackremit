;; StackRemit - Secure Decentralized Money Transfer Protocol

;; Constants
(define-constant contract-administrator tx-sender)
(define-constant error-unauthorized (err u200))
(define-constant error-user-not-found (err u201))
(define-constant error-insufficient-balance (err u202))
(define-constant error-invalid-amount (err u203))
(define-constant error-transaction-failed (err u204))
(define-constant error-permission-denied (err u205))
(define-constant error-invalid-exchange-rate (err u206))
(define-constant error-user-already-exists (err u207))
(define-constant error-invalid-input-data (err u208))
(define-constant error-transfer-locked (err u209))

;; State Variables
(define-data-var exchange-rate uint u0)
(define-data-var transaction-fee-basis-points uint u150) ;; 1.5% charge, expressed in basis points
(define-data-var global-transfer-lock bool false) ;; New state variable for emergency lock functionality

;; Mappings
(define-map account-balances principal uint)
(define-map user-profiles 
  principal 
  { display-name: (string-ascii 55), 
    payment-identifier: (string-ascii 22) })
(define-map rate-administrators principal bool)

;; Read-only Queries
(define-read-only (get-balance (account principal))
  (default-to u0 (map-get? account-balances account)))

(define-read-only (get-user-profile (account principal))
  (map-get? user-profiles account))

(define-read-only (get-current-exchange-rate)
  (ok (var-get exchange-rate)))

(define-read-only (is-rate-administrator (account principal))
  (default-to false (map-get? rate-administrators account)))

(define-read-only (is-transfer-locked)
  (var-get global-transfer-lock))

;; Private Validation Methods
(define-private (validate-display-name (name (string-ascii 55)))
  (and (> (len name) u0) (<= (len name) u55)))

(define-private (validate-payment-identifier (identifier (string-ascii 22)))
  (and (> (len identifier) u0) (<= (len identifier) u22)))

;; Public Methods
(define-public (register-user (display-name (string-ascii 55)) (payment-identifier (string-ascii 22)))
  (begin
    (asserts! (is-none (get-user-profile tx-sender)) error-user-already-exists)
    (asserts! (validate-display-name display-name) error-invalid-input-data)
    (asserts! (validate-payment-identifier payment-identifier) error-invalid-input-data)
    (ok (map-set user-profiles tx-sender {display-name: display-name, payment-identifier: payment-identifier}))))

(define-public (deposit-funds (amount uint))
  (let ((current-balance (get-balance tx-sender)))
    (asserts! (> amount u0) error-invalid-amount)
    (ok (map-set account-balances tx-sender (+ current-balance amount)))))

(define-public (send-payment (recipient principal) (amount uint))
  (let
    (
      (sender-balance (get-balance tx-sender))
      (fee-amount (/ (* amount (var-get transaction-fee-basis-points)) u10000))
      (total-debit (+ amount fee-amount))
      (current-rate (var-get exchange-rate))
    )
    (asserts! (not (var-get global-transfer-lock)) error-transfer-locked)
    (asserts! (is-some (get-user-profile tx-sender)) error-user-not-found)
    (asserts! (is-some (get-user-profile recipient)) error-user-not-found)
    (asserts! (>= sender-balance total-debit) error-insufficient-balance)
    (asserts! (> current-rate u0) error-invalid-exchange-rate)
    (try! (stx-transfer? amount tx-sender recipient))
    (try! (stx-transfer? fee-amount tx-sender contract-administrator))
    (map-set account-balances tx-sender (- sender-balance total-debit))
    (ok (/ (* amount current-rate) u100000000)))) ;; Returns converted amount with assumed 8 decimals

(define-public (withdraw-funds (amount uint))
  (let ((user-balance (get-balance tx-sender)))
    (asserts! (>= user-balance amount) error-insufficient-balance)
    (try! (as-contract (stx-transfer? amount contract-administrator tx-sender)))
    (ok (map-set account-balances tx-sender (- user-balance amount)))))

(define-public (update-exchange-rate (new-rate uint))
  (begin
    (asserts! (is-rate-administrator tx-sender) error-permission-denied)
    (asserts! (> new-rate u0) error-invalid-exchange-rate)
    (ok (var-set exchange-rate new-rate))))

;; New functionality - Emergency transfer lock
(define-public (set-global-transfer-lock (lock-status bool))
  (begin
    (asserts! (is-eq tx-sender contract-administrator) error-unauthorized)
    (ok (var-set global-transfer-lock lock-status))))

;; Administrator Functions
(define-public (update-transaction-fee (new-fee-basis-points uint))
  (begin
    (asserts! (is-eq tx-sender contract-administrator) error-unauthorized)
    (asserts! (<= new-fee-basis-points u10000) error-invalid-amount) ;; Cap at 100%
    (ok (var-set transaction-fee-basis-points new-fee-basis-points))))

(define-public (add-rate-administrator (account principal))
  (begin
    (asserts! (is-eq tx-sender contract-administrator) error-unauthorized)
    (asserts! (is-none (map-get? rate-administrators account)) error-invalid-input-data)
    (ok (map-set rate-administrators account true))))

(define-public (remove-rate-administrator (account principal))
  (begin
    (asserts! (is-eq tx-sender contract-administrator) error-unauthorized)
    (asserts! (is-some (map-get? rate-administrators account)) error-invalid-input-data)
    (ok (map-delete rate-administrators account))))