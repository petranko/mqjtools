# mqjtools

Personal toolkit for clinical and bioinformatics analysis: formatting helpers,
descriptive tables, Cox model tidying, publication-ready file output, and a
lightweight cache for reference resources too large to ship inside a package.

## Install

```r
# public repository
devtools::install_github("your-account/mqjtools")

# private repository: needs a GitHub PAT with repo scope
# (create one with usethis::create_github_token(), store with gitcreds::gitcreds_set())
devtools::install_github("your-account/mqjtools", auth_token = Sys.getenv("GITHUB_PAT"))
```

During development, load the source tree without installing:

```r
devtools::load_all("path/to/mqjtools")   # or open the .Rproj and press Ctrl+Shift+L
```

## Use

```r
library(mqjtools)

fmt_est_ci(1.47, 1.11, 1.94)              # "1.47 (1.11-1.94)" with an en dash
fmt_p(0.00004)                            # "<0.001"

describe_by_group(demo_clinical, c("age", "sex", "plt"),
                  by = "group", median_vars = "plt", p_value = TRUE)

cox_univariable(demo_clinical, "os_time", "os_status", c("age", "group"))

write_xlsx_pub(list(Table1 = head(iris)), "table1.xlsx")
```

## Where things live

| Path | Contents |
| --- | --- |
| `R/` | all source code; one file per topic |
| `data/` | exported data sets (`demo_clinical`, `gene_panel`) |
| `R/sysdata.rda` | internal lookup tables, loaded with the namespace |
| `data-raw/` | the scripts that regenerate `data/` and `sysdata.rda` |
| `inst/extdata/` | small plain-text reference files |
| `man/` | **generated** by `devtools::document()` -- never edit by hand |
| `tests/testthat/` | unit tests |
| `GUIDE.md` | the full build guide: conventions, pitfalls, data strategy |

## Adding a function

1. Put it in the matching `R/` file (or start a new one).
2. Write a roxygen block: `@title`-ish first line, `@param`, `@return`,
   `@examples`, `@export`, and `@family` for cross-links.
3. `devtools::document()` -- this rewrites `man/` and `NAMESPACE`.
4. `devtools::load_all()` then `?your_function` (F1 in RStudio).
5. Add a test, run `devtools::test()`.
6. `devtools::check()` before every push.

## Conventions

* Everything ASCII in `R/`; write `"\u2013"` rather than a literal en dash and
  avoid Chinese characters in code, comments and roxygen blocks.
* Heavy packages (`survival`, `readxl`, `openxlsx`, `ggplot2`, `data.table`)
  stay in `Suggests` and are guarded with `requireNamespace()`.
* No `setwd()`, no `library()` inside functions, no `T`/`F`, no `1:length(x)`.
* Functions do one thing; helpers shared by several files get a `utils-` prefix.

## Status

Version 0.1.0. See `NEWS.md`.
