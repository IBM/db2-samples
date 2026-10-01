[//]: # (Copyright Dr. Gerd Anders. All Rights Reserved.)
[//]: # (SPDX-License-Identifier: Apache-2.0)

# Rust Sample Code - Public Function Summary

Summary of all `pub fn` items found in the `.rs` files under
[`ibm/db2-samples/rust`](https://github.com/ibm/db2-samples/tree/master/rust).

The `rust/basic_demo` files (`main.rs`, `main_parameter_markers.rs`,
`main_sp_udf.rs`) contain only a private `fn main()` and expose no `pub fn`
items, so they are omitted below. `rust/library_demo/db2binmain/src/main.rs`
likewise has no `pub fn` items (its `run()`, `main()`, and
`DbConfig::from_env()` are all private).

## `rust/library_demo/db2libadmin/src/lib.rs`

| Function | Summary |
|---|---|
| `acquire_lock_file(path: &Path) -> Result<fs::File>` | Opens (creating if needed) an exclusive-instance lock file at `path`. Refuses to follow a pre-existing symlink at that path, re-verifies the opened handle is a regular file, and (on Unix) chmods it to `0600` before returning it. |
| `redact_dsn(dsn: &str) -> String` | Returns a log-safe copy of a DSN string. If the string looks like a keyword=value ODBC connection string, it masks the values of `PWD`, `PASSWORD`, `UID`, and `USER` keys so credentials can't leak into log output. |
| `connect<'env>(env: &'env Environment, db2_dsn: &str, db2_user: &str, db2_pwd: &str) -> Result<Connection<'env>>` | Opens a single DB2 connection on the given ODBC `Environment`, meant to be created once and reused by the caller rather than reconnecting for every operation. |
| `check_db2_instance_owner(expected_user: &str) -> Result<bool>` | Runs `ps -eo user=,comm=` and checks whether the running `db2sysc` process is owned by `expected_user`. Returns `Ok(true)` if it matches, `Ok(false)` if it doesn't (or no such process is found). |
| `check_for_table_status(conn: &Connection, tabschema: &str, tabname: &str, status: &mut i32) -> Result<()>` | Queries `syscat.tables` for the given table's status and writes a numeric code into `status`: `0` = normal, `-1` = set-integrity pending, `-2` = inoperative, `-3` = unknown. Validates that `tabschema`/`tabname` contain only safe characters before building the query. |
| `check_for_empty_table(conn: &Connection, tabschema: &str, tabname: &str, table_is_empty: &mut bool) -> Result<()>` | Runs `SELECT COUNT(*)` against the given table and sets `table_is_empty` to `true` if the count is zero. Validates `tabschema`/`tabname` characters first. |
| `check_if_udf_sp_exists(conn: &Connection, udf_sp_schema: &str, udf_sp_name: &str, is_udf: bool, udf_sp_exists: &mut bool) -> Result<()>` | Looks up `syscat.functions` (if `is_udf`) or `syscat.procedures` (otherwise) to determine whether the named UDF/stored procedure exists, and sets `udf_sp_exists` accordingly. |
| `check_if_table_exists(conn: &Connection, tabschema: &str, tabname: &str, table_exists: &mut bool) -> Result<()>` | Queries `syscat.tables` to check whether a table with the given schema/name exists, setting `table_exists` to `true` or `false`. |

## `rust/library_demo/db2libimpload/src/lib.rs`

| Function | Summary |
|---|---|
| `is_gzip(path: &str) -> io::Result<bool>` | Reads the first two bytes of the file at `path` and returns `true` if they match the gzip magic number (`0x1f 0x8b`). |
| `set_integrity(conn: &Connection, tabschema: &str, tabname: &str) -> Result<()>` | Checks `syscat.tables` for `status = 'C'` (set-integrity pending) on the given table, and if pending, runs `SET INTEGRITY FOR <schema>.<table> IMMEDIATE CHECKED`. Does nothing if the table isn't in that state. |
| `runstats(conn: &Connection, tabschema: &str, tabname: &str) -> Result<()>` | Checks `syscat.tables` for `status = 'N'` (normal) on the given table, and if so, runs `CALL ADMIN_CMD('RUNSTATS ON TABLE <schema>.<table> ON KEY COLUMNS')` to refresh statistics. Does nothing otherwise. |
| `is_well_formed_xml<R: BufRead>(reader: R) -> bool` | Streams `reader` through a `quick_xml::Reader` and returns `true` if at least one well-formed start/empty XML element is seen before EOF, without buffering the whole input in memory (useful for validating large decompressed XML streams, e.g. PDB data). |
| `SizeLimitedReader::new(inner: R, limit: u64) -> Self` | Constructs a `Read` wrapper around `inner` that errors out once more than `limit` bytes have been read, guarding against decompression-bomb style inputs instead of silently truncating. |

### Related public constants

- `MAX_GUNZIP_SIZE: u64 = 1 GiB` - cap used when decompressing a single gzip blob.
- `MAX_TGZ_SIZE: u64 = 1 GiB` - cap used when decompressing a `.tgz` stream.
