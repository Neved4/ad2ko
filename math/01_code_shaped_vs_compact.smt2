; Check the code-shaped cycle mapping against the compact README formula.
(set-logic QF_LIA)
(declare-const d Int)
(declare-const leap Int)
(assert (or (= leap 0) (= leap 1)))
(assert (and (<= 1 d) (<= d (+ 365 leap))))
(define-fun q () Int (mod (+ 286 d -1) 365))
(define-fun after-leap-day () Bool (and (= leap 1) (> d 262)))
(define-fun leap-day () Bool (and (= leap 1) (= d 262)))
(define-fun c-index () Int (ite after-leap-day (mod (+ q 364) 365) q))
(define-fun awk-index () Int (ite after-leap-day (mod (- q 1) 365) q))
(define-fun c-month () Int
  (ite leap-day 2 (ite (= c-index 364) 4 (+ (div c-index 91) 1))))
(define-fun c-day () Int
  (ite leap-day 91 (ite (= c-index 364) 91 (mod c-index 91))))
(define-fun awk-month () Int
  (ite leap-day 2 (ite (= awk-index 364) 4 (+ (div awk-index 91) 1))))
(define-fun awk-day () Int
  (ite leap-day 91 (ite (= awk-index 364) 91 (mod awk-index 91))))
(define-fun r () Int (mod (- (+ 285 d) (ite (and (= leap 1) (> d 262)) 1 0)) 365))
(define-fun compact-month () Int
  (ite leap-day 2 (+ (div (ite (< r 363) r 363) 91) 1)))
(define-fun compact-day () Int
  (ite leap-day 91 (+ (mod r 91) (ite (= r 364) 91 0))))
(echo "C mapping vs compact formula")
(push)
(assert (or (not (= c-month compact-month)) (not (= c-day compact-day))))
(check-sat)
(pop)
(echo "AWK mapping vs compact formula")
(assert (or (not (= awk-month compact-month)) (not (= awk-day compact-day))))
(check-sat)
