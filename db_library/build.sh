#!/bin/bash

# A simple bit of code to concatenate all the library views and other CREATEable things into a single "install" sql file
#  also creates a version of the views for use against snapshot versions of SYSCAT, SYSIBMADM and the MON table functions
# and generates the db-library.md file and comments.sql from the 5th line of each file

NAME="db-library"
echo $(($(cat version)+1)) > version
VERSION=$(cat version)
MAJOR=1

OUT=$NAME.sql
DOCS=db-library.md

echo creating $OUT for version $MAJOR.$VERSION

echo -n > $OUT

echo "--# (C) Copyright IBM Corp. 2020 All Rights Reserved." >> $OUT
echo "--# SPDX-License-Identifier: Apache-2.0" >> $OUT
echo ''  >> $OUT
echo "--# db-library version  $MAJOR.$VERSION" >> $OUT
echo ''  >> $OUT
echo '/*' >> $OUT
cat known_issues.txt >> $OUT
echo '*/' >> $OUT

echo "SET SCHEMA           DB @  -- You can install in any schema you like. DB is not a bad one to choose, but up to you " >> $OUT
echo "SET PATH=SYSTEM PATH,DB @  -- change it in the path too, if you do change it" >> $OUT
echo >> $OUT
echo "CREATE OR REPLACE VARIABLE DB_VERSION DECIMAL(6,3) DEFAULT $MAJOR.$VERSION @" >> $OUT
echo >> $OUT

cat $OUT >  ${OUT/.sql/}.db2_11.1.sql

echo "--GRANT SELECTIN ON SCHEMA DB TO PUBLIC @  -- optional only supported in Db2 Warehouse currently" >> $OUT
echo >> $OUT

echo adding variables
for f in variables/*.sql
do
   tail -n +3 $f   >> $OUT
   tail -n +3 $f   >> ${OUT/.sql/}.db2_11.1.sql
done
echo "" >> $OUT

echo adding scalar_functions
for f in scalar_functions/*.sql
do
#   echo "-- $f" >> $OUT
   tail -n +3 $f   >> $OUT
   echo ''  >> $OUT
   echo '@' >> $OUT
   tail -n +3 $f | sed -re 's/(\s+)(ALLOW PARALLEL)(\s*)/\1\/*\2*\/\3/g' |  sed -re 's/(\/\*[1-9][1-9]\.[0-9]\.[0-9]\*\/)/--\1/g' >> ${OUT/.sql/}.db2_11.1.sql
   echo ''  >> ${OUT/.sql/}.db2_11.1.sql
   echo '@' >> ${OUT/.sql/}.db2_11.1.sql
done

# List files in reverse order to allow
#  some views to reference others with the same prefix

F=$(ls -1 -r views/*.sql)
for f in $F
do
   tail -n +3  $f   >> $OUT
   echo ''  >> $OUT
   echo '@' >> $OUT
   if [ ! "${f#views/}" = "db_external_tables.sql" ]; then
       tail -n +3  $f  | sed -re 's/(\/\*[1-9][1-9]\.[0-9]\.[0-9]\*\/)/--\1/g'  >> ${OUT/.sql/}.db2_11.1.sql
       echo ''  >> ${OUT/.sql/}.db2_11.1.sql
       echo '@' >> ${OUT/.sql/}.db2_11.1.sql
   fi
done



# build the comments by taking the 5th line of each file and putting them into a COMMENT ON statement
cat /dev/null > comments.sql
cd views
for f in *.sql
do
     t=${f%.sql}
     c=$(tail -n +5 $f | head -1 | cut -b 4- | sed -re "s/'/''/")
     echo "COMMENT ON TABLE ${t^^} IS '$c' @" >> ../comments.sql
done
cd ../scalar_functions
for f in *.sql
do
     t=${f%.sql}
     c=$(tail -n +5 $f | head -1 | cut -b 4- | sed -re "s/'/''/")
     echo "COMMENT ON FUNCTION ${t^^} IS '$c' @" >> ../comments.sql
done
cd ..
echo "
COMMENT ON VARIABLE DB_DIAG_FROM_TIMESTAMP        IS 'Limits rows returned in DB_DIAG to entries more recent than this value' @
COMMENT ON VARIABLE DB_DIAG_TO_TIMESTAMP          IS 'Limits rows returned in DB_DIAG to entries older than this value'       @
COMMENT ON VARIABLE DB_DIAG_MEMBER                IS 'Limits rows returned in DB_DIAG to entries from this member. -1 = current member. -2 = all members' @
" >> comments.sql

# add the comments
cat comments.sql >> $OUT
cat comments.sql | sed -re 's/^(COMMENT ON TABLE DB_EXTERNAL_TABLES)/--\1/g'  >> ${OUT/.sql/}.db2_11.1.sql
rm  comments.sql

# now cat dbx_procs such as dbx_uninstall

# build a version of the views that will run against tables in the current schema named the same as the catalog views and mon functions
cat $OUT                      | sed -re 's/((SYSCAT|SYSIBMADM|SYSTOOLS))\./\/*\1*\//ig' | sed -re 's/(TABLE\()(((MON)|(ADMIN))[A-Z\_]*)\s*(\(.*?\)?\))/\/*\1*\/\2\/*\6*\//ig' > ${OUT/.sql/}.snapshot.sql
cat ${OUT/.sql/}.db2_11.1.sql | sed -re 's/((SYSCAT|SYSIBMADM|SYSTOOLS))\./\/*\1*\//ig' | sed -re 's/(TABLE\()(((MON)|(ADMIN))[A-Z\_]*)\s*(\(.*?\)?\))/\/*\1*\/\2\/*\6*\//ig' > ${OUT/.sql/}.snapshot.db2_11.1.sql

## override the couple of views that need to be coded differently to get OK performance from the snapshot tables
for f in offline/*/*.sql
do
    cat $f >> ${OUT/.sql/}.snapshot.sql
    cat $f >> ${OUT/.sql/}.snapshot.db2_11.1.sql
done

## Now build the docs by again taking the 5th line

echo "
# A Library of useful Db2 Views, Compound Statements, SQL User Defined Functions and Procedures.

[Readme](README.md)

- [Compound Statements](#compound_statements)
- [Procedures](#procedures)
- [Functions](#functions)
- [Views](#views)


- [DB2 Catalog Poster](images/db2-syscat-11.5.2.0.png)
- [DB2 WLM Poster](images/db2-wlm-syscat-11.5.4.0.png)

"  > ${DOCS}

echo -n "
## [Compound Statements](compound_statements)
| Compound Statement | Description
| ------------ | -------------
"  >> $DOCS
cd compound_statements
for f in *.sql; do echo -n "|[${f%.sql}](compound_statements/$f)|"; echo -n "$(head -n 5 $f | tail -1 | cut -b 4-150)"; echo "|" ; done >> ../${DOCS}
cd ..
echo -n "
## [Procedures](procedures)
|  Procedures | Description
| ----------- | -------------
"  >> ${DOCS}
cd procedures
for f in *.sql; do echo -n "|[${f%.sql}](procedures/$f)|"; echo -n "$(head -n 5 $f | tail -1 | cut -b 4-150)"; echo "|" ; done >> ../${DOCS}
cd ..
echo >> ${DOCS}
echo -n "
## [Functions](scalar_functions)
| Function | Description
| ------------ | -------------
"  >> ${DOCS}
cd scalar_functions
for f in *.sql; do echo -n "|[${f%.sql}](scalar_functions/$f)|"; echo -n "$(head -n 5 $f | tail -1 | cut -b 4-150)"; echo "|" ; done >> ../${DOCS}
cd ..

echo >> ${DOCS}
echo -n "
## [Views](views)
| View | Description
| ------------ | -------------
"  >> ${DOCS}
cd views
for f in *.sql; do echo -n "|[${f%.sql}](views/$f)|"; echo -n "$(head -n 5 $f | tail -1 | cut -b 4-150)"; echo "|" ; done >> ../${DOCS}
cd ..

