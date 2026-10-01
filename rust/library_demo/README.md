# Overview

This Rust workspace demonstrates the use of certain Db2 commands in Rust. These commands are separated into two libraries, which can be re-used and adopted in other Rust projects.

## Directory *db2libadmin*

Directory *db2libadmin* contains a Rust file named *lib.rs, currently implementing the following Rust methods:
- pub fn acquire_lock_file
- pub fn redact_dsn
- pub fn connect
- pub fn check_db2_instance_owner
- pub fn check_for_table_status
- pub fn check_for_empty_table
- pub fn check_if_udf_sp_exists
- pub fn check_if_table_exists(

## Directory *db2libimpload*

Directory *db2libimpload* contains a Rust file named *lib.rs, currently implementing the following Rust methods:
- pub fn new
- fn read
- pub fn is_well_formed_xml

## Directory *db2main*

Directory *db2binmain* conatins the *main.rs* file which is compiled to an executable. It accesses various methods from the aforementioned libraries.
