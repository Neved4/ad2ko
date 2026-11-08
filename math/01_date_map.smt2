; Code-shaped mathematical mapping from the README's Date mapping section.
; Function arguments are the 1-based day of year d and leap indicator L.
(define-fun date-map-q ((d Int)) Int (mod (+ 286 d -1) 365))
(define-fun date-map-index ((d Int) (L Int)) Int
  (ite (and (= L 1) (> d 262)) (- (date-map-q d) 1) (date-map-q d)))
(define-fun date-map-month ((d Int) (L Int)) Int
  (ite (and (= L 1) (= d 262)) 2
    (ite (= (date-map-index d L) 364) 4
      (+ (div (date-map-index d L) 91) 1))))
(define-fun date-map-day ((d Int) (L Int)) Int
  (ite (and (= L 1) (= d 262)) 91
    (ite (= (date-map-index d L) 364) 91
      (mod (date-map-index d L) 91))))
(define-fun date-map-year ((y Int) (M Int) (D Int) (L Int)) Int
  (- y
    (ite (or (< M 3) (and (= M 3) (< D (- 21 L)))) 2025 2024)))
