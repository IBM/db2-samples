# A Db2 Library

This library contains Db2 SQL

- **Views** to simplify working with Db2's system catalog and monitoring SQL functions.
- **Functions** to augment Db2's built-in ones
- **Compound statements** to run SQL against multiple objects
- **Procedures** to encapsulate some useful processes
- **Variables** to allow some views to be parameterized

You can use the files individually, or install the objects in a schema in your Db2 database(s).

There is a list and description of all objects here: [db-library.md](db-library.md)

## Install

Run [db-library.sql](db-library.sql) file in your favorite SQL interface.

> You will need to set the *statement delimiter* to `@` (i.e. do not use the default `;` delimiter).


By default the objects will be created in a schema called `DB`, but you can change that in the script.

All the objects are prefixed `DB_`, so you can add them to an existing schema if you wish

## Requirements

Db2 11.1 or upwards

For Db2 11.1, use the [db-library.db2_11.1.sql](db-library.db2_11.1.sql) file the 


### Install via CLP

     db2 -td@ -f db-library.sql

I recommend to *not* use the `db2` CLP as it strips all line-feeds from SQL VIEWs when it creates them. 
This legacy behavior means that you loose all my nice formatting in the catalog which makes the view SQL less useful for reference.

### Install vis dbsql

    dbsql -h $host -port $port -u $user -pw $password -d $database -terminator @ -f db-library.sql

### Uninstall

The [uninstall.sql](uninstall.sql) code will simply `DROP` all Views and Functions that begin with the three characters `DB_` in your **current schema**.

> Be careful, as this will drop any of *your* objects if they also start with the same three characters.


## Notes

The library has been created primarily while working on Db2 Warehouse, Db2 Warehouse on Cloud and IBM Integrated Analytics Systems. 
It therefore has a certain focus on managing Column Organized Tables and Data Warehouse workloads. 

It should still be useful for OLTP and mixed workloads, but feel free to suggest changes/additions to improve it's utility in this area.

The compound statements are particually useful when you don't have (or don't want to use) a shell or other scripting language for simple SQL tasks.
Often they are little more than wrappers to avoid the need to cut-and-paste "generated" SQL results back into your editor for execution.


The library is intended to be used from an **SQL GUI editor** rather than the Db2 command line processor.
For example, none of the views include `SUBSTR` on columns to reduce their display length.

The `@` is used as the statement delimiter is used throughout. It is needed for the compound SQL (i.e. `BEGIN` `END`) statements.

 `@` is not a bad practice to get used to using in general as you can then use in-line atomic statements in your day-to-day SQL work.

The library only supports Db2 11.1 upwards due to the use of `REXEXP` functions. SOme thinks will work on DB2 10.5 or earlier, but this has not been tested.


The views use the same column names as the db2 SYSCAT catalog views for the most part.
So we use e.g. `TABSCHMEA`, `TABNAME`, `COLNAME` et al.
This makes it simpler to join the db views with catalog tables and monitoring functions, even though say `COLUMN` or `COLUMN_NAME` might have been a little more user friendly in result sets.

I hope to have been somewhat consistent with my use of abbreviations. E.g.

- Use `DB` not `DATABASE` 
- USE `DBM` not `DATABASE_MANAGER`
- Use `GB` not `GIGABYTE` etc


I have tried to follow a certain SQL coding style for the views. This can be summarised as

- Use Unix line endings (i.e. `lF`, not `CR` `LF`)
- Use UTF-8 encoding
- Use spaces, not tabs to format the code
- Use 4 spaces as the indentation size
- Use start of line comma separators, not end of line
- All code in UPPER-CASE
- Vertically align code in many cases


We use the following options on all ATOMIC SQL scalar functions that are not using in-lined SQL

    ALLOW PARALLEL      -- The default is DISALLOW PARALLEL
    DETERMINISTIC       -- The default is NOT DETERMINISTIC which is not needed for most SQL UDFs
    NO EXTERNAL ACTION  -- The default is EXTERNAL ACTION   which is not needed for most SQL UDFs


## License

This code pattern is licensed under the Apache License, Version 2. Separate third-party code objects invoked within this code pattern are licensed by their respective providers pursuant to their own separate licenses. Contributions are subject to the [Developer Certificate of Origin, Version 1.1](https://developercertificate.org/) and the [Apache License, Version 2](https://www.apache.org/licenses/LICENSE-2.0.txt).

[Apache License FAQ](https://www.apache.org/foundation/license-faq.html#WhatDoesItMEAN)