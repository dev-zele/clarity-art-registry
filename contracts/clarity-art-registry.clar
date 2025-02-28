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
