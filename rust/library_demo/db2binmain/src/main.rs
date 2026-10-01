/*
Copyright Dr. Gerd Anders. All Rights Reserved.

SPDX-License-Identifier: Apache-2.0
*/

//! Rust demo for SAMPLE database
//!
//! ## Configuration
//! Database credentials as well as a schema must be provided via environment variables or in a .env file:
//! - `DB2_DSN` - Database DSN (e.g., "dsn_db2samples")
//! - `DB2_USER` - Database username
//! - `DB2_PWD` - Database password
//! - `DB2_SCHEMA` - Database schema
//! 
//!
//! ## Usage
//!
//! ```bash
//! # Set environment variables
//! export DB2_DSN="dsn_proxpdb2"
//! export DB2_USER="db2luw1"
//! export DB2_PWD="your_password"
//! export DB2_SCHEMA="your_schema"
//!
//! # Or use a .env file
//! echo "DB2_DSN=dsn_proxpdb2" >> .env
//! echo "DB2_USER=db2luw1" >> .env
//! echo "DB2_PWD=your_password" >> .env
//! echo "DB2_SCHEMA=your_schema" >> .env
//!
//! # Run the program
//! ./db2binmain_run.sh
//!
//! ```

use anyhow::{Context, Result};
use fs2::FileExt;
use log::{debug, error, info};
use std::env;
use std::path::Path;

use db2libadmin;
// placeholder for more sample code (in development)
// use db2libimpload;

/// Constants
const LOCK_FILE: &str = "db2binmain.lock";

/// Database configuration
#[derive(Clone)]
struct DbConfig {
    dsn: String,
    user: String,
    schema: String,
    password: String,
}

// Manual Debug impl (instead of #[derive(Debug)]) so that logging this
// struct with {:?} can never print the plaintext password, even if a future
// call site does so.
impl std::fmt::Debug for DbConfig {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("DbConfig")
            .field("dsn", &self.dsn)
            .field("user", &self.user)
            .field("schema", &self.schema)
            .field("password", &"***")
            .finish()
    }
}

impl DbConfig {
    /// Load database configuration from environment variables
    fn from_env() -> Result<Self> {
        // Try to load from .env file (silently ignore if not found)
        let _ = dotenvy::dotenv();

        let dsn = env::var("DB2_DSN").context(
            "DB2_DSN environment variable not set. Please set it or create a .env file.",
        )?;

        let user = env::var("DB2_USER").context(
            "DB2_USER environment variable not set. Please set it or create a .env file.",
        )?;

        let schema = env::var("DB2_SCHEMA").context(
            "DB2_SCHEMA environment variable not set. Please set it or create a .env file.",
        )?;

        let password = env::var("DB2_PWD").context(
            "DB2_PWD environment variable not set. Please set it or create a .env file.",
        )?;

        info!("Database configuration loaded successfully");
        debug!("Using DSN: {}, User: {}", db2libadmin::redact_dsn(&dsn), user);

        Ok(DbConfig {
            dsn,
            user,
            schema,
            password,
        })
    }
}

fn run() -> Result<i32> {
    let db_config = DbConfig::from_env()
        .context("Failed to load database configuration. See error above for details.")?;

    // Initialize logging
    env_logger::init();
    //    initialize_logging(args.verbose);

    // Load database configuration once: DB2_DSN / DB2_USER / DB2_PWD are
    // the single source of truth for credentials, used both for this
    // function's own connection below and for every worker thread's
    // connection (in case threading is used). Read a DB2_PWD env
    // var for its own connection while DbConfig::from_env() read
    // DB2_PWD for worker threads, so both had to independently hold
    // the same secret -- forgetting DB2_PWD aborted the run even though
    // DB2_PWD (the only var documented above) was set correctly.

    match db2libadmin::check_db2_instance_owner(&db_config.user) {
        Ok(true) => {
            info!("Db2 instance owner check passed. Continuing...");
        }
        Ok(false) => {
            return Ok(3);
        }
        Err(err) => {
            error!(
                "Failed to check if Db2 instance is running for {}: {}",
                &db_config.user,
                err
            );
            return Ok(3);
        }
    }
    // One connection, opened once and reused for every sequential DB2 call
    // made on the main thread below, instead of each db2libgen call paying
    // its own ODBC driver-manager init + network handshake + auth round
    // trip. Worker threads still open their own connection each, since a
    // single Connection cannot be shared safely across threads.
    let env = odbc_api::Environment::new().context("Failed to create ODBC environment")?;
    let conn = db2libadmin::connect(&env, &db_config.dsn, &db_config.user, &db_config.password)?;


    let tmp_path = std::env::var("TMPDIR").unwrap_or_else(|_| String::from("/tmp/"));

    let mut abs_lock_file: String = tmp_path.to_owned();

    if abs_lock_file.ends_with("/") == false {
        abs_lock_file.push_str("/");
    }

    abs_lock_file.push_str(LOCK_FILE);

    info!("abs_lock_file: {}", abs_lock_file);

    let lock_file = match db2libadmin::acquire_lock_file(Path::new(&abs_lock_file)) {
        Ok(f) => f,
        Err(e) => {
            log::error!("Failed to open lock file: {e}");
            return Ok(1);
        }
    };

    match lock_file.try_lock_exclusive() {
        Ok(()) => {
            info!("Lock acquired. Continuing...");
        }
        Err(_) => {
            error!("Another instance is already running. Aborting.");
            return Ok(2);
        }
    }

    let mut table_status: i32 = 0;
    // let mut num_records: i32 = 0;

    info!("Starting Rust demo processing pipeline");
    //    debug!("Arguments: {:?}", args);

    db2libadmin::check_for_table_status(&conn, &db_config.schema, "employee", &mut table_status)
        .context("Failed to ensure sufficient table status from database")?;

    match table_status {
         0 => log::info!( "Table status ('Normal') for table {} is sufficient. Continuing.", "employee"),
        -1 => { error!( "Table status ('Set integrity pending') for table {} is not sufficient. Aborting.", "employee"); return Ok(4); }
        -2 => { error!( "Table status ('Inoperative') for table {} is not sufficient. Aborting.", "employee"); return Ok(4); }
         _ => { error!( "Table status ('Unknown status') for table {} is not sufficient. Aborting.", "employee"); return Ok(4); }
    }

    Ok(0)
}

fn main() {
    let exit_code = match run() {
        Ok(code) => code,
        Err(e) => {
            eprintln!("Error: {:?}", e);
            1
        }
    };

    std::process::exit(exit_code);
}
