#!/usr/bin/perl
########################################################################
# (c) Copyright IBM Corp. 2007 All rights reserved.
# 
# The following sample of source code ("Sample") is owned by International 
# Business Machines Corporation or one of its subsidiaries ("IBM") and is 
# copyrighted and licensed, not sold. You may use, copy, modify, and 
# distribute the Sample in any form without payment to IBM, for the purpose of 
# assisting you in the development of your applications.
# 
# The Sample code is provided to you on an "AS IS" basis, without warranty of 
# any kind. IBM HEREBY EXPRESSLY DISCLAIMS ALL WARRANTIES, EITHER EXPRESS OR 
# IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. Some jurisdictions do 
# not allow for the exclusion or limitation of implied warranties, so the above 
# limitations or exclusions may not apply to you. IBM shall not be liable for 
# any damages you suffer as a result of using, copying, modifying or 
# distributing the Sample, even if IBM has been advised of the possibility of 
# such damages.
#########################################################################
# 
# SOURCE FILE NAME: tbconstr.pl 
# 
# SAMPLE: How to create, use, and drop constraints.  
# 
# SQL STATEMENTS USED: 
#         CREATE TABLE
#         ALTER TABLE
#         DROP TABLE
#         INSERT
#         SELECT
#         DELETE
#         UPDATE 
# 
# OUTPUT FILE: tbconstr.out (available in the online documentation) 
########################################################################## 
# 
# For more information on the sample programs, see the README file. 
# 
# For information on developing Perl applications, see the Application 
# Development Guide. 
# 
# For information on using SQL statements, see the SQL Reference. 
# 
# For the latest information on programming, building, and running DB2 
# applications, visit the DB2 application development website: 
#     http://www.software.ibm.com/data/db2/udb/ad 
########################################################################## 

select STDERR; $|=1;
select STDOUT; $|=1;

use strict;
use warnings; 
use DBI;

# access the module for DB2 Sample Utility functions
use DB2SampUtil;

# check and parse the command line arguments
# call the subroutine CmdLineArgChk from DB2SampUtil.pm
my ($database, $user, $password) = CmdLineArgChk(@ARGV);

# declare return code, statement handler, database handler
my ($rc, $sth, $dbh);

print "THIS SAMPLE SHOWS HOW TO CREATE/USE/DROP CONSTRAINTS.\n";

# connect to the database
print "\n  Connecting to database...";
$dbh = DBI->connect($database, $user, $password, {AutoCommit => 0})
         || die "Can't connect to $database: $DBI::errstr";
print "\n  Connected to database.\n"; 
 
# demonstrate how to use a 'NOT NULL' constraint 
$rc = Cn_NOT_NULL_Show(); 
 
# demonstrate how to use a 'UNIQUE' constraint 
$rc = Cn_UNIQUE_Show(); 
 
# demonstrate how to use a 'PRIMARY KEY' constraint 
$rc = Cn_PRIMARY_KEY_Show(); 
 
# demonstrate how to use a 'CHECK' constraint 
$rc = Cn_CHECK_Show(); 
 
# demonstrate how to use a 'INFORMATION' constraint 
$rc = Cn_CHECK_INFO_Show(); 
 
# demonstrate how to use a 'WITH DEFAULT' constraint 
$rc = Cn_WITH_DEFAULT_Show(); 
 
print "\n#####################################################\n". 
      "#    Create tables for FOREIGN KEY sample functions #\n". 
      "#####################################################\n"; 

# create tables for foreign key sample functions 
$rc = FK_TwoTablesCreate(); 
if($rc != 0) 
{ 
  # call the subroutine TransRollback from DB2SampUtil.pm 
  TransRollback($dbh);  
  return $rc; 
} 
# demonstrate how to insert into a foreign key
$rc = Cn_FK_OnInsertShow(); 
 
# demonstrate how to use an 'ON UPDATE NO ACTION' foreign key 
$rc = Cn_FK_ON_UPDATE_NO_ACTION_Show(); 
 
# demonstrate how to use an 'ON UPDATE RESTRICT' foreign key 
$rc = Cn_FK_ON_UPDATE_RESTRICT_Show(); 
 
# demonstrate how to use an 'ON DELETE CASCADE' foreign key 
$rc = Cn_FK_ON_DELETE_CASCADE_Show(); 
 
# demonstrate how to use an 'ON DELETE SET NULL' foreign key 
$rc = Cn_FK_ON_DELETE_SET_NULL_Show(); 
 
# demonstrate how to use an 'ON DELETE NO ACTION' foreign key 
$rc = Cn_FK_ON_DELETE_NO_ACTION_Show(); 
 
print "\n########################################################\n". 
      "# Drop tables created for FOREIGN KEY sample functions #\n". 
      "########################################################\n"; 

# drop tables created for foreign key sample functions 
$rc = FK_TwoTablesDrop(); 
if($rc != 0) 
{ 
  # call the subroutine TransRollback from DB2SampUtil.pm 
  TransRollback($dbh);  
  return $rc; 
} 
  
print"\n  Disconnecting from sample...";
$dbh->disconnect();
print"\n  Disconnected from sample.\n";
 
##########################################################################
# Description: Create two tables namely, 'deptmt' and 'empl' and insert data 
#              into them
# Input      : None
# Output     : Returns 0 on success 
########################################################################## 
sub FK_TwoTablesCreate 
{ 
  print "\n  CREATE TABLE deptmt(deptno CHAR(3) NOT NULL,\n". 
        "                    deptname VARCHAR(20),\n". 
        "                    CONSTRAINT pk_dept PRIMARY KEY(deptno))\n"; 
  $dbh->do("CREATE TABLE deptmt(deptno CHAR(3) NOT NULL, 
                              deptname VARCHAR(20), 
                              CONSTRAINT pk_dept PRIMARY KEY(deptno))") 
    || print "First table -- create : $DBI::errstr"; 
  
  print "\n  INSERT INTO deptmt VALUES('A00', 'ADMINISTRATION'),\n". 
        "                         ('B00', 'DEVELOPMENT'),\n". 
        "                         ('C00', 'SUPPORT')\n"; 
  $dbh->do("INSERT INTO deptmt VALUES('A00', 'ADMINISTRATION'),  
                                   ('B00', 'DEVELOPMENT'),  
                                   ('C00', 'SUPPORT') ") 
    || print "First table -- insert : $DBI::errstr";   
     
  print "\n  CREATE TABLE empl(empno CHAR(4),\n". 
        "                   empname VARCHAR(10),\n". 
        "                   dept_no CHAR(3))\n"; 
  $dbh->do("CREATE TABLE empl(empno CHAR(4), 
                            empname VARCHAR(10), 
                            dept_no CHAR(3))") 
    || print "Second table -- create : $DBI::errstr";                                                        
 
  print "\n  INSERT INTO empl VALUES('0010', 'Smith', 'A00'),\n". 
        "                        ('0020', 'Ngan', 'B00'),\n". 
        "                        ('0030', 'Lu', 'B00'),\n". 
        "                        ('0040', 'Wheeler', 'B00'),\n". 
        "                        ('0050', 'Burke', 'C00'),\n". 
        "                        ('0060', 'Edwards', 'C00'),\n". 
        "                        ('0070', 'Lea', 'C00')\n"; 
  $dbh->do("INSERT INTO empl VALUES('0010', 'Smith', 'A00'),  
                                  ('0020', 'Ngan', 'B00'),  
                                  ('0030', 'Lu', 'B00'),  
                                  ('0040', 'Wheeler', 'B00'),  
                                  ('0050', 'Burke', 'C00'),  
                                  ('0060', 'Edwards', 'C00'),  
                                  ('0070', 'Lea', 'C00')  ") 
    || print "Second table -- insert : $DBI::errstr";    
    
  # commit the transaction 
  $rc  = $dbh->commit 
           || print "Commit : $DBI::errstr"; 
  return 0; 
} # FK_TwoTablesCreate   
 
##########################################################################
# Description: Display the contents of the tables 'empl' and 'deptmt' 
# Input      : None
# Output     : Returns 0 on success 
########################################################################## 
sub FK_TwoTablesDisplay 
{ 
  print "\n  SELECT * FROM deptmt\n"; 
  print "    DEPTNO  DEPTNAME      \n"; 
  print "    ------- --------------\n"; 
   
  my $selectStmt = "SELECT * FROM deptmt"; 

  # declare local variables
  my ($deptno, $deptname, $empno, $empname, $dept_no);
  
  # prepare and execute the SQL statement 
  # call the subroutine PrepareExecuteSql() from DB2SampUtil.pm 
  $sth = PrepareExecuteSql($dbh, $selectStmt); 
 
  while(($deptno, $deptname) = $sth->fetchrow()) 
  { 
    printf("    %-7s %-20s\n", $deptno, $deptname); 
  } 
   
  print "\n  SELECT * FROM empl\n"; 
  print "    EMPNO EMPNAME    DEPT_NO\n"; 
  print "    ----- ---------- -------\n"; 
   
  $selectStmt = "SELECT * FROM empl";  
   
  # prepare and execute the SQL statement 
  # call the subroutine PrepareExecuteSql() from DB2SampUtil.pm 
  $sth = PrepareExecuteSql($dbh, $selectStmt); 
     
  while(($empno, $empname, $dept_no) = $sth->fetchrow()) 
  { 
    printf("    %-5s %-10s", $empno, $empname); 
    if(defined $dept_no) 
    { 
      printf(" %-3s\n", $dept_no); 
    } 
    else   
    { 
      print " -\n"; 
    } 
  } 
  return 0; 
} # FK_TwoTablesDisplay 
 
##########################################################################
# Description: Drop tables 'empl' and 'deptmt' 
# Input      : None
# Output     : Returns 0 on success 
##########################################################################     
sub FK_TwoTablesDrop 
{ 
  print "\n  DROP TABLE deptmt\n"; 
  $dbh->do("DROP TABLE deptmt") 
    || print "Drop Table deptmt: $DBI::errstr";  
     
  print "\n  DROP TABLE empl\n"; 
  $dbh->do("DROP TABLE empl") 
    || print "Drop Table empl: $DBI::errstr";         

  # commit the transaction 
  print "  COMMIT\n";
  $rc = $dbh->commit 
           || print "Commit : $DBI::errstr"; 
            
  return 0; 
} # FK_TwoTablesDrop   
 
##########################################################################
# Description: Adds a foreign key constraint
# Input      : A string specifying the rule clause for the foreign 
#              constraint
# Output     : Returns 0 on success 
##########################################################################   
sub FK_Create 
{ 
  my $ruleClause = $_[0]; 
  my $strStmt;
  if (defined $ruleClause)
  {
    print "\n  ALTER TABLE empl ADD CONSTRAINT fk_dept\n". 
          "    FOREIGN KEY(dept_no)\n". 
          "    REFERENCES deptmt(deptno)\n". 
          "    $ruleClause\n", ; 
 
    $strStmt = "ALTER TABLE empl ADD CONSTRAINT fk_dept FOREIGN KEY(dept_no)".                    
               "  REFERENCES deptmt(deptno) ".$ruleClause; 
  }
  else
  {
    print "\n  ALTER TABLE empl ADD CONSTRAINT fk_dept\n". 
          "    FOREIGN KEY(dept_no)\n". 
          "    REFERENCES deptmt(deptno)\n";
 
    $strStmt = "ALTER TABLE empl ADD CONSTRAINT fk_dept FOREIGN KEY(dept_no)".                    
               "  REFERENCES deptmt(deptno) ";
  }
	     
     
  $dbh->do($strStmt) 
    || print "Alter Table: $DBI::errstr";  
     
  # commit the transaction 
  print "  COMMIT\n"; 
  $rc  = $dbh->commit 
           || print "Commit : $DBI::errstr"; 
   
  return 0; 
} # FK_Create  
 
##########################################################################
# Description: Drops a foreign key constraint 
# Input      : None
# Output     : Returns 0 on success 
##########################################################################   
sub FK_Drop 
{ 
  print "\n  ALTER TABLE empl DROP CONSTRAINT fk_dept\n"; 
  my $strStmt = "ALTER TABLE empl DROP CONSTRAINT fk_dept "; 
 
  $dbh->do($strStmt) 
    || print "foreign key -- drop: $DBI::errstr";  
     
  # commit the transaction 
  print "  COMMIT\n"; 
  $rc  = $dbh->commit 
           || print "Commit : $DBI::errstr"; 
   
  return 0; 
} # FK_Drop  
 
##########################################################################
# Description: To show a NOT NULL constraint
# Input      : None
# Output     : Returns 0 on success 
########################################################################## 
sub Cn_NOT_NULL_Show 
{ 
  print "\n-----------------------------------------------------------"; 
  print "\nUSE THE SQL STATEMENTS:\n"; 
  print "  CREATE TABLE\n"; 
  print "  INSERT\n"; 
  print "  DROP TABLE\n"; 
  print "TO SHOW A 'NOT NULL' CONSTRAINT.\n"; 
 
  # create table  
  print "\n  CREATE TABLE empl_sal(lastname VARCHAR(10) NOT NULL,\n". 
        "                       firstname VARCHAR(10),\n". 
        "                       salary DECIMAL(7, 2))\n"; 
 
  $dbh->do("CREATE TABLE empl_sal(lastname VARCHAR(10) NOT NULL, 
                                 firstname VARCHAR(10), 
                                 salary DECIMAL(7, 2))") 
    || print "Create Table : $DBI::errstr";                               
   
  # commit the transaction 
  print "  COMMIT\n"; 
  $rc  = $dbh->commit 
           || print "Commit : $DBI::errstr"; 
   
  # insert table  
  print "\n  INSERT INTO empl_sal VALUES(NULL, 'PHILIP', 17000.00)\n"; 
  print "\n**************** Expected Error ******************\n\n"; 
  $dbh->do("INSERT INTO empl_sal VALUES(NULL, 'PHILIP', 17000.00) "); 
  print "\n**************************************************\n"; 
            
  # drop table  
  print "\n  DROP TABLE empl_sal\n"; 
 
  $dbh->do("DROP TABLE empl_sal") 
    || print "Drop : $DBI::errstr";           
     
  return 0; 
} # Cn_NOT_NULL_Show  
 
##########################################################################
# Description: To show a UNIQUE constraint
# Input      : None
# Output     : Returns 0 on success 
########################################################################## 
sub Cn_UNIQUE_Show 
{ 
  print "\n-----------------------------------------------------------"; 
  print "\nUSE THE SQL STATEMENTS:\n"; 
  print "  CREATE TABLE\n"; 
  print "  INSERT\n"; 
  print "  ALTER TABLE\n"; 
  print "  DROP TABLE\n"; 
  print "TO SHOW A 'UNIQUE' CONSTRAINT.\n"; 
 
  # create table  
  print "\n  CREATE TABLE empl_sal(lastname VARCHAR(10) NOT NULL,\n". 
        "                       firstname VARCHAR(10) NOT NULL,\n". 
        "                       salary DECIMAL(7, 2),\n". 
        "  CONSTRAINT unique_cn UNIQUE(lastname, firstname))\n"; 
 
  $dbh->do("CREATE TABLE empl_sal(lastname VARCHAR(10) NOT NULL, 
                                 firstname VARCHAR(10) NOT NULL, 
                                 salary DECIMAL(7, 2), 
              CONSTRAINT unique_cn UNIQUE(lastname, firstname))") 
    || print "Create Table : $DBI::errstr";            
   
  # commit the transaction 
  print "  COMMIT\n"; 
  $rc  = $dbh->commit 
           || print "Commit : $DBI::errstr"; 
   
  # insert table  
  print "\n  INSERT INTO empl_sal VALUES('SMITH', 'PHILIP', 17000.00),". 
        "\n                            ('SMITH', 'PHILIP', 21000.00) \n"; 
  print "\n**************** Expected Error ******************\n\n"; 
  $dbh->do("INSERT INTO empl_sal VALUES('SMITH', 'PHILIP', 17000.00),  
                                      ('SMITH', 'PHILIP', 21000.00)"); 
  print "\n**************************************************\n"; 
   
  # drop constraint  
  print "\n  ALTER TABLE empl_sal DROP CONSTRAINT unique_cn\n"; 
 
  $dbh->do("ALTER TABLE empl_sal DROP CONSTRAINT unique_cn") 
    || print "Alter Table: $DBI::errstr"; 
 
  # drop table  
  print "\n  DROP TABLE empl_sal\n"; 
 
  $dbh->do("DROP TABLE empl_sal") 
    || print "Drop Table: $DBI::errstr"; 
 
  return 0; 
} # Cn_UNIQUE_Show  
 
##########################################################################
# Description: To show a PRIMARY KEY constraint
# Input      : None
# Output     : Returns 0 on success 
########################################################################## 
sub Cn_PRIMARY_KEY_Show 
{ 
  print "\n-----------------------------------------------------------"; 
  print "\nUSE THE SQL STATEMENTS:\n"; 
  print "  CREATE TABLE\n"; 
  print "  INSERT\n"; 
  print "  ALTER TABLE\n"; 
  print "  DROP TABLE\n"; 
  print "TO SHOW A 'PRIMARY KEY' CONSTRAINT.\n"; 
 
  # create table  
  print "\n  CREATE TABLE empl_sal(lastname VARCHAR(10) NOT NULL,\n". 
        "                       firstname VARCHAR(10) NOT NULL,\n". 
        "                       salary DECIMAL(7, 2),\n". 
        "  CONSTRAINT pk_cn PRIMARY KEY(lastname, firstname))\n"; 
 
  $dbh->do("CREATE TABLE empl_sal(lastname VARCHAR(10) NOT NULL, 
                                 firstname VARCHAR(10) NOT NULL, 
                                 salary DECIMAL(7, 2), 
              CONSTRAINT pk_cn PRIMARY KEY(lastname, firstname))") 
    || print "Create Table : $DBI::errstr";    
 
  # commit the transaction 
  print "  COMMIT\n"; 
  $rc  = $dbh->commit 
           || print "Commit : $DBI::errstr"; 
 
  # insert table  
  print "\n  INSERT INTO empl_sal VALUES('SMITH', 'PHILIP', 17000.00),". 
        "\n                            ('SMITH', 'PHILIP', 21000.00) \n"; 
  print "\n**************** Expected Error ******************\n\n"; 
  $dbh->do("INSERT INTO empl_sal VALUES('SMITH', 'PHILIP', 17000.00),  
                                      ('SMITH', 'PHILIP', 21000.00)");    
  print "\n**************************************************\n"; 
    
  # drop constraint  
  print "\n  ALTER TABLE empl_sal DROP CONSTRAINT pk_cn\n"; 
 
  $dbh->do("ALTER TABLE empl_sal DROP CONSTRAINT pk_cn") 
    || print "Alter Table: $DBI::errstr"; 
 
  # drop table  
  print "\n  DROP TABLE empl_sal\n"; 
 
  $dbh->do("DROP TABLE empl_sal") 
    || print "Drop Table: $DBI::errstr"; 
 
  return 0; 
} # Cn_PRIMARY_KEY_Show  
 
##########################################################################
# Description: To show a CHECK constraint
# Input      : None
# Output     : Returns 0 on success 
########################################################################## 
sub Cn_CHECK_Show 
{ 
  print "\n-----------------------------------------------------------"; 
  print "\nUSE THE SQL STATEMENTS:\n"; 
  print "  CREATE TABLE\n"; 
  print "  INSERT\n"; 
  print "  ALTER TABLE\n"; 
  print "  DROP TABLE\n"; 
  print "TO SHOW A 'CHECK' CONSTRAINT.\n"; 
 
  # create table  
  print "\n  CREATE TABLE empl_sal(lastname VARCHAR(10),\n". 
        "                       firstname VARCHAR(10),\n". 
        "                       salary DECIMAL(7, 2),\n". 
        "    CONSTRAINT check_cn CHECK(salary < 25000.00))\n"; 
 
  $dbh->do("CREATE TABLE empl_sal(lastname VARCHAR(10), 
                                 firstname VARCHAR(10), 
                                 salary DECIMAL(7, 2), 
              CONSTRAINT check_cn CHECK(salary < 25000.00))") 
    || print "Create Table : $DBI::errstr";    
 
  # commit the transaction 
  print "  COMMIT\n"; 
  $rc  = $dbh->commit 
           || print "Commit : $DBI::errstr"; 
 
  # insert table  
  print "\n  INSERT INTO empl_sal VALUES('SMITH', 'PHILIP', 27000.00)\n"; 
  print "\n**************** Expected Error ******************\n\n"; 
  $dbh->do("INSERT INTO empl_sal VALUES('SMITH', 'PHILIP', 27000.00)"); 
  print "\n**************************************************\n"; 
   
  # drop constraint  
  print "\n  ALTER TABLE empl_sal DROP CONSTRAINT check_cn\n"; 
 
  $dbh->do("ALTER TABLE empl_sal DROP CONSTRAINT check_cn") 
    || print "Alter Table: $DBI::errstr"; 
 
  # drop table  
  print "\n  DROP TABLE empl_sal\n"; 
 
  $dbh->do("DROP TABLE empl_sal") 
    || print "Drop Table: $DBI::errstr"; 
 
  return 0; 
} # Cn_CHECK_Show  
 
##########################################################################
# Description: To show an INFORMATIONAL constraint
# Input      : None
# Output     : Returns 0 on success 
########################################################################## 
sub Cn_CHECK_INFO_Show 
{ 
  print "\n-----------------------------------------------------------"; 
  print "\nUSE THE SQL STATEMENTS:\n"; 
  print "  CREATE TABLE\n"; 
  print "  INSERT\n"; 
  print "  ALTER TABLE\n"; 
  print "  DROP TABLE\n"; 
  print "TO SHOW AN 'INFORMATIONAL' CONSTRAINT.\n"; 
 
  # create table  
  print "\n  CREATE TABLE empl(empno INTEGER NOT NULL PRIMARY KEY,\n". 
        "                   name VARCHAR(10),\n". 
        "                   firstname VARCHAR(20),\n". 
        "                   salary INTEGER CONSTRAINT minsalary\n". 
        "                          CHECK (salary >= 25000)\n". 
        "                          NOT ENFORCED\n". 
        "                          ENABLE QUERY OPTIMIZATION)\n"; 
 
  $dbh->do("CREATE TABLE empl(empno INTEGER NOT NULL PRIMARY KEY, 
                             name VARCHAR(10), 
                             firstname VARCHAR(20), 
                             salary INTEGER CONSTRAINT minsalary 
                                    CHECK (salary >= 25000) 
                                    NOT ENFORCED 
                                    ENABLE QUERY OPTIMIZATION)") 
    || print "Create Table: $DBI::errstr";                                   
 
  # commit the transaction 
  print "  COMMIT\n"; 
  $rc = $dbh->commit 
          || print "Commit : $DBI::errstr"; 
 
  # insert data that doesn't satisfy the constraint 'minsalary'. 
  # database manager does not enforce the constraint for IUD operations  
  print "\n\nTO SHOW NOT ENFORCED OPTION\n"; 
  print "\n  INSERT INTO empl VALUES(1, 'SMITH', 'PHILIP', 1000)\n\n"; 
  $dbh->do("INSERT INTO empl VALUES(1, 'SMITH', 'PHILIP', 1000)") 
    || print "Insert : $DBI::errstr"; 
 
  # alter the constraint to make it ENFORCED by database manager  
  print "Alter the constraint to make it ENFORCED by database manager\n"; 
  print "\n  ALTER TABLE empl ALTER CHECK minsalary ENFORCED\n"; 
  print "\n**************** Expected Error ******************\n\n"; 
  $dbh->do("ALTER TABLE empl ALTER CHECK minsalary ENFORCED"); 
  print "\n**************************************************\n"; 
 
  # delete entries from EMPL Table  
  print "\n  DELETE FROM empl\n"; 
  $dbh->do("DELETE FROM empl") 
    || print " Delete : $DBI::errstr"; 
 
  # alter the constraint to make it ENFORCED by database manager  
  print "\n\nTO SHOW ENFORCED OPTION\n"; 
  print "\n  ALTER TABLE empl ALTER CHECK minsalary ENFORCED\n"; 
  $dbh->do("ALTER TABLE empl ALTER CHECK minsalary ENFORCED") 
    || print" Alter Table : $DBI::errstr"; 
 
  # insert table with data not conforming to the constraint 'minsalary' 
  # database manager does not enforce the constraint for IUD operations  
  print "\n  INSERT INTO empl VALUES(1, 'SMITH', 'PHILIP', 1000)\n"; 
  print "\n**************** Expected Error ******************\n\n"; 
  $dbh->do("INSERT INTO empl VALUES(1, 'SMITH', 'PHILIP', 1000)"); 
  print "\n**************************************************\n"; 
   
  # drop table  
  print "\n  DROP TABLE empl\n"; 
  $dbh->do("DROP TABLE empl") 
    || print "Drop Table : $DBI::errstr"; 
 
  return 0; 
} # Cn_CHECK_INFO_Show  
 
##########################################################################
# Description: To show a WITH DEFAULT constraint
# Input      : None
# Output     : Returns 0 on success 
########################################################################## 
sub Cn_WITH_DEFAULT_Show 
{ 
  # declare local variables
  my ($firstname, $lastname, $salary);

  print "\n-----------------------------------------------------------"; 
  print "\nUSE THE SQL STATEMENTS:\n"; 
  print "  CREATE TABLE\n"; 
  print "  INSERT\n"; 
  print "  DROP TABLE\n"; 
  print "TO SHOW A 'WITH DEFAULT' CONSTRAINT.\n"; 
 
  # create table    
  printf("\n  CREATE TABLE empl_sal(lastname VARCHAR(10),\n". 
         "                       firstname VARCHAR(10),\n". 
         "                       ". 
         "salary DECIMAL(7, 2) WITH DEFAULT 17000.00)\n"); 
  $dbh->do("CREATE TABLE empl_sal(lastname VARCHAR(10), 
                                firstname VARCHAR(10), 
                                salary DECIMAL(7, 2) WITH DEFAULT 17000.00)") 
    || print "Create Table : $DBI::errstr";  
 
  # commit the transaction 
  print "  COMMIT\n"; 
  $rc  = $dbh->commit 
           || print "Commit : $DBI::errstr"; 
 
  # insert table    
  print "\n  INSERT INTO empl_sal(lastname, firstname)\n". 
        "    VALUES('SMITH', 'PHILIP'),\n". 
        "          ('PARKER', 'JOHN'),\n". 
        "          ('PEREZ', 'MARIA')\n"; 
 
  $dbh->do("INSERT INTO empl_sal(lastname, firstname)  
              VALUES('SMITH' , 'PHILIP'),  
                    ('PARKER', 'JOHN'),  
                    ('PEREZ' , 'MARIA') ") 
    || print "Insert : $DBI::errstr"; 
   
  # display table    
  print "\n  SELECT * FROM empl_sal\n"; 
 
  print "    FIRSTNAME  LASTNAME   SALARY  \n"; 
  print "    ---------- ---------- --------\n"; 
 
  my $strStmt = "SELECT * FROM empl_sal"; 
   
  # prepare and execute the SQL statement 
  # call the subroutine PrepareExecuteSql() from DB2SampUtil.pm 
  $sth = PrepareExecuteSql($dbh, $strStmt); 
  
  while (($firstname, $lastname, $salary) = $sth->fetchrow()) 
  { 
    printf("    %-10s %-10s %-7.2f\n", $firstname, $lastname, $salary); 
  } 
 
  # drop table    
  print "\n  DROP TABLE empl_sal\n"; 
 
  $dbh->do("DROP TABLE empl_sal") 
    || print "Drop Table : $DBI::errstr";  
  
  return 0; 
} # Cn_WITH_DEFAULT_Show    
 
##########################################################################
# Description: To show how a FOREIGN KEY works on INSERT
# Input      : None
# Output     : Returns 0 on success 
########################################################################## 
sub Cn_FK_OnInsertShow 
{ 
  print "\n-----------------------------------------------------------"; 
  print "\nUSE THE SQL STATEMENTS:\n"; 
  print "  ALTER TABLE\n"; 
  print "  INSERT\n"; 
  print "TO SHOW HOW A FOREIGN KEY WORKS ON INSERT.\n"; 
 
  # display initial tables content    
  $rc = FK_TwoTablesDisplay(); 
 
  # create foreign key    
  $rc = FK_Create(); 
 
  # insert parent table    
  print "\n  INSERT INTO deptmt VALUES('D00', 'SALES')\n"; 
  $dbh->do("INSERT INTO deptmt VALUES('D00', 'SALES') ") 
    || print "Insert : $DBI::errstr"; 
 
  # insert child table    
  print "\n  INSERT INTO empl VALUES('0080', 'Pearce', 'E03')\n"; 
  print "\n**************** Expected Error ******************\n\n"; 
  $dbh->do("INSERT INTO empl VALUES('0080', 'Pearce', 'E03') "); 
  print "\n**************************************************\n"; 
 
  # display final tables' contents    
  $rc = FK_TwoTablesDisplay(); 
 
  # rollback transaction    
  print "\n  ROLLBACK\n"; 
  my $rv = $dbh->rollback
             || die "The transaction couldn't be rolled back: $DBI::errstr"; 
   
  # drop foreign key    
  $rc = FK_Drop(); 
 
  return 0; 
} # Cn_FK_OnInsertShow  
   
##########################################################################
# Description: To show an 'ON UPDATE NO ACTION' FOREIGN KEY
# Input      : None
# Output     : Returns 0 on success 
########################################################################## 
sub Cn_FK_ON_UPDATE_NO_ACTION_Show 
{ 
  print "\n-----------------------------------------------------------"; 
  print "\nUSE THE SQL STATEMENTS:\n"; 
  print "  ALTER TABLE\n"; 
  print "  UPDATE\n"; 
  print "TO SHOW AN 'ON UPDATE NO ACTION' FOREIGN KEY.\n"; 
 
  # display initial tables content    
  $rc = FK_TwoTablesDisplay(); 
 
  # create foreign key    
  $rc = FK_Create("ON UPDATE NO ACTION"); 
 
  # update parent table    
  print "\n  UPDATE deptmt SET deptno = 'E01' WHERE deptno = 'A00'\n"; 
  print "\n**************** Expected Error ******************\n\n"; 
  $dbh->do("UPDATE deptmt SET deptno = 'E01' WHERE deptno = 'A00' "); 
  print "\n**************************************************\n"; 
   
  print "\n  UPDATE deptmt SET deptno =\n". 
        "    CASE\n". 
        "      WHEN deptno = 'A00' THEN 'B00'\n". 
        "      WHEN deptno = 'B00' THEN 'A00'\n". 
        "    END\n". 
        "    WHERE deptno = 'A00' OR deptno = 'B00'\n"; 
 
  $dbh->do("UPDATE deptmt SET deptno =  
              CASE  
                WHEN deptno = 'A00' THEN 'B00'  
                WHEN deptno = 'B00' THEN 'A00'  
              END  
              WHERE deptno = 'A00' OR deptno = 'B00' ") 
    || print "Update : $DBI::errstr";             
 
  # update child table    
  print "\n  UPDATE empl SET dept_no = 'G11' WHERE empname = 'Wheeler'\n"; 
  print "\n**************** Expected Error ******************\n\n"; 
  $dbh->do("UPDATE empl SET dept_no = 'G11' WHERE empname = 'Wheeler' "); 
  print "\n**************************************************\n"; 
   
  # display final tables' contents    
  $rc = FK_TwoTablesDisplay(); 
 
  # rollback transaction    
  print "\n  ROLLBACK\n"; 
  my $rv = $dbh->rollback
             || die "The transaction couldn't be rolled back: $DBI::errstr"; 
     
  # drop foreign key    
  $rc = FK_Drop(); 
 
  return 0; 
} # Cn_FK_ON_UPDATE_NO_ACTION_Show    
 
##########################################################################
# Description: To show an 'ON UPDATE RESTRICT' FOREIGN KEY
# Input      : None
# Output     : Returns 0 on success 
########################################################################## 
sub Cn_FK_ON_UPDATE_RESTRICT_Show 
{ 
  print "\n-----------------------------------------------------------"; 
  print "\nUSE THE SQL STATEMENTS:\n"; 
  print "  ALTER TABLE\n"; 
  print "  UPDATE\n"; 
  print "TO SHOW AN 'ON UPDATE RESTRICT' FOREIGN KEY.\n"; 
 
  # display initial tables content    
  $rc = FK_TwoTablesDisplay(); 
 
  # create foreign key    
  $rc = FK_Create("ON UPDATE RESTRICT"); 
 
  # update parent table    
  print "\n  UPDATE deptmt SET deptno = 'E01' WHERE deptno = 'A00'\n"; 
  print "\n**************** Expected Error ******************\n\n"; 
  $dbh->do("UPDATE deptmt SET deptno = 'E01' WHERE deptno = 'A00' "); 
  print "\n**************************************************\n"; 
   
  print "\n  UPDATE deptmt SET deptno =\n". 
        "    CASE\n". 
        "      WHEN deptno = 'A00' THEN 'B00'\n". 
        "      WHEN deptno = 'B00' THEN 'A00'\n". 
        "    END\n". 
        "    WHERE deptno = 'A00' OR deptno = 'B00'\n"; 
  print "\n**************** Expected Error ******************\n\n"; 
  $dbh->do("UPDATE deptmt SET deptno =  
              CASE  
                WHEN deptno = 'A00' THEN 'B00'  
                WHEN deptno = 'B00' THEN 'A00'  
              END  
                WHERE deptno = 'A00' OR deptno = 'B00' "); 
  print "\n**************************************************\n"; 
   
  # update child table    
  print "\n  UPDATE empl SET dept_no = 'G11' WHERE empname = 'Wheeler'\n"; 
  print "\n**************** Expected Error ******************\n\n"; 
  $dbh->do("UPDATE empl SET dept_no = 'G11' WHERE empname = 'Wheeler' "); 
  print "\n**************************************************\n"; 
   
  # display final tables' contents    
  $rc = FK_TwoTablesDisplay(); 
 
  # rollback transaction    
  print "\n  ROLLBACK\n"; 
  my $rv = $dbh->rollback
             || die "The transaction couldn't be rolled back: $DBI::errstr"; 
 
  # drop foreign key    
  $rc = FK_Drop(); 
 
  return 0; 
} # Cn_FK_ON_UPDATE_RESTRICT_Show    
 
##########################################################################
# Description: To show an 'ON DELETE CASCADE' FOREIGN KEY
# Input      : None
# Output     : Returns 0 on success 
########################################################################## 
sub Cn_FK_ON_DELETE_CASCADE_Show 
{ 
  print "\n-----------------------------------------------------------"; 
  print "\nUSE THE SQL STATEMENTS:\n"; 
  print "  ALTER TABLE\n"; 
  print "  DELETE\n"; 
  print "TO SHOW AN 'ON DELETE CASCADE' FOREIGN KEY.\n"; 
 
  # display initial tables content    
  $rc = FK_TwoTablesDisplay(); 
 
  # create foreign key    
  $rc = FK_Create("ON DELETE CASCADE"); 
 
  # delete parent table    
  print "\n  DELETE FROM deptmt WHERE deptno = 'C00'\n"; 
  $dbh->do("DELETE FROM deptmt WHERE deptno = 'C00'") 
    || print "Delete : $DBI::errstr"; 
    
  # display tables' contents    
  $rc = FK_TwoTablesDisplay(); 
 
  # delete child table    
  print "\n  DELETE FROM empl WHERE empname = 'Wheeler'\n"; 
  $dbh->do("DELETE FROM empl WHERE empname = 'Wheeler'") 
    || print "Delete : $DBI::errstr"; 
   
  # display final tables' contents    
  $rc = FK_TwoTablesDisplay(); 
 
  # rollback transaction    
  print "\n  ROLLBACK\n"; 
  my $rv = $dbh->rollback
             || die "The transaction couldn't be rolled back: $DBI::errstr"; 
     
  # drop foreign key    
  $rc = FK_Drop(); 
 
  return 0; 
} # Cn_FK_ON_DELETE_CASCADE_Show    
 
##########################################################################
# Description: To show an 'ON DELETE SET NULL' FOREIGN KEY
# Input      : None
# Output     : Returns 0 on success 
########################################################################## 
sub Cn_FK_ON_DELETE_SET_NULL_Show 
{   
  print "\n-----------------------------------------------------------"; 
  print "\nUSE THE SQL STATEMENTS:\n"; 
  print "  ALTER TABLE\n"; 
  print "  COMMIT\n"; 
  print "  DELETE\n"; 
  print "TO SHOW AN 'ON DELETE SET NULL' FOREIGN KEY.\n"; 
 
  # display initial tables content    
  $rc = FK_TwoTablesDisplay(); 
 
  # create foreign key    
  $rc = FK_Create("ON DELETE SET NULL"); 
 
  # delete parent table    
  print "\n  DELETE FROM deptmt WHERE deptno = 'C00'\n"; 
  $dbh->do("DELETE FROM deptmt WHERE deptno = 'C00'") 
    || print "Delete : $DBI::errstr"; 
 
  # display tables' contents    
  $rc = FK_TwoTablesDisplay(); 
 
  # delete child table    
  print "\n  DELETE FROM empl WHERE empname = 'Wheeler'\n"; 
  $dbh->do("DELETE FROM empl WHERE empname = 'Wheeler'") 
    || print "Delete : $DBI::errstr"; 
   
  # display final tables' contents    
  $rc = FK_TwoTablesDisplay(); 
 
  # rollback transaction    
  print "\n  ROLLBACK\n"; 
  my $rv = $dbh->rollback
             || die "The transaction couldn't be rolled back: $DBI::errstr"; 
   
  # drop foreign key    
  $rc = FK_Drop(); 
 
  return 0; 
} # Cn_FK_ON_DELETE_SET_NULL_Show    
 
##########################################################################
# Description: To show an 'ON DELETE NO ACTION' FOREIGN KEY
# Input      : None
# Output     : Returns 0 on success 
########################################################################## 
sub Cn_FK_ON_DELETE_NO_ACTION_Show 
{ 
  print "\n-----------------------------------------------------------"; 
  print "\nUSE THE SQL STATEMENTS:\n"; 
  print "  ALTER TABLE\n"; 
  print "  DELETE\n"; 
  print "TO SHOW AN 'ON DELETE NO ACTION' FOREIGN KEY.\n"; 
 
  # display initial tables content    
  $rc = FK_TwoTablesDisplay(); 
 
  # create foreign key    
  $rc = FK_Create("ON DELETE NO ACTION"); 
 
  # delete parent table    
  print "\n  DELETE FROM deptmt WHERE deptno = 'C00'\n"; 
  print "\n**************** Expected Error ******************\n\n"; 
  $dbh->do("DELETE FROM deptmt WHERE deptno = 'C00' "); 
  print "\n**************************************************\n"; 
   
  # delete child table    
  print "  \n  DELETE FROM empl WHERE empname = 'Wheeler'\n"; 
  $dbh->do("DELETE FROM empl WHERE empname = 'Wheeler' ") 
    || print "Delete: $DBI::errstr"; 
   
  # display final tables' contents    
  $rc = FK_TwoTablesDisplay(); 
 
  # rollback transaction    
  print "\n  ROLLBACK\n"; 
  my $rv = $dbh->rollback
             || die "The transaction couldn't be rolled back: $DBI::errstr"; 
     
  # drop foreign key    
  $rc = FK_Drop(); 
 
  return 0; 
} # Cn_FK_ON_DELETE_NO_ACTION_Show    
