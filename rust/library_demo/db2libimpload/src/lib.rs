/*
Copyright Dr. Gerd Anders. All Rights Reserved.

SPDX-License-Identifier: Apache-2.0
*/

use anyhow::{Context, Result};
// use std::fs;
// use std::path::Path;
use quick_xml::Reader;
use quick_xml::events::Event;
use std::io::{self, BufRead, Read};

// use odbc_api::{Connection, ConnectionOptions, Cursor, Environment, IntoParameter, Nullable};
use odbc_api::{Connection, Cursor, IntoParameter, Nullable};

pub fn is_gzip(path: &str) -> io::Result<bool> {
    let mut f = std::fs::File::open(path)?;
    let mut header = [0u8; 2];

    if f.read_exact(&mut header).is_err() {
        return Ok(false);
    }

    Ok(header == [0x1f, 0x8b])
}

pub fn set_integrity(conn: &Connection<'_>, tabschema: &str, tabname: &str) -> Result<()> {
    let timeout_sec: Option<usize> = None;
    let mut count = 0;

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

    let qry_stmt = "SELECT COUNT(1) FROM syscat.tables WHERE tabschema = UPPER(?) AND tabname = UPPER(?) AND status = 'C' FOR READ ONLY";

    let mut cursor = conn
        .execute(qry_stmt, (&tabschema.into_parameter(), &tabname.into_parameter()), timeout_sec)?
        .context("Expected SELECT to create cursor")?;

    while let Some(mut row) = cursor.next_row()? {
        let mut field = Nullable::<i32>::null();
        row.get_data(1, &mut field)?;
        if let Some(value) = field.into_opt() {
            count = value;
        }
    }

    // in SET INTEGRITY pending state
    if count == 1 {
        let set_integrity_stmt = format!("SET INTEGRITY FOR {}.{} IMMEDIATE CHECKED", tabschema, tabname);

        log::debug!("Executing query: {}", set_integrity_stmt);

        match conn.execute(&set_integrity_stmt, (), timeout_sec) {
            Err(e) => log::error!(
                "SET INTEGRITY failed for '{}.{}': {}",
                &tabschema,
                &tabname,
                e
            ),
            Ok(None) => log::info!("SET INTEGRITY: No result set generated."),
            Ok(Some(mut cursor)) => {
                let mut row = cursor
                    .next_row()?
                    .context("Expected result row from SET INTEGRITY")?;

                let mut buf = Vec::<u8>::new();
                row.get_text(1, &mut buf)?;
                let col_1 = String::from_utf8(buf).context("Parameter name is not valid UTF-8")?;

                log::info!("SET INTEGRITY result: {}", col_1);
            }
        }
    } else {
        log::info!("SET INTEGRITY {}.{}: Nothing to do, skipping.", &tabschema, &tabname);
    }

    Ok(())
}

pub fn runstats(conn: &Connection<'_>, tabschema: &str, tabname: &str) -> Result<()> {
    let timeout_sec: Option<usize> = None;
    let mut count = 0;

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

    // check if table exists
    let query = "SELECT COUNT(1) FROM syscat.tables WHERE tabschema = UPPER(?) AND tabname = UPPER(?) AND status = 'N' FOR READ ONLY";

    let mut cursor = conn
        .execute( query, (&tabschema.into_parameter(), &tabname.into_parameter()), timeout_sec)?
        .context("Expected SELECT to create cursor")?;

    while let Some(mut row) = cursor.next_row()? {
        let mut field = Nullable::<i32>::null();
        row.get_data(1, &mut field)?;
        if let Some(value) = field.into_opt() {
            count = value;
        }
    }

    if count == 1 {
        let runstats_stmt = format!("CALL ADMIN_CMD ('RUNSTATS ON TABLE {}.{} ON KEY COLUMNS')", tabschema, tabname);

        log::debug!("Executing query: {}", runstats_stmt);

        match conn.execute(&runstats_stmt, (), timeout_sec) {
            Err(e) => log::error!("RUNSTATS failed for '{}.{}': {}", &tabschema, &tabname, e),
            Ok(None) => log::info!("RUNSTATS: No result set generated."),
            Ok(Some(mut cursor)) => {
                let mut row = cursor
                    .next_row()?
                    .context("Expected result row from SET INTEGRITY")?;

                let mut buf = Vec::<u8>::new();
                row.get_text(1, &mut buf)?;
                let col_1 = String::from_utf8(buf).context("Parameter name is not valid UTF-8")?;

                log::info!("RUNSTATS result: {}", col_1);
            }
        }
    } else {
        log::info!("RUNSTATS {}.{}: Nothing to do, skipping.", &tabschema, &tabname);
    }

    Ok(())
}

/// Hard cap on decompressed output size for a single gzip-compressed blob
/// (e.g. any xml.gz file), to guard against a decompression bomb: a
/// small compressed input that expands to an enormous amount of data.
///
pub const MAX_GUNZIP_SIZE: u64 = 1024 * 1024 * 1024; // 1 GB

/// Hard cap on total decompressed output size when reading a .tgz archive
/// stream (which may contain many entries), for the same reason.
///
pub const MAX_TGZ_SIZE: u64 = 1024 * 1024 * 1024; // 1 GB

/// A `Read` wrapper that returns an error once more than `limit` bytes have
/// been read from the underlying reader, instead of silently truncating
/// (as `std::io::Take` does) or letting the caller allocate unboundedly.
pub struct SizeLimitedReader<R> {
    inner: R,
    limit: u64,
    consumed: u64,
}

impl<R: Read> SizeLimitedReader<R> {
    pub fn new(inner: R, limit: u64) -> Self {
        Self {
            inner,
            limit,
            consumed: 0,
        }
    }
}

impl<R: Read> Read for SizeLimitedReader<R> {
    fn read(&mut self, buf: &mut [u8]) -> io::Result<usize> {
        let n = self.inner.read(buf)?;
        self.consumed += n as u64;
        if self.consumed > self.limit {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                format!(
                    "Refusing to decompress further: exceeded {} byte limit (possible decompression bomb)",
                    self.limit
                ),
            ));
        }
        Ok(n)
    }
}

/// Checks that `reader` yields at least one well-formed XML element.
///
/// Takes a `BufRead` rather than a fully-materialized `&[u8]` so that
/// callers validating decompressed gzip content (e.g. one ~12GB PDB xml.gz
/// file that dwarfs every other file processed) can stream straight from a
/// `GzDecoder` instead of first buffering the whole decompressed output in
/// memory just to throw it away after this check.
pub fn is_well_formed_xml<R: BufRead>(reader: R) -> bool {
    let mut reader = Reader::from_reader(reader);
    reader.config_mut().trim_text(true);
    let mut buf = Vec::new();
    let mut saw_element = false;

    loop {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Eof) => break,
            Ok(Event::Start(_)) | Ok(Event::Empty(_)) => saw_element = true,
            Ok(_) => {}
            Err(_) => return false,
        }

        buf.clear();
    }

    saw_element
}

