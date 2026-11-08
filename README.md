# `ad2ko` - Gregorian to Korilo dates! ⌚️

Convert dates from Gregorian _"A.D."_ to Korilo date format.

###### Originally from: [`korilo_date.py`]

## What is this?

Korilo dates divide a 365-day cycle into four 91-day months, with one extra named day at the end. This converter finds where each Gregorian date falls in that cycle. Leap years need a small adjustment so the Korilo calendar stays aligned, and the Korilo year changes around March 20 or 21.

The aim of this project was to provide reference implementations in widely adopted programming languages, without requiring hardcoded entries like in the baseline authored version.

Finally, **performance was a primary driver**, we wanted to ensure that lightweight desktop widgets could display real-time date conversions with minimal latency and near-zero CPU or RAM overhead. By maximizing execution speed, we can allow async blocks to refresh instantly, keeping UI widgets responsive without system spikes or unnecessary resource use.

## Benchmarks

> [!NOTE]
> All benchmarks were conducted using [`hyperfine`](https://github.com/sharkdp/hyperfine), with flags: `-N -w 4 -r 8`.

Measured `1,107,050` dates at `tools/dates.txt` (`1970-01-01`-`5000-12-31`):

| Version |         Time | Peak memory |
| ------- | -----------: | ----------: |
| C       | **0.2466 s** | **1.7 MiB** |
| Awk     |     6.9442 s |    84.8 MiB |
| Python  |     1.9207 s |    16.5 MiB |

For a single date (`2024-03-20`):

| Version |         Time |  Peak memory |
| ------- | -----------: | -----------: |
| C       | **0.0019 s** |     1.64 MiB |
| Awk     |     0.0025 s | **1.56 MiB** |
| Python  |     0.0299 s |     16.3 MiB |

## Usage

These variants support standalone execution, reading from `stdin` and optionally format the output in [ISO 8601].

### AWK version

Standalone:
```console
$ ad2ko.awk
Printuno 64, 0
```

From standard input:
```console
$ echo $(date -u +"%Y-%m-%d") | ad2ko.awk
Printuno 64, 0
```

Date in [ISO 8601] format:
```console
$ awk -v iso_fmt=1 -f ad2ko.awk
0000-01-64
```

Read dates from a file, one per line:
```console
$ ad2ko.awk dates.txt
Printuno 64, 0
```

### C version

Compile with:
```
$ make build
```

Standalone:
```console
$ ad2ko
Printuno 64, 0
```

Standard input:
```console
$ echo $(date -u +"%Y-%m-%d") | ad2ko
Printuno 64, 0
```

Read one date per line from a file:
```console
$ ad2ko -f dates.txt
Printuno 64, 0
```

[ISO 8601] format:
```console
$ ad2ko -v iso_fmt=1
0000-01-64
```

## Date mapping

> [!IMPORTANT]
>
> **SMT proof.** Z3 _**checks satisfiability**_ of the negated output-tuple equality under valid-date constraints, `unsat` certifies equivalence over that domain. Z3 checked the compact and further simplified formulas against the original mapping rules in both C and AWK, including the year rule, for $d=1,\ldots,365$ in common years and $d=1,\ldots,366$ in leap years. Every counterexample query returned `unsat`. All Z3 queries can be found inside `math/`. Run them with `z3 math/<query>.smt2`.

Both the C and AWK versions compute the date from the Gregorian day of year, rather than storing a date-by-date lookup table. Let $d$ be the 1-based Gregorian day of year, $y$ the Gregorian year, and $L(y)$ equal 1 for a leap year and 0 otherwise. This first form follows the same steps as the code:

$$
q = (286 + d - 1) \bmod 365
$$

$$
(m,k) =
\begin{cases}
(2,91), & L(y)=1 \text{ and } d=262,\\
\operatorname{cycle}(q-1), & L(y)=1 \text{ and } d>262,\\
\operatorname{cycle}(q), & \text{otherwise}
\end{cases}
\qquad
\operatorname{cycle}(x) =
\begin{cases}
(4,91), & x=364,\\
(\lfloor x/91 \rfloor+1,\; x \bmod 91), & 0 \le x < 364
\end{cases}
$$

$$
y_K = y -
\begin{cases}
2025, & M<3 \text{ or } (M=3 \text{ and } D<B),\\
2024, & \text{otherwise}
\end{cases}
\qquad B=21-L(y)
$$

Here $M,D$ are the Gregorian month and day, and $y_K$ is the Korilo year. The leap-day exception and post-February index shift keep the cycle aligned across leap years. The year boundary is March 20 in leap years and March 21 otherwise.

### Compact equivalent

The same mapping can be written with one adjusted cycle index. Let $\mathbf{1}[P]$ equal 1 when $P$ is true and 0 otherwise. Then:

$$
r = (285 + d - L(y)\mathbf{1}[d>262]) \bmod 365
$$

$$
(m,k) =
\begin{cases}
(2,91), & L(y)=1 \text{ and } d=262,\\
(\lfloor \min(r,363)/91 \rfloor+1,\; (r \bmod 91)+91\mathbf{1}[r=364]), & \text{otherwise}
\end{cases}
$$

$$
y_K = y - 2024 - \mathbf{1}[M<3 \text{ or } (M=3 \text{ and } D<21-L(y))]
$$

The first simplification is $q=(286+d-1)\bmod365=(285+d)\bmod365$. After day 262 in a leap year, the code subtracts one from $q$. Combining that correction into $r$ gives the single index above. The explicit day-262 exception remains. For $r<364$, the month/day expression is the usual cycle calculation. At $r=364$, it yields $(4,91)$, the final named day. The year indicator combines the two year-offset cases by subtracting an extra 1 before the March boundary.

### Further simplification

The special cases can be folded into one correction. Reuse $r$ and the indicator function above, and define:

$$
\begin{aligned}
e &= \mathbf{1}[r=364]+L(y)\mathbf{1}[d=262],\\
m &= 1+\lfloor r/91\rfloor-e,\\
k &= r-91(m-1),\\
y_K &= y-2024-\mathbf{1}[d<80]
\end{aligned}
$$

Normally $e=0$, giving the usual quotient and remainder. At $r=364$, $e=1$ gives $(m,k)=(4,91)$. On leap-year day $d=262$, $r=182$ and $e=1$ gives $(2,91)$. These exceptions do not overlap. The year boundary is day $31+(28+L(y))+(21-L(y))=80$ in both cases, so the year rule reduces to $d<80$.

## License

This repository is licensed under the terms of the [MIT License].
   
See the [LICENSE](LICENSE) file for details.

[`korilo_date.py`]: https://github.com/lajtobw/desktop-distros-config/blob/main/shared/.mekadimo_date.py
[MIT License]: https://opensource.org/license/mit/
[ISO 8601]: https://en.wikipedia.org/wiki/ISO_8601
