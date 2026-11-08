; Compact equivalent from the README's Compact equivalent section.
(define-fun compact-r ((d Int) (L Int)) Int
  (mod (- (+ 285 d) (ite (and (= L 1) (> d 262)) 1 0)) 365))
(define-fun compact-leap-day ((d Int) (L Int)) Bool
  (and (= L 1) (= d 262)))
(define-fun compact-month ((d Int) (L Int)) Int
  (let ((r (compact-r d L)))
    (ite (compact-leap-day d L) 2
      (+ (div (ite (< r 363) r 363) 91) 1))))
(define-fun compact-day ((d Int) (L Int)) Int
  (let ((r (compact-r d L)))
    (ite (compact-leap-day d L) 91
      (+ (mod r 91) (ite (= r 364) 91 0)))))
(define-fun compact-year ((y Int) (M Int) (D Int) (L Int)) Int
  (- y 2024
    (ite (or (< M 3) (and (= M 3) (< D (- 21 L)))) 1 0)))
