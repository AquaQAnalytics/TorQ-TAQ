// define directories for qmerger and taqloader processes

\d .taq

hdbdir:hsym `$getenv[`KDBHDB]
mergedir:hsym `$getenv[`TORQTAQMERGED]
symdir:hsym `$getenv[`KDBHDB]
filedrop:hsym`$getenv[`TORQTAQFILEDROP]
tempdb:hsym `$getenv[`TORQTAQTEMPDB]

