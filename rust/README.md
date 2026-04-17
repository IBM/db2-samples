[//]: # (Copyright Dr. Gerd Anders. All Rights Reserved.)
[//]: # (SPDX-License-Identifier: Apache-2.0)

# Installation of the Db2 Community Edition (v12.1.4)

Ubuntu Server v22.04.4 LTS is used. The Db2 server hostname is db2samples.

## Installing required Linux packages for Db2 Community Edition (CE)

```bash
root@db2samples:~# apt update && apt install ksh binutils -y
```

## Create directory for extracting Db2 installation image

```bash
root@db2samples:~# mkdir -p ~/db2ce
root@db2samples:~# cd ~/db2ce/
root@db2samples:~/db2ce#
```

## Extract Db2 installation image

It is assumed that the Db2 CE installation package is located in the db2ce subdirectory.

```bash
root@db2samples:~/db2ce# ls -1
v12.1.4_linuxx64_server_dec.tar.gz
root@db2samples:~/db2ce# tar xzf v12.1.4_linuxx64_server_dec.tar.gz
root@db2samples:~/db2ce# ls -1
server_dec
v12.1.4_linuxx64_server_dec.tar.gz
root@db2samples:~/db2ce#
```

## Run db2prereqcheck

```bash
root@db2samples:~/db2ce# cd server_dec/
root@db2samples:~/db2ce/server_dec# ./db2prereqcheck -i -l
Requirement not matched for DB2 database "Server" . Version: "12.1.4.0".
Summary of prerequisites that are not met on the current system:
   DBT3514W  The db2prereqcheck utility failed to find the following 32-bit library file only required to support 32-bit non-sql routines: "/lib/i386-linux-gnu/libpam.so*" provided by the "libpam0g:i386" package.

DBT3514W  The db2prereqcheck utility failed to find the following 32-bit library file only required to support 32-bit non-sql routines: "libstdc++.so.6" provided by the "libstdc++.i686" package.
```

The warnings refer to 32-bit libraries. These can be ignored. Otherwise, to get rid of them:

```bash
root@db2samples:~/db2ce/server_dec# dpkg --add-architecture i386
root@db2samples:~/db2ce/server_dec# apt update
[...]
apt install libpam0g:i386 libx32stdc++6 -y
[...]
root@db2samples:~/db2ce/server_dec# ./db2prereqcheck -i -l
root@db2samples:~/db2ce/server_dec#
```

## Create Db2 installation directory and run Db2 installation

```bash
root@db2samples:~/db2ce/server_dec# mkdir -p /opt/ibm/db2/v12.1.4/
root@db2samples:~/db2ce/server_dec# ./db2_install -b /opt/ibm/db2/v12.1.4/ -p SERVER -f NOPCMK -y
DB2 installation is being initialized.

 Total number of tasks to be performed: 54
[...]
The execution completed successfully.

For more information see the DB2 installation log at
"/tmp/db2_install.log.<process id>".
root@db2samples:~/db2ce/server_dec#
```

## Optional: Validate Db2 installation

```bash
root@db2samples:~/db2ce/server_dec# cd /opt/ibm/db2/v12.1.4/bin/
root@db2samples:/opt/ibm/db2/v12.1.4/bin# ./db2val
DBI1379I  The db2val command is running. This can take several minutes.

DBI1335I  Installation file validation for the DB2 copy installed at
      /opt/ibm/db2/v12.1.4 was successful.

DBI1343I  The db2val command completed successfully. For details, see
      the log file /tmp/db2val-<YYMMDD>_<HHMMSS>.log.


root@db2samples:/opt/ibm/db2/v12.1.4/bin#
```

## Creating Db2 groups and users

Feel free to use different group IDs (here 5001 and 5002 are used), group names, and/or user names:

```bash
root@db2samples:/opt/ibm/db2/v12.1.4/bin# groupadd -g 5001 db2luwgr
root@db2samples:/opt/ibm/db2/v12.1.4/bin# groupadd -g 5002 db2fengr
root@db2samples:/opt/ibm/db2/v12.1.4/bin# useradd -c "Db2 LUW instance user" -u 5001 -g db2luwgr -s /bin/bash -m db2luw1
root@db2samples:/opt/ibm/db2/v12.1.4/bin# useradd -c "Db2 LUW fenced user" -u 5002 -g db2fengr -s /bin/bash -m db2fluw1
```

A password for db2luw1 is required later; this setting is skipped here.

## Create Db2 instance

```bash
root@db2samples:/opt/ibm/db2/v12.1.4/bin# cd /opt/ibm/db2/v12.1.4/instance/
root@db2samples:/opt/ibm/db2/v12.1.4/instance# ./db2icrt -a SERVER -u db2fluw1 db2luw1
DBI1446I  The db2icrt command is running.
[...]
The execution completed successfully.

For more information see the DB2 installation log at "/tmp/db2icrt.log.<process id>".
DBI1070I  Program db2icrt completed successfully.

root@db2samples:/opt/ibm/db2/v12.1.4/instance#
```

## Clean up Db2 CE installation

```bash
root@db2samples:/opt/ibm/db2/v12.1.4/instance# cd
root@db2samples:~# rm -rf ~/db2ce/
```

## Linux Kernel parameter settings

For the Db2 server installation, Linux kernel parameters should be set; see [Kernel parameter requirements (Linux](https://www.ibm.com/docs/en/db2/12.1.x?topic=unix-kernel-parameter-requirements-linux). For the sake of simplicity, they are skipped here. The Db2 server should nevertheless work.

## Creating the SAMPLE database (and optionally activating it)

```bash
db2luw1@db2samples:~$ db2start
MM/DD/YYYY hh:mm:ss     0   0   SQL1063N  DB2START processing was successful.
SQL1063N  DB2START processing was successful.
db2luw1@db2samples:~$ db2sampl -sql -xml -vector

  Creating database "SAMPLE"...
  Connecting to database "SAMPLE"...
  Creating tables and data in schema "DB2LUW1"...
  Creating tables with XML columns and XML data in schema "DB2LUW1"...
  Creating tables with VECTOR columns and VECTOR data in schema "DB2LUW1"...

  'db2sampl' processing complete.

db2luw1@db2samples:~$ db2 activate db SAMPLE
DB20000I  The ACTIVATE DATABASE command completed successfully.
db2luw1@db2samples:~$ db2 list db directory

 System Database Directory

 Number of entries in the directory = 1

Database 1 entry:

 Database alias                       = SAMPLE
 Database name                        = SAMPLE
 Local database directory             = /home/db2luw1
 Database release level               = 16.00
 Comment                              =
 Directory entry type                 = Indirect
 Catalog database partition number    = 0
 Alternate server hostname            =
 Alternate server port number         =
```

## Installing Db2 ODBC CLI driver

### In case these two Linux packages are not installed yet:

```bash
root@db2samples:~# apt install unixodbc unixodbc-dev gcc -y
[...]
root@db2samples:~#
```

Note: Any "regular" Linux user (in this case, scientist) is used for the following tasks.

The Db2 ODBC CLI driver v12.1.4 can be downloaded from [here](https://www.ibm.com/support/fixcentral/swg/selectFixes?parent=ibm%2FInformation%20Management&product=ibm/Information+Management/IBM+Data+Server+Client+Packages&release=12.1.4.0&platform=Linux+64-bit,x86_64&function=fixId&fixids=*odbc_cli-*FP000&includeSupersedes=0&source=fc). Use the one with linuxx64 in the filename.


```bash
scientist@db2samples:~/db2odbccli$ ls -1 v12.1.4_linuxx64_odbc_cli.tar.gz
v12.1.4_linuxx64_odbc_cli.tar.gz
scientist@db2samples:~/db2odbccli$ tar -xzf v12.1.4_linuxx64_odbc_cli.tar.gz
scientist@db2samples:~/db2odbccli$ mv odbc_cli/ ~/db2_odbc_cli
scientist@db2samples:~/db2odbccli$ cd ..
scientist@db2samples:~$ rm -rf ~/db2odbccli/
scientist@db2samples:~$
```

## Db2 ODBC driver configuration

```bash
scientist@db2samples:~$ cd db2_odbc_cli/clidriver/cfg/
scientist@db2samples:~/db2_odbc_cli/clidriver/cfg$ ls
db2cli.ini.sample  db2dsdriver.cfg.sample  db2dsdriver.xsd
scientist@db2samples:~/db2_odbc_cli/clidriver/cfg$
```

### db2dsdriver.cfg

Created new db2dsdriver.cfg configuration file with the following content:

```bash
scientist@db2samples:~/db2_odbc_cli/clidriver/cfg$ cat db2dsdriver.cfg
<configuration>
   <!-- Multi-line comments are not supported -->
   <dsncollection>
      <dsn alias="dsn_db2samples" name="SAMPLE" host="db2samples.fritz.box" port="25000">
         <parameter name="Authentication" value="SERVER"/>
      </dsn>
   </dsncollection>
   <databases>
      <database name="SAMPLE" host="db2samples.fritz.box" port="25000">
         <parameter name="CurrentSchema" value="DB2LUW1"/>
      </database>
      <!-- Local IPC connection -->
      <database name="SAMPLE" host="localhost" port="0">
         <parameter name="IPCInstance" value="DB2LUW1"/>
         <parameter name="CommProtocol" value="IPC"/>
      </database>
   </databases>
   <parameters>
   </parameters>
</configuration>
```

### db2cli.ini

Created new db2cli.ini configuration file with the following content:

```bash
scientist@db2samples:~/db2_odbc_cli/clidriver/cfg$ cat db2cli.ini
[dsn_db2samples]
uid=db2luw1
pwd=<your_password>
autocommit=1
TableType="'TABLE','VIEW','SYSTEM TABLE'"
```

Remark: Set proper file permissions for
- ~/db2\_odbc\_cli/clidriver/cfg/db2dsdriver.cfg
- ~/db2\_odbc\_cli/clidriver/cfg/db2cli.ini
explicitly.

### When Linux user is not a Db2 instance owner (like in this case)

```bash
scientist@db2samples:~/db2_odbc_cli/clidriver/cfg$ cd ../lib/
scientist@db2samples:~/db2_odbc_cli/clidriver/lib$ pwd
/home/scientist/db2_odbc_cli/clidriver/lib
```

export LD\_LIBRARY\_PATH as follows (for bash):

```bash
scientist@db2samples:~/db2_odbc_cli/clidriver/lib$ vi ~/.bashrc
scientist@db2samples:~/db2_odbc_cli/clidriver/lib$ grep -A 1 -B 1 LD_LIBRARY_PATH ~/.bashrc
if [ -d "/home/scientist/db2_odbc_cli/clidriver/lib" ] ; then
        export LD_LIBRARY_PATH="/home/scientist/db2_odbc_cli/clidriver/lib";
fi
```

Logout and re-login.

### Optional: Validation

```bash
scientist@db2samples:~$ printenv | grep LD_LIBRARY_PATH
LD_LIBRARY_PATH=/home/scientist/db2_odbc_cli/clidriver/lib
scientist@db2samples:~$
```

### Configuration validation

```bash
scientist@db2samples:~$ cd ~/db2_odbc_cli/clidriver/bin
scientist@db2samples:~/db2_odbc_cli/clidriver/bin$ ./db2cli validate -dsn dsn_db2samples -connect -user db2luw1 -passwd <your_password>

===============================================================================
Client information for the current copy:
===============================================================================

Client Package Type       : IBM Data Server Driver For ODBC and CLI
Client Version (level/bit): DB2 v12.1.4.0 (s2602211313/64-bit)
Client Platform           : Linux/X8664
Install/Instance Path     : /home/scientist/db2_odbc_cli/clidriver
DB2DSDRIVER_CFG_PATH value: <not-set>
db2dsdriver.cfg Path      : /home/scientist/db2_odbc_cli/clidriver/cfg/db2dsdriver.cfg
DB2CLIINIPATH value       : <not-set>
db2cli.ini Path           : /home/scientist/db2_odbc_cli/clidriver/cfg/db2cli.ini
db2diag.log Path          : /home/scientist/db2_odbc_cli/clidriver/db2dump/db2diag.log

===============================================================================
db2dsdriver.cfg schema validation for the entire file:
===============================================================================

Success: The system db2dsdriver.cfg schema validation completed successfully without any errors.

===============================================================================
db2cli.ini validation for data source name "dsn_db2samples":
===============================================================================

[ Keywords used for the connection ]

Keyword                   Value
---------------------------------------------------------------------------
UID                       db2luw1
PWD                       *******
AUTOCOMMIT                1
TABLETYPE                 "'TABLE','VIEW','SYSTEM TABLE'"

===============================================================================
db2dsdriver.cfg validation for data source name "dsn_db2samples":
===============================================================================

[ Parameters used for the connection ]

Keywords                  Valid For     Value
---------------------------------------------------------------------------
DATABASE                  CLI,.NET,ESQL sample
HOSTNAME                  CLI,.NET,ESQL db2samples.fritz.box
PORT                      CLI,.NET,ESQL 25000
AUTHENTICATION            CLI,.NET      SERVER
CURRENTSCHEMA             CLI,.NET      DB2LUW1

===============================================================================
Connection attempt for data source name "dsn_db2samples":
===============================================================================

[SUCCESS]

Output Connection String :
"DSN=DSN_DB2SAMPLES;UID=db2luw1;PWD=********;AUTOCOMMIT=1;TABLETYPE="'TABLE','VIEW','SYSTEM
TABLE'";AUTHENTICATION=SERVER;CURRENTSCHEMA=DB2LUW1;"

===============================================================================
The validation is completed.
===============================================================================

scientist@db2samples:~/db2_odbc_cli/clidriver/bin$
```

## ODBC manager configuration

### When Linux user is not a Db2 instance owner (like in this case)

Locate libdb2o.so file as follows (which is a symbolic link):

```bash
scientist@db2samples:~$ find ~/db2_odbc_cli/clidriver -name "libdb2o.so" -type l
/home/scientist/db2_odbc_cli/clidriver/lib/libdb2o.so
scientist@db2samples:~$
```

Create or modify the ini file below with the following content:

```bash
scientist@db2samples:~$ cat ~/.odbc.ini
[ODBC Data sources]
dsn_db2samples = db2driver

[dsn_db2samples]
Driver = /home/scientist/db2_odbc_cli/clidriver/lib/libdb2o.so
Description = ODBC setup for Db2
```

## Installing Rust

Simple press ENTER at the prompt:

```bash
scientist@db2samples:~$ curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
info: downloading installer
```

Logging out and re-logging in.

### Optional: Rust installation validation

Note: The Rust version may vary:

```bash
scientist@db2samples:~$ rustc --version
rustc 1.94.1 (e408947bf 2026-03-25)
```

## Creating a Rust application

```bash
scientist@db2samples:~$ mkdir rust4db2
scientist@db2samples:~$ cd rust4db2/
scientist@db2samples:~/rust4db2$ cargo new rust_odbc_test
    Creating binary (application) `rust_odbc_test` package
note: see more `Cargo.toml` keys and their definitions at https://doc.rust-lang.org/cargo/reference/manifest.html
scientist@db2samples:~/rust4db2$ ls -1
rust_odbc_test
scientist@db2samples:~/rust4db2$ cd rust_odbc_test/
scientist@db2samples:~/rust4db2/rust_odbc_test$ ls -1
Cargo.toml
src
```

Content of Cargo.toml:

```bash
scientist@db2samples:~/rust4db2/rust_odbc_test$ cat Cargo.toml
[package]
name = "rust_odbc_test"
version = "0.1.0"
edition = "2024"

[dependencies]
```

## Adding Rust crate odbc-api

https://docs.rs/odbc-api/latest/odbc_api/
https://github.com/pacman82/odbc-api

```bash
scientist@db2samples:~/rust4db2/rust_odbc_test$ cargo add odbc-api
    Updating crates.io index
      Adding odbc-api v24.0.0 to dependencies
             Features:
             [...]
    Updating crates.io index
     Locking 146 packages to latest Rust 1.94.1 compatible versions
scientist@db2samples:~/rust4db2/rust_odbc_test$
```

Useful crate, which will be used as well:

```bash
scientist@db2samples:~/rust4db2/rust_odbc_test$ cargo add anyhow
[...]
scientist@db2samples:~/rust4db2/rust_odbc_test$
```
Listing modifications in dependencies section:

```bash
scientist@db2samples:~/rust4db2/rust_odbc_test$ cat Cargo.toml
[package]
name = "rust_odbc_test"
version = "0.1.0"
edition = "2024"

[dependencies]
anyhow = "1.0.102"
odbc-api = "24.0.0"
scientist@db2samples:~/rust4db2/rust_odbc_test$
```

Note the new record in Cargo.toml below section dependencies.

## Compiling ("production-ready") binary:

```bash
scientist@db2samples:~/rust4db2/rust_odbc_test$ cargo build --release
   [...]
   Compiling odbc-api v24.0.0
   Compiling rust_odbc_test v0.1.0 (/home/scientist/rust4db2/rust_odbc_test)
    Finished `release` profile [optimized] target(s) in 2.87s
scientist@db2samples:~/rust4db2/rust_odbc_test$
```

## Executing Rust binary:

```bash
scientist@db2samples:~/rust4db2/rust_odbc_test$ cargo run --release > db2output.txt
Finished `release` profile [optimized] target(s) in 0.02s
     Running `target/release/rust_odbc_test
scientist@db2samples:~/rust4db2/rust_odbc_test$
```
