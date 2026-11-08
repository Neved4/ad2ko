; Check the compact month/day mapping against the further-simplified form.
(set-logic QF_LIA)
(declare-const d Int)
(declare-const L Int)
(assert (or (= L 0) (= L 1)))
(assert (and (<= 1 d) (<= d (+ 365 L))))
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
(assert (or (not (= (compact-month d L) (simplified-month d L)))
           (not (= (compact-day d L) (simplified-day d L)))))
(check-sat)
