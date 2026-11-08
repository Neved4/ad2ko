; Further simplified equivalent from the README's Further simplification section.
(define-fun simplified-r ((d Int) (L Int)) Int (compact-r d L))
(define-fun simplified-e ((d Int) (L Int)) Int
  (+ (ite (= (simplified-r d L) 364) 1 0)
     (ite (and (= L 1) (= d 262)) 1 0)))
(define-fun simplified-month ((d Int) (L Int)) Int
  (+ 1
    (- (div (simplified-r d L) 91) (simplified-e d L))))
(define-fun simplified-day ((d Int) (L Int)) Int
  (- (simplified-r d L)
    (* 91 (- (simplified-month d L) 1))))
(define-fun simplified-year ((y Int) (d Int)) Int
  (- y 2024 (ite (< d 80) 1 0)))
