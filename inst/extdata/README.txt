inst/extdata
============

Small, plain-text reference files that the package reads at run time belong
here. Reach them with:

    mqj_extdata("some_file.tsv")

which is a thin wrapper around system.file("extdata", ..., package = "mqjtools").

Rules of thumb
--------------
1. Keep this directory under a few megabytes in total. Everything here is
   downloaded again by every user, on every install, forever.
2. Prefer .tsv or .csv over .xlsx: text diffs in git, spreadsheets do not.
3. Do not put parsed R objects here. Use data/ for exported data and
   R/sysdata.rda for internal data.
4. Anything above roughly 5 MB, or anything whose licence forbids
   redistribution, goes to a remote archive and is pulled through mqj_fetch().

This file itself exists so that mqj_extdata("README.txt") has something to
find in the examples and tests.
