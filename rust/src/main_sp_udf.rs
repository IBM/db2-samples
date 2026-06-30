/*
Copyright Dr. Gerd Anders. All Rights Reserved.

SPDX-License-Identifier: Apache-2.0
*/

// https://docs.rs/odbc-api/latest/odbc_api/struct.Connection.html
// https://docs.rs/odbc-api/latest/odbc_api/parameter/index.html

// Readme: Rename this file to main.rs - save already exisitng main.rs before if desired - and compile it

// For option 2:
use anyhow::{Context, Result};

// When Using InOut (see e. g. second URL above for a sample):
// use odbc_api::{Environment, ConnectionOptions, Out, InOut, Nullable};
use odbc_api::{Cursor, Environment, ConnectionOptions, Out, Nullable};
use odbc_api::parameter::VarCharArray;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let env = Environment::new()?;

    // Requirement: Db2 instance is started

    // Option 1: Values in plain text:
    // const DB2_DSN: &str = "dsn_db2samples";
    // const DB2_USER: &str = "db2luw1";
    // const DB2_PWD: &str = "db2lUw1";

    // let conn = env.connect(&DB2_DSN, &DB2_USER, &DB2_PWD, ConnectionOptions::default())?;

    // Option 2: Values taken from environmnt variables
    // in bash:
    // export DB2_DSN="dsn_db2samples";
    // export DB2_USER="db2luw1";
    // export DB2_PWD="db2lUw1";
    //
    let db2_dsn = std::env::var("DB2_DSN").context("DB2_DSN environment variable not set")?;
    let db2_user = std::env::var("DB2_USER").context("DB2_USER environment variable not set")?;
    let db2_pwd = std::env::var("DB2_PWD").context("DB2_PWD environment variable not set")?;

    let conn = env.connect(&db2_dsn, &db2_user, &db2_pwd, ConnectionOptions::default())?;

    // Sample for CALLing a Stored Procedure (SP)

    println!("");

    println!("Sample CALLing a SP: CALL DBMS_UTILITY.DB_VERSION(?, ?)");

    println!("");

    let mut rc = Nullable::<i32>::null();
    let mut version = VarCharArray::<64>::NULL;
    let mut compatibility = VarCharArray::<64>::NULL;

    // on Db2 command line, the SP below would return output like this:
    // CALL DBMS_UTILITY.DB_VERSION(?, ?)
    //
    // Value of output parameters
    // --------------------------
    // Parameter Name  : VERSION
    // Parameter Value : DB2 v12.1.4.0

    // Parameter Name  : COMPATIBILITY
    // Parameter Value : DB2 v12.1.4.0

    // Return Status = 0

    conn.execute("{? = CALL DBMS_UTILITY.DB_VERSION(?, ?)}",
                    (Out(&mut rc), Out(&mut version), Out(&mut compatibility)),
                    None)?;

    let version_str = version.as_bytes().map(|b| String::from_utf8_lossy(b).into_owned()).unwrap_or_default();
    let compat_str = compatibility.as_bytes().map(|b| String::from_utf8_lossy(b).into_owned()).unwrap_or_default();

    println!("Return code : {:?}", rc.into_opt());
    println!("VERSION     : {}", version_str);
    println!("COMPATIBILITY: {}", compat_str);

    println!("\n");

    // Sample for executing a User-Defined Function (UDF)

    // for parameter marker in SELECT statement below:
    let my_ibm_dbs = VarCharArray::<3>::new(b"db2");

    // on Db2 command line, the UDF below would return output like this:
    // db2 "VALUES UPPER('db2')"
    //
    // 1
    // ---
    // DB2
    // 
    // 1 record(s) selected.

    let timeout_sec: Option<usize> = None;
    let mut row_cnt: u32 = 0;

    println!("");

    // SELECT sample

    println!("SELECT sample using a UDF: SELECT UPPER(?) FROM SYSIBM.SYSDUMMY1");

    println!("");

    let select_udf_stmt = "SELECT UPPER(?) FROM SYSIBM.SYSDUMMY1";
    // Equivalant for SQL statement above:
    // let values_udf_stmt = "VALUES UPPER(?)";

    let mut cursor = conn.execute(select_udf_stmt, &my_ibm_dbs, timeout_sec)?.expect("Assume select statement creates cursor");

    while let Some(mut row) = cursor.next_row()? {
        let mut buf = Vec::<u8>::new();
        row.get_text(1, &mut buf)?;
        let upper_case = String::from_utf8(buf).unwrap();

        println!("{}", upper_case);

        row_cnt += 1;
    }

    println!("\n {} record(s) selected.", row_cnt);

    println!("\n");

    Ok(())
}
