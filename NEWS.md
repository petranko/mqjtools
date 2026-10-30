# mqjtools 0.1.0

First working skeleton.

## Added

* `fmt_p()`, `fmt_num()`, `fmt_est_ci()`, `fmt_pct()`, `fmt_est_ci_p()` for
  consistent numeric reporting.
* `describe_by_group()` for baseline ("Table 1") summaries with optional tests.
* `cox_tidy()` and `cox_univariable()` for Cox model tables.
* `read_any()`, `write_xlsx_pub()`, `write_tsv_pub()`, `ensure_dir()` for file
  input and output.
* `mqj_cache_dir()`, `mqj_fetch()`, `mqj_cache_list()`, `mqj_extdata()` as the
  layer for reference resources that are too large to bundle.
* `lab_ref_range()`, backed by the internal `lab_ref` table, as an example of
  shipping small constants in `R/sysdata.rda`.
* Bundled data: `demo_clinical`, `gene_panel`.

## Notes

* Heavy dependencies are in `Suggests`; the package installs on a bare R.
* All exported functions carry runnable, offline examples.
