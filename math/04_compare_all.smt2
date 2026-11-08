; Run from this file: z3 math/04_compare_all.smt2
; Z3 includes the three independent formula-definition files below.
(set-logic QF_LIA)
(include "math/01_date_map.smt2")
(include "math/02_compact.smt2")
(include "math/03_simplified.smt2")
(declare-const d Int)
(declare-const L Int)
(declare-const M Int)
(declare-const D Int)
(declare-const y Int)

; Model every valid Gregorian month/day and tie d to its 1-based day of year.
(assert (or (= L 0) (= L 1)))
(assert (and (<= 1 M) (<= M 12)))
(define-fun month-length ((m Int)) Int
  (ite (= m 2) (+ 28 L)
    (ite (or (= m 4) (= m 6) (= m 9) (= m 11)) 30 31)))
(assert (and (<= 1 D) (<= D (month-length M))))
(define-fun days-before-month ((m Int)) Int
  (ite (= m 1) 0
    (ite (= m 2) 31
      (ite (= m 3) (+ 59 L)
        (ite (= m 4) (+ 90 L)
          (ite (= m 5) (+ 120 L)
            (ite (= m 6) (+ 151 L)
              (ite (= m 7) (+ 181 L)
                (ite (= m 8) (+ 212 L)
                  (ite (= m 9) (+ 243 L)
                    (ite (= m 10) (+ 273 L)
                      (ite (= m 11) (+ 304 L) (+ 334 L)))))))))))))
(assert (= d (+ (days-before-month M) D)))

; Ask for counterexamples to each equivalence. All results should be unsat.
(echo "Date map formula vs compact formula")
(push)
(assert (or (distinct (date-map-month d L) (compact-month d L))
            (distinct (date-map-day d L) (compact-day d L))
            (distinct (date-map-year y M D L) (compact-year y M D L))))
(check-sat)
(pop)

(echo "Date map formula vs simplified formula")
(push)
(assert (or (distinct (date-map-month d L) (simplified-month d L))
            (distinct (date-map-day d L) (simplified-day d L))
            (distinct (date-map-year y M D L) (simplified-year y d))))
(check-sat)
(pop)

(echo "Compact formula vs simplified formula")
(push)
(assert (or (distinct (compact-month d L) (simplified-month d L))
            (distinct (compact-day d L) (simplified-day d L))
            (distinct (compact-year y M D L) (simplified-year y d))))
(check-sat)
(pop)
