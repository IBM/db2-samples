/*
Copyright Dr. Gerd Anders. All Rights Reserved.

SPDX-License-Identifier: Apache-2.0
*/

// https://docs.rs/odbc-api/latest/odbc_api/struct.Connection.html

// For option 2:
use anyhow::{Context, Result};

use odbc_api::{Cursor, Environment, ConnectionOptions};

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

    // The queries below do not use any parameters
    let query_params = ();
    let timeout_sec: Option<usize> = None;
    let mut row_cnt: u32 = 0;

    println!("");

    // SELECT sample

    println!("SELECT sample");

    println!("");

    let select_stmt = "SELECT empno, firstnme, COALESCE(midinit, '-') AS midinit, lastname, edlevel FROM employee ORDER BY empno";

    println!("| {:>8} | {:<12} | {:<8} | {:<15} | {:<7} |", "empno", "firstnme", "midinit", "lastname", "edlevel");
    println!("|----------|--------------|----------|-----------------|---------|");

    let mut cursor = conn.execute(select_stmt, query_params, timeout_sec)?.expect("Assume select statement creates cursor");
    while let Some(mut row) = cursor.next_row()? {
        let mut buf = Vec::<u8>::new();
        row.get_text(1, &mut buf)?;
        let empno = String::from_utf8(buf).unwrap();

        let mut buf = Vec::<u8>::new();
        row.get_text(2, &mut buf)?;
        let firstnme = String::from_utf8(buf).unwrap();

        let mut buf = Vec::<u8>::new();
        row.get_text(3, &mut buf)?;
        let midinit = String::from_utf8(buf).unwrap();

        let mut buf = Vec::<u8>::new();
        row.get_text(4, &mut buf)?;
        let lastname = String::from_utf8(buf).unwrap();

        let mut edlevel: u8 = 0;
        row.get_data(5, &mut edlevel)?;

        println!("| {empno:>8} | {firstnme:<12} | {midinit:<8} | {lastname:<15} | {edlevel:>7} |");

        row_cnt += 1;
    }

    println!("\n {} record(s) selected.", row_cnt);

    // INSERT sample

    println!("\n\nINSERT sample");

    let insert_stmt = "INSERT INTO employee (empno, firstnme, midinit, lastname, workdept, phoneno, hiredate, job, edlevel, sex, birthdate, salary, bonus, comm) \
                        VALUES ('000000', 'THOMAS', 'J', 'WATSON', 'A00', '1234', '05/01/1914', 'FOUNDER', 20, 'M', '02/17/1874', 250000, 2500, 8750)";

    match conn.execute(insert_stmt, query_params, timeout_sec) {
        Err(e) => println!("INSERT stmt: {}", e),
        Ok(None) => println!("INSERT stmt: Ok(None))"),
        Ok(Some(_)) => println!("INSERT stmt: Ok(some(_))"),
    }

    // INSERT validation

    let select_stmt = "SELECT empno, firstnme, COALESCE(midinit, '-') AS midinit, lastname, edlevel FROM employee WHERE empno = '000000'";
        
    println!("After INSERT:\n");
    println!("| {:>8} | {:<12} | {:<8} | {:<15} | {:<7} |", "empno", "firstnme", "midinit", "lastname", "edlevel");
    println!("|----------|--------------|----------|-----------------|---------|");

    row_cnt = 0;

    let mut cursor = conn.execute(select_stmt, query_params, timeout_sec)?.expect("Assume select statement creates cursor");
    while let Some(mut row) = cursor.next_row()? {
        let mut buf = Vec::<u8>::new();
        row.get_text(1, &mut buf)?;
        let empno = String::from_utf8(buf).unwrap();

        let mut buf = Vec::<u8>::new();
        row.get_text(2, &mut buf)?;
        let firstnme = String::from_utf8(buf).unwrap();

        let mut buf = Vec::<u8>::new();
        row.get_text(3, &mut buf)?;
        let midinit = String::from_utf8(buf).unwrap();

        let mut buf = Vec::<u8>::new();
        row.get_text(4, &mut buf)?;
        let lastname = String::from_utf8(buf).unwrap();

        let mut edlevel: u8 = 0;
        row.get_data(5, &mut edlevel)?;

        println!("| {empno:>8} | {firstnme:<12} | {midinit:<8} | {lastname:<15} | {edlevel:>7} |");

        row_cnt += 1;
    }

    println!("\n {} record(s) selected.", row_cnt);

    // UPDATE sample

    println!("\n\nUPDATE sample");

    let update_stmt = "UPDATE employee SET empno = '000001' WHERE empno = '000000'";

    match conn.execute(update_stmt, query_params, timeout_sec) {
        Err(e) => println!("UPDATE stmt: {}", e),
        Ok(None) => println!("UPDATE stmt: Ok(None))"),
        Ok(Some(_)) => println!("UPDATE stmt: Ok(some(_))"),
    }

    // UPDATE validation

    let select_stmt = "SELECT empno, firstnme, COALESCE(midinit, '-') AS midinit, lastname, edlevel FROM employee WHERE empno IN ('000000', '000001') ORDER BY empno";

    row_cnt = 0;

    println!("After UPDATE:\n");
    println!("| {:>8} | {:<12} | {:<8} | {:<15} | {:<7} |", "empno", "firstnme", "midinit", "lastname", "edlevel");
    println!("|----------|--------------|----------|-----------------|---------|");

    let mut cursor = conn.execute(select_stmt, query_params, timeout_sec)?.expect("Assume select statement creates cursor");
    while let Some(mut row) = cursor.next_row()? {
        let mut buf = Vec::<u8>::new();
        row.get_text(1, &mut buf)?;
        let empno = String::from_utf8(buf).unwrap();

        let mut buf = Vec::<u8>::new();
        row.get_text(2, &mut buf)?;
        let firstnme = String::from_utf8(buf).unwrap();

        let mut buf = Vec::<u8>::new();
        row.get_text(3, &mut buf)?;
        let midinit = String::from_utf8(buf).unwrap();

        let mut buf = Vec::<u8>::new();
        row.get_text(4, &mut buf)?;
        let lastname = String::from_utf8(buf).unwrap();

        let mut edlevel: u8 = 0;
        row.get_data(5, &mut edlevel)?;

        println!("| {empno:>8} | {firstnme:<12} | {midinit:<8} | {lastname:<15} | {edlevel:>7} |");

        row_cnt += 1;
    }

    println!("\n {} record(s) selected.", row_cnt);

    // DELETE sample

    println!("\n\nDELETE sample");

    let delete_stmt = "DELETE FROM employee WHERE empno <= '000001'";

    match conn.execute(delete_stmt, query_params, timeout_sec) {
        Err(e) => println!("DELETE stmt: {}", e),
        Ok(None) => println!("DELETE stmt: Ok(None))"),
        Ok(Some(_)) => println!("DELETE stmt: Ok(some(_))"),
    }

    // DELETE validation (should not output any records after DELETE)

    let select_stmt = "SELECT empno, firstnme, COALESCE(midinit, '-') AS midinit, lastname, edlevel FROM employee WHERE empno IN ('000000', '000001') ORDER BY empno";

    println!("After DELETE:\n");
    println!("| {:>8} | {:<12} | {:<8} | {:<15} | {:<7} |", "empno", "firstnme", "midinit", "lastname", "edlevel");
    println!("|----------|--------------|----------|-----------------|---------|");

    row_cnt = 0;

    let mut cursor = conn.execute(select_stmt, query_params, timeout_sec)?.expect("Assume select statement creates cursor");
    while let Some(mut row) = cursor.next_row()? {
        let mut buf = Vec::<u8>::new();
        row.get_text(1, &mut buf)?;
        let empno = String::from_utf8(buf).unwrap();

        let mut buf = Vec::<u8>::new();
        row.get_text(2, &mut buf)?;
        let firstnme = String::from_utf8(buf).unwrap();

        let mut buf = Vec::<u8>::new();
        row.get_text(3, &mut buf)?;
        let midinit = String::from_utf8(buf).unwrap();

        let mut buf = Vec::<u8>::new();
        row.get_text(4, &mut buf)?;
        let lastname = String::from_utf8(buf).unwrap();

        let mut edlevel: u8 = 0;
        row.get_data(5, &mut edlevel)?;

        println!("| {empno:>8} | {firstnme:<12} | {midinit:<8} | {lastname:<15} | {edlevel:>7} |");

        row_cnt += 1;
    }

    println!("\n {} record(s) selected.", row_cnt);

    println!("\n");

    Ok(())
}
