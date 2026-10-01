/*
Copyright Dr. Gerd Anders. All Rights Reserved.

SPDX-License-Identifier: Apache-2.0
*/

use anyhow::{Context, Result};
// use std::collections::HashMap;
use std::fs;
use std::path::Path;
use std::process;
// use log::{debug, error, info, warn};

use odbc_api::{Connection, ConnectionOptions, Cursor, Environment, IntoParameter, Nullable};

/// Opens (creating if necessary) the exclusive-instance lock file at `path`,
/// guarding against a symlink pre-planted at this well-known, shared
/// temp-directory path: `File::create()` would otherwise silently follow
/// such a symlink and open/truncate whatever it points to. Shared by every
/// binary in this workspace that takes a single-instance lock, instead of
/// each one reimplementing (or forgetting) this guard.
pub fn acquire_lock_file(path: &Path) -> Result<fs::File> {
    // Refuse outright if something already at this path is a symlink,
    // rather than following it.
    if let Ok(meta) = fs::symlink_metadata(path) {
        if meta.file_type().is_symlink() {
            anyhow::bail!(
                "Refusing to use lock file '{}': existing entry is a symlink",
                path.display()
            );
        }
    }

    let file = fs::OpenOptions::new()
        .create(true)
        .write(true)
        .truncate(true)
        .open(path)
        .with_context(|| format!("Failed to open lock file '{}'", path.display()))?;

    // Re-check what we actually got a handle to: guards against a symlink
    // being swapped in during the tiny window between the check above and
    // the open() call -- if that happened, refuse to trust this handle.
    let opened_meta = file
        .metadata()
        .with_context(|| format!("Failed to stat open lock file handle '{}'", path.display()))?;
    if !opened_meta.is_file() {
        anyhow::bail!(
            "Refusing to use lock file '{}': resolved to something other than a regular file",
            path.display()
        );
    }

    // Restrict access to the lock file itself once we hold a valid handle
    // to a confirmed regular file (defense in depth on shared/multi-user
    // systems where /tmp or $TMPDIR may be world-writable).
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        file.set_permissions(fs::Permissions::from_mode(0o600))
            .with_context(|| {
                format!(
                    "Failed to set permissions on lock file '{}'",
                    path.display()
                )
            })?;
    }

    Ok(file)
}

/// Returns a version of `dsn` safe to pass to log::debug!/error messages.
/// Callers are expected to pass a plain named DSN, but if one ever passes a
/// full keyword=value ODBC connection string as the DSN argument instead,
/// this strips out any password/user fields so it can't leak credentials
/// into logs.
pub fn redact_dsn(dsn: &str) -> String {
    if !dsn.contains('=') {
        return dsn.to_string();
    }

    dsn.split(';')
        .map(|kv| match kv.split_once('=') {
            Some((key, _))
                if matches!(
                    key.trim().to_uppercase().as_str(),
                    "PWD" | "PASSWORD" | "UID" | "USER"
                ) =>
            {
                format!("{}=***", key.trim())
            }
            _ => kv.to_string(),
        })
        .collect::<Vec<_>>()
        .join(";")
}

/// Opens a single DB2 connection on `env`, meant to be created once per
/// caller (e.g. once at the start of a program's `run()`, or once per
/// worker thread) and then passed by reference into every db2libgen
/// function that needs it, instead of each function connecting from
/// scratch. Reusing one connection avoids paying a full ODBC
/// driver-manager init plus network handshake and auth round trip on every
/// call.
pub fn connect<'env>(
    env: &'env Environment,
    db2_dsn: &str,
    db2_user: &str,
    db2_pwd: &str,
) -> Result<Connection<'env>> {
    env.connect(db2_dsn, db2_user, db2_pwd, ConnectionOptions::default())
        .with_context(|| format!("Failed to connect to DB2 (DSN: {})", redact_dsn(db2_dsn)))
}

/// Checks that the running Db2 engine process (db2sysc) is owned by the
/// expected Db2 instance user, e.g. "db2luw1".
pub fn check_db2_instance_owner(expected_user: &str) -> Result<bool> {
    let output = process::Command::new("ps")
        .args(["-eo", "user=,comm="])
        .output()
        .context("Failed to execute ps.")?;

    let stdout = String::from_utf8_lossy(&output.stdout);

    let running_as = stdout
        .lines()
        .filter_map(|line| line.trim().split_once(char::is_whitespace))
        .find(|(_, comm)| comm.trim() == "db2sysc")
        .map(|(user, _)| user);

    match running_as {
        Some(user) if user == expected_user => {
            log::info!("Db2 instance is running as expected user: {}", user);
            Ok(true)
        }
        Some(user) => {
            log::error!(
                "Db2 instance is running as unexpected user: {} (expected {})",
                user,
                expected_user
            );
            Ok(false)
        }
        None => {
            log::error!("No running db2sysc process found.");
            Ok(false)
        }
    }
}

pub fn check_for_table_status(
    conn: &Connection<'_>,
    tabschema: &str,
    tabname: &str,
    status: &mut i32,
) -> Result<()> {
    let timeout_sec: Option<usize> = None;

    if tabschema.is_empty()
        || !tabschema
            .chars()
            .all(|c| c.is_ascii_alphanumeric() || matches!(c, | '_' | '-'))
    {
        anyhow::bail!(
            "Illegal character in tabschema {} (only ASCII alphanumerics, '_', '-', allowed): Aborting.",
            tabschema
        );
    }

    if tabname.is_empty()
        || !tabname
            .chars()
            .all(|c| c.is_ascii_alphanumeric() || matches!(c, | '_' | '-'))
    {
        anyhow::bail!(
            "Illegal character in tabname {} (only ASCII alphanumerics, '_', '-', allowed). Aborting.",
            tabname
        );
    }

    let qry_stmt = "SELECT CASE WHEN status = 'N' THEN 0 WHEN status = 'C' THEN -1 WHEN status = 'X' THEN -2 ELSE -3 END FROM syscat.tables WHERE LOWER(tabschema) = ? AND LOWER(tabname) = ? FOR READ ONLY;";

    log::debug!("Executing query: {}", qry_stmt);

    let qry_params = (&tabschema.into_parameter(), &tabname.into_parameter());

    let mut cursor = conn
            .execute(qry_stmt, qry_params, timeout_sec)?
            .context("Expected SELECT to create cursor")?;

    while let Some(mut row) = cursor.next_row()? {
        let mut field = Nullable::<i32>::null();
        row.get_data(1, &mut field)?;
        if let Some(value) = field.into_opt() {
            *status = value;
        }
    }

    Ok(())
}

pub fn check_for_empty_table(
    conn: &Connection<'_>,
    tabschema: &str,
    tabname: &str,
    table_is_empty: &mut bool,
) -> Result<()> {
    let timeout_sec: Option<usize> = None;
    *table_is_empty = false;

    if tabschema.is_empty()
        || !tabschema
            .chars()
            .all(|c| c.is_ascii_alphanumeric() || matches!(c, | '_' | '-'))
    {
        anyhow::bail!(
            "Illegal character in tabschema {} (only ASCII alphanumerics, '_', '-', allowed): Aborting.",
            tabschema
        );
    }

    if tabname.is_empty()
        || !tabname
            .chars()
            .all(|c| c.is_ascii_alphanumeric() || matches!(c, | '_' | '-'))
    {
        anyhow::bail!(
            "Illegal character in tabname {} (only ASCII alphanumerics, '_', '-', allowed). Aborting.",
            tabname
        );
    }

    let qry_stmt = format!("SELECT COUNT(*) FROM {}.{} FOR READ ONLY", tabschema, tabname);

    log::debug!("Executing query: {}", qry_stmt);

    let mut cursor = conn
        .execute(&qry_stmt.to_string(), (), timeout_sec)?
        .context("Expected SELECT to create cursor")?;

    if let Some(mut row) = cursor.next_row()? {
        let mut field = Nullable::<i32>::null();
        row.get_data(1, &mut field)?;
        if let Some(value) = field.into_opt() {
            if value == 0 {
                *table_is_empty = true;
            }

            log::debug!("SQL COUNT(*) result: {}", value);

        }
    }

    Ok(())
}

/// Check if UDF(s) or SP(s) exist(s)
pub fn check_if_udf_sp_exists(
    conn: &Connection<'_>,
    udf_sp_schema: &str,
    udf_sp_name: &str,
    is_udf: bool,
    udf_sp_exists: &mut bool,
) -> Result<()> {
    let timeout_sec: Option<usize> = None;
    *udf_sp_exists = false;

    // log::debug!("Schema: {}, Name: {}", udf_sp_schema, udf_sp_name);

    if udf_sp_schema.is_empty()
        || !udf_sp_schema
            .chars()
            .all(|c| c.is_ascii_alphanumeric() || matches!(c, | '_' | '-'))
    {
        anyhow::bail!(
            "Illegal character in tabschema {} (only ASCII alphanumerics, '_', '-', allowed): Aborting.",
            udf_sp_schema
        );
    }

    if udf_sp_name.is_empty()
        || !udf_sp_name
            .chars()
            .all(|c| c.is_ascii_alphanumeric() || matches!(c, | '_' | '-'))
    {
        anyhow::bail!(
            "Illegal character in tabname {} (only ASCII alphanumerics, '_', '-', allowed). Aborting.",
            udf_sp_name
        );
    }

    let qry_stmt: &str;

    if is_udf == true {
        qry_stmt = "SELECT COUNT(*) FROM syscat.functions WHERE funcschema = UPPER(?) AND funcname = UPPER(?) FOR READ ONLY";
    } else {
        qry_stmt = "SELECT COUNT(*) FROM syscat.procedures WHERE procschema = UPPER(?) AND procname = UPPER(?) FOR READ ONLY";
    }

    log::debug!("Executing query: {}", qry_stmt);

    let qry_params = (&udf_sp_schema.into_parameter(), &udf_sp_name.into_parameter());

    let mut cursor = conn
        .execute(qry_stmt, qry_params, timeout_sec)?
        .context("Expected SELECT to create cursor")?;

    if let Some(mut row) = cursor.next_row()? {
        let mut field = Nullable::<i32>::null();
        row.get_data(1, &mut field)?;
        if let Some(value) = field.into_opt() {
            if value != 0 {
                *udf_sp_exists = true;
            }

            log::debug!("SQL COUNT(*) result: {}", value);
        }

    }

    Ok(())
}

pub fn check_if_table_exists(
    conn: &Connection<'_>,
    tabschema: &str,
    tabname: &str,
    table_exists: &mut bool
) -> Result<()> {
    let timeout_sec: Option<usize> = None;
    *table_exists = false;

    let qry_stmt = "SELECT COUNT(1) FROM syscat.tables WHERE tabschema = UPPER(?) AND tabname = UPPER(?) FOR READ ONLY";

    log::debug!("Executing query: {}", qry_stmt);

    let mut cursor = conn.execute(qry_stmt, (&tabschema.into_parameter(), &tabname.into_parameter()), timeout_sec)?
        .context("Expected SELECT to create cursor")?;

    if let Some(mut row) = cursor.next_row()? {
        let mut field = Nullable::<i32>::null();
        row.get_data(1, &mut field)?;
        if let Some(value) = field.into_opt() {
            if value != 0 {
                *table_exists = true;
            }

            log::debug!("SQL COUNT(*) result: {}", value);
        }

    }

    Ok(())
}
