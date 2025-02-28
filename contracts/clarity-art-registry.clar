 ;; ========================================================
;; Clarity Art Registry
;; ========================================================

;; ========================================================
;; Global Settings
;; ========================================================
(define-constant ADMIN tx-sender)  ;; Admin privileges assigned to contract deployer

;; Response codes for error handling
(define-constant ERROR-ARTWORK-MISSING (err u301))           ;; Artwork not found in registry
(define-constant ERROR-ARTWORK-EXISTS (err u302))            ;; Artwork already exists in registry
(define-constant ERROR-INVALID-NAME (err u303))              ;; Name format doesn't meet requirements
(define-constant ERROR-INVALID-DIMENSIONS (err u304))        ;; Dimensions provided are out of range
(define-constant ERROR-PERMISSION-DENIED (err u305))         ;; User lacks required permissions
(define-constant ERROR-INVALID-USER (err u306))              ;; Target user is invalid for operation
(define-constant ERROR-ADMIN-ACTION (err u307))              ;; Action limited to admin account
(define-constant ERROR-ACCESS-DENIED (err u308))             ;; User lacks viewing/access privileges

;; ========================================================
;; Database Schema
;; ========================================================
;; Counter for total registered artworks
(define-data-var artwork-count uint u0)

;; Primary artwork database
(define-map artwork-registry
  { artwork-id: uint }  ;; Unique identifier for each artwork
  {
    name: (string-ascii 64),             ;; Artwork name/title
    artist: principal,                   ;; Artist's blockchain address
    dimensions: uint,                    ;; Artwork dimensions
    registration-block: uint,            ;; Block height at registration
    notes: (string-ascii 128),           ;; Additional information
    categories: (list 10 (string-ascii 32)) ;; Categorization labels
  }
)

;; Permissions database for artwork viewing
(define-map permission-registry
  { artwork-id: uint, viewer: principal }  ;; Artwork and viewer combination
  { can-view: bool }                       ;; Access permission status
)

;; ========================================================
;; Utility Functions
;; ========================================================
;; Verify artwork exists in registry
(define-private (artwork-registered? (artwork-id uint))
  (is-some (map-get? artwork-registry { artwork-id: artwork-id }))
)

;; Validate user is the creator of an artwork
(define-private (is-artwork-creator? (artwork-id uint) (artist principal))
  (match (map-get? artwork-registry { artwork-id: artwork-id })
    artwork-record (is-eq (get artist artwork-record) artist)
    false
  )
)

;; Get artwork dimensions
(define-private (get-artwork-dimensions (artwork-id uint))
  (default-to u0 
    (get dimensions 
      (map-get? artwork-registry { artwork-id: artwork-id })
    )
  )
)

;; Validate category format
(define-private (is-category-valid? (category (string-ascii 32)))
  (and 
    (> (len category) u0)     ;; Category must have at least one character
    (< (len category) u33)    ;; Category must be within size limits
  )
)

;; Validate all categories in a list
(define-private (are-categories-valid? (categories (list 10 (string-ascii 32))))
  (and
    (> (len categories) u0)                 ;; At least one category required
    (<= (len categories) u10)               ;; Maximum 10 categories allowed
    (is-eq (len (filter is-category-valid? categories)) (len categories))  ;; All categories must be valid
  )
)

;; Text validation helper
(define-private (validate-text-length (text (string-ascii 64)) (min-length uint) (max-length uint))
  (and 
    (>= (len text) min-length)
    (<= (len text) max-length)
  )
)

;; Dimension validation helper
(define-private (are-dimensions-valid? (dimensions uint))
  (and 
    (> dimensions u0)          ;; Must be positive
    (< dimensions u1000000000) ;; Must be below maximum threshold
  )
)

;; Generate new artwork ID
(define-private (generate-artwork-id)
  (let ((current-id (var-get artwork-count)))
    (var-set artwork-count (+ current-id u1))
    (ok current-id) ;; Return pre-increment value
  )
)

;; ========================================================
;; Registry Management Functions
;; ========================================================
;; Create new artwork entry
(define-public (register-artwork (name (string-ascii 64)) (dimensions uint) (notes (string-ascii 128)) (categories (list 10 (string-ascii 32))))
  (let
    (
      (new-id (+ (var-get artwork-count) u1))
    )
    ;; Input validation
    (asserts! (and (> (len name) u0) (< (len name) u65)) ERROR-INVALID-NAME)
    (asserts! (and (> dimensions u0) (< dimensions u1000000000)) ERROR-INVALID-DIMENSIONS)
    (asserts! (and (> (len notes) u0) (< (len notes) u129)) ERROR-INVALID-NAME)
    (asserts! (are-categories-valid? categories) ERROR-INVALID-NAME)

    ;; Create new artwork record
    (map-insert artwork-registry
      { artwork-id: new-id }
      {
        name: name,
        artist: tx-sender,
        dimensions: dimensions,
        registration-block: block-height,
        notes: notes,
        categories: categories
      }
    )

    ;; Set creator access permission
    (map-insert permission-registry
      { artwork-id: new-id, viewer: tx-sender }
      { can-view: true }
    )

    ;; Update counter
    (var-set artwork-count new-id)
    (ok new-id)
  )
)

;; ========================================================
;; Artwork Information Retrieval
;; ========================================================
;; Get artwork notes
(define-public (get-artwork-notes (artwork-id uint))
  (let
    (
      (artwork-record (unwrap! (map-get? artwork-registry { artwork-id: artwork-id }) ERROR-ARTWORK-MISSING))
    )
    (ok (get notes artwork-record))
  )
)


;; Get artwork registration time
(define-public (get-registration-time (artwork-id uint))
  (let
    (
      (artwork-record (unwrap! (map-get? artwork-registry { artwork-id: artwork-id }) ERROR-ARTWORK-MISSING))
    )
    (ok (get registration-block artwork-record))
  )
)

;; Get artwork name
(define-public (get-artwork-name (artwork-id uint))
  (let
    (
      (artwork-record (unwrap! (map-get? artwork-registry { artwork-id: artwork-id }) ERROR-ARTWORK-MISSING))
    )
    (ok (get name artwork-record))
  )
)

;; Get artwork categories
(define-public (get-artwork-categories (artwork-id uint))
  (let
    (
      (artwork-record (unwrap! (map-get? artwork-registry { artwork-id: artwork-id }) ERROR-ARTWORK-MISSING))
    )
    (ok (get categories artwork-record))
  )
)

;; Get artwork artist
(define-public (get-artwork-artist (artwork-id uint))
  (let
    (
      (artwork-record (unwrap! (map-get? artwork-registry { artwork-id: artwork-id }) ERROR-ARTWORK-MISSING))
    )
    (ok (get artist artwork-record))
  )
)

;; ========================================================
;; Artwork Validation Functions
;; ========================================================
;; Check if a user has viewing access
(define-public (check-viewer-access (artwork-id uint) (viewer principal))
  (let
    (
      (access-record (map-get? permission-registry { artwork-id: artwork-id, viewer: viewer }))
    )
    (ok (is-some access-record))
  )
)

;; Check category count
(define-public (get-category-count (artwork-id uint))
  (let
    (
      (artwork-record (unwrap! (map-get? artwork-registry { artwork-id: artwork-id }) ERROR-ARTWORK-MISSING))
    )
    (ok (len (get categories artwork-record)))
  )
)

;; Validate artwork name length
(define-public (validate-name (name (string-ascii 64)))
  (ok (and (> (len name) u0) (<= (len name) u64)))
)

;; Validate if artwork exists
(define-public (check-artwork-exists (artwork-id uint))
  (let
    (
      (exists (artwork-registered? artwork-id))
    )
    (asserts! exists ERROR-ARTWORK-MISSING)
    (ok exists)
  )
)

;; ========================================================
;; Artwork Management Functions
;; ========================================================
;; Transfer artwork ownership
(define-public (transfer-artwork (artwork-id uint) (new-artist principal))
  (let
    (
      (artwork-record (unwrap! (map-get? artwork-registry { artwork-id: artwork-id }) ERROR-ARTWORK-MISSING))
    )
    (asserts! (artwork-registered? artwork-id) ERROR-ARTWORK-MISSING)
    (asserts! (is-eq (get artist artwork-record) tx-sender) ERROR-PERMISSION-DENIED)

    ;; Update registry with new owner
    (map-set artwork-registry
      { artwork-id: artwork-id }
      (merge artwork-record { artist: new-artist })
    )
    (ok true)
  )
)

;; Remove viewer access
(define-public (remove-viewer-access (artwork-id uint))
  (begin
    (asserts! (artwork-registered? artwork-id) ERROR-ARTWORK-MISSING)
    (map-delete permission-registry { artwork-id: artwork-id, viewer: tx-sender })
    (ok true)
  )
)


;; Get full artwork details
(define-public (get-full-artwork-details (artwork-id uint))
  (let
    (
      (artwork-record (unwrap! (map-get? artwork-registry { artwork-id: artwork-id }) ERROR-ARTWORK-MISSING))
    )
    (ok artwork-record)
  )
)

;; Get total artworks count
(define-public (get-total-artworks)
  (ok (var-get artwork-count))
)

;; Check if user has viewing permission
(define-public (has-viewing-permission? (artwork-id uint) (viewer principal))
  (let
    (
      (access-record (unwrap! (map-get? permission-registry { artwork-id: artwork-id, viewer: viewer }) ERROR-ACCESS-DENIED))
    )
    (ok (get can-view access-record))
  )
)

;; ========================================================
;; Artwork Modification Functions
;; ========================================================
;; Update artwork details
(define-public (update-artwork (artwork-id uint) (new-name (string-ascii 64)) (new-dimensions uint) (new-notes (string-ascii 128)) (new-categories (list 10 (string-ascii 32))))
  (let
    (
      (artwork-record (unwrap! (map-get? artwork-registry { artwork-id: artwork-id }) ERROR-ARTWORK-MISSING))
    )
    ;; Validate inputs and permissions
    (asserts! (artwork-registered? artwork-id) ERROR-ARTWORK-MISSING)
    (asserts! (is-eq (get artist artwork-record) tx-sender) ERROR-PERMISSION-DENIED)
    (asserts! (and (> (len new-name) u0) (< (len new-name) u65)) ERROR-INVALID-NAME)
    (asserts! (and (> new-dimensions u0) (< new-dimensions u1000000000)) ERROR-INVALID-DIMENSIONS)
    (asserts! (and (> (len new-notes) u0) (< (len new-notes) u129)) ERROR-INVALID-NAME)
    (asserts! (are-categories-valid? new-categories) ERROR-INVALID-NAME)

    ;; Update artwork details
    (map-set artwork-registry
      { artwork-id: artwork-id }
      (merge artwork-record { 
        name: new-name, 
        dimensions: new-dimensions, 
        notes: new-notes, 
        categories: new-categories 
      })
    )
    (ok true)
  )
)

;; ========================================================
;; Validator Functions
;; ========================================================
;; Check if user is artwork creator
(define-public (is-user-creator (artwork-id uint) (user principal))
  (let
    (
      (artwork-record (unwrap! (map-get? artwork-registry { artwork-id: artwork-id }) ERROR-ARTWORK-MISSING))
    )
    (ok (is-eq (get artist artwork-record) user))
  )
)


;; Check if artwork dimensions are in range
(define-public (validate-dimensions-range (artwork-id uint) (min-dims uint) (max-dims uint))
  (let
    (
      (artwork-record (unwrap! (map-get? artwork-registry { artwork-id: artwork-id }) ERROR-ARTWORK-MISSING))
    )
    (ok (and (>= (get dimensions artwork-record) min-dims) (<= (get dimensions artwork-record) max-dims)))
  )
)

;; Validate dimensions input
(define-public (validate-artwork-dimensions (dimensions uint))
  (ok (and (> dimensions u0) (< dimensions u1000000000)))
)

;; ========================================================
;; Ownership Verification Functions
;; ========================================================
;; Check if sender is artwork creator
(define-public (verify-artwork-ownership (artwork-id uint))
  (let
    (
      (artwork-record (unwrap! (map-get? artwork-registry { artwork-id: artwork-id }) ERROR-ARTWORK-MISSING))
    )
    (ok (is-eq tx-sender (get artist artwork-record)))
  )
)

;; Check if empty gallery
(define-public (is-gallery-empty)
  (ok (is-eq (var-get artwork-count) u0))
)

;; ========================================================
;; Access Control Functions
;; ========================================================
;; Check if user has viewing permission
(define-public (check-user-viewing-permission (artwork-id uint) (viewer principal))
  (ok (is-some (map-get? permission-registry { artwork-id: artwork-id, viewer: viewer })))
)

;; Verify admin status
(define-public (verify-admin-status)
  (ok (is-eq tx-sender ADMIN))
)

;; ========================================================
;; Validation Helper Functions
;; ========================================================
;; Check if name is empty
(define-public (is-name-empty (name (string-ascii 64)))
  (ok (is-eq (len name) u0))
)

