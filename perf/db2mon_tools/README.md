# db2mon tools

## Introduction

The db2mon reports provide extensive insights into the database activity for a specific point in time. Collecting multiple db2mon reports can aid analysis of changing patterns over time. This set of tools assists in collating the individual sections of the db2mon report into separate files, and converts the SQL output into CSV (suitable for import into a spreadsheet or analysis with `colStats`) and ORG (a plain text markup format which can be used with GNU Emacs for inspection, calculation and manipulation) files.

## Setup

To simplify the configuration of the `PATH` and `PERL5LIB` environment variables, examine and if needed correct the `DB2MONTOOLS_INSTALL_ROOT` in the `db2mon_tools/etc/profile` file.

e.g. if the db2-samples git repository was unpacked in `$HOME/db2-samples` using 
 
    cd $HOME
    git clone https://github.com/IBM/db2-samples.git 
 
then `db2mon_tools/etc/profile` should have the following directory setting.

    export DB2MONTOOLS_INSTALL_ROOT=$HOME/db2-samples/perf/db2mon_tools

This should be added to the appropriate shell initialization script - e.g.

- `~/.bashrc` for bash
- `~/.kshrc` for kssh.

## Utilities

There are four utilites provided in the `samples/perf/db2mon_tools/bin` directory:

- mon2csv
- extractSelects
- colStats
- runPerl

### mon2csv

This utility is an wrapper utility on top of `extractSelects` to simplify the creation of the db2mon reports. Typical usage for a set of db2mon reports with names like db2mon-1.out, db2mon-2.out, etc.

    mon2csv -prefix analysis/mydb db2mon*out

This creates the directory `analysis` and a set of new files starting with `mydb-` in that directory. Each file is named after the section of the db2mon report where it was found. For example, all the SQL reports from each db2mon report found under the heading 

    ================================================ 
     DB#THRUP: Throughput metrics at database level  
    ================================================ 

will be collated into the following two files with appropriate formatting:

    mydb-DB#THRUP_Throughput_metrics_at_database_level.csv
    mydb-DB#THRUP_Throughput_metrics_at_database_level.org

See `mon2csv --help` for more options.

### extractSelects

This utility can find and reprint the select statement(s) output in one or more files. See `extractSelects --help` for more details.

### colStats

Rather than export CSV files to a spreadsheet on another system, `colStat` can perform statistics, create charts and aggregate data in the CSV files created by `mon2csv` and other utilities. Check out `colStats --help` for the many options.

### runPerl

This is a perl bootstrap utility, which examines the script provided to the utility and tests the perl executables to determine a functional perl installation. It performs automatic and additional specific tests to ensure certain features and capabilities exist (such as 64-bit perl) before running the script with the "successful" perl executable. If no perl executable passes the tests, an error is printed to STDOUT.

The other scripts in this directory use this utility transparently when executed. `runPerl` must be found in the PATH environment variable or the `DB2MONTOOLS_INSTALL_ROOT` environment variable must be set to the directory

## Examples

### Basic usage

Create a set of db2mon reports in the current directory, based on all files matching the glob pattern `db2mon*out`.

    mon2csv db2mon*out

These will be prefixed with `db2mon-` automatically.

### Separate reports in a subdirectory 

Put reports into a `myreport` subdirectory (created automatically) with the filename prefix `db2mon`.

    mon2csv -prefix myreport/db2mon db2mon*out

### Remove empty columns from the output reports

Many columns in the output reports are entirely zeros (e.g. Column-organised table metrics for databases without column-organised tables, CF metrics for a non-pureScale database). Adding `-empty` removes these columns from the created output.

    mon2csv -prefix myreport/reduced -empty db2mon*out

These reports would be written into the `myreport` directory with the prefix `reduced-`.

Note: Removal of the columns includes the table column name as well. Knowing what is empty can sometimes be important to analysis (e.g. there are no Lob Direct Writes but you expected to see some).

