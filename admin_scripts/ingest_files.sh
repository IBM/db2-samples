#! /bin/bash


#---------------------------------------------------------------------------
# (c) Copyright IBM Corp. 2010 All rights reserved.
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
#---------------------------------------------------------------------------

# -----------------------------------------------------------------------------------------------------------------------
# TITLE: Ingest utility sample script
#
# SAMPLE FILE NAME: ingest_files.sh
#
# PURPOSE: This sample demonstrates ingesting data from files into a single target table with the INGEST utility. This
#          sample script is a shell script that generates and runs an INGEST command each time there are files to process.
#
# USAGE SCENARIO: This sample demonstrates the ongoing processing of files as they appear in a directory and ingesting data from
#                 the file into a target table in the database.
#
#                 The script continuously monitors a directory for the appearance of new input files for the ingest utility.
#                 Because files might appear in the directory before they are completely copied, the script waits for files with
#                 an extension of ".done".  When it sees such a file, it assumes that an input file with the specified name but
#                 without the ".done" extension is complete and runs the INGEST command using that file as input.  For example,
#                 when the script sees a file named "myFile.csv.done", it assumes that input file "myFile.csv" is complete and
#                 runs the INGEST command using that file as input.
#
#                 The ".done" files and input files are moved to a SUCCESS directory if the INGEST
#                 was successful; else the files are moved to a FAILED directory. The script also creates two log files:
#                 ingest_files.log that stores information messages (preceded by [INFO]), error messages (preceded by
#                 [ERROR]) if any of all the operations and all the INGEST commands i.e both the successful ones and the failed
#                 ones; failed_ingest.log stores information about all the failed INGEST commands.
#
# PREREQUISITES: This sample needs a table MY_SCHEMA.MY_TABLE that needs to be setup with two integer columns
#                db2 "CREATE TABLE MY_SCHEMA.MY_TABLE (COL1 INTEGER, COL2 INTEGER)"
#                This sample requires input data files that contains two integer fields in each row separated by a comma.
#                Replace the sample values provided in section 2 with appropriate values.
#                * INPUT_FILES_DIRECTORY: specifies the directory to look for the data files
#                * DATABASE_NAME: specifies the database name containing the target table
#                * SCHEMA_NAME: specifies the schema name
#                * TABLE_NAME: specifies the name of the target table
#                * MAIL_USER_NAME: specifies the user name who has to be notified through mail about the failed INGEST
#                                  commands
#
# EXECUTION: chmod +x ingest_files.sh
#            ./ingest_files.sh <USER_NAME> <PASSWORD>
#
# INPUTS: 1) USER_NAME
#         2) PASSWORD
#
# OUTPUT: This sample does not generate any output on the standard output. Check the log ingest_files.log created at
#         <SCRIPT_PATH>/logs/ingest_files.log
#
# ----------------------------------------------------------------------------------------------------------------------


# --------------------------------------------------------------------------------------------------------------------- #
# --------------------------------------------------------------------------------------------------------------------- #
#                                       SECTION 1: HANDLE COMMAND LINE ARGUMENTS                                        #
# --------------------------------------------------------------------------------------------------------------------- #
# --------------------------------------------------------------------------------------------------------------------- #

# ----------
# check the command line arguments
# ----------

if [ $# -ne 2 ]
then
    echo -e "INVALID number of arguments"
    echo -e "Enter two arguments: USER_NAME and PASSWORD"
    exit 1
fi

# ----------
# assign the command line arguments to shell variables
# ----------

USER_NAME=$1
PASSWORD=$2

# ----------
# check if user name and password is non-blank
# ----------

# if user name or password is blank
if [ ! -n "$USER_NAME" -o ! -n "$PASSWORD" ]
then
    echo -e "username/password cannot be blank"
    exit 1
fi

# --------------------------------------------------------------------------------------------------------------------- #
#                                                  END OF SECTION 1                                                     #
# --------------------------------------------------------------------------------------------------------------------- #

# --------------------------------------------------------------------------------------------------------------------- #
# --------------------------------------------------------------------------------------------------------------------- #
#                            SECTION 2: INPUT VALUES                                                                    #
#                            (SAMPLE VALUES, TO BE REPLACED BY THE USER OR                                              #
#                            GOTTEN FROM THE $INGEST_FILE_... ENVIRONMENT VARIABLES SHOWN BELOW)                        #
# --------------------------------------------------------------------------------------------------------------------- #
# --------------------------------------------------------------------------------------------------------------------- #

# path to search for the data files
INPUT_FILES_DIRECTORY="$INGEST_FILES_DIRECTORY"
#INPUT_FILES_DIRECTORY="<provide your value>"
# example: INPUT_FILES_DIRECTORY="/home/data"

# database name
DATABASE_NAME="$INGEST_FILES_DB"
#DATABASE_NAME="<provide your value>"
# example: DATABASE_NAME="OLAPDB"

# schema name
SCHEMA_NAME="$INGEST_FILES_SCHEMA"
#SCHEMA_NAME="<provide your value>"
# example: SCHEMA_NAME="MY_SCHEMA"

# target table name
TABLE_NAME="$INGEST_FILES_TABLE"
#TABLE_NAME="<provide your value>"
# example: TABLE_NAME="MY_TABLE"

# user name of the user who has to be notified through mail about the failed INGEST commands
MAIL_USER_NAME="$INGEST_FILES_USER"

# ----------
# get the script path
# ----------

SCRIPT_PATH="$( dirname "$( which "$0" )" )"

# --------------------------------------------------------------------------------------------------------------------- #
#                                                  END OF SECTION 2                                                     #
# --------------------------------------------------------------------------------------------------------------------- #


# --------------------------------------------------------------------------------------------------------------------- #
# --------------------------------------------------------------------------------------------------------------------- #
#                                              SECTION 3: INGEST COMMAND DETAILS                                        #
# --------------------------------------------------------------------------------------------------------------------- #
# --------------------------------------------------------------------------------------------------------------------- #

# This script generates an ingest command using the two parts sepcified below as well as the name of a file to be processed
# INGEST COMMAND DETAILS_PART1="FORMAT <provide your format clause> MESSAGES ${SCRIPT_PATH}/messages.txt RESTART NEW"
INGEST_COMMAND_DETAILS_PART1="FORMAT DELIMITED (\$field1 INTEGER EXTERNAL, \$field2 INTEGER EXTERNAL) MESSAGES ${SCRIPT_PATH}/messages.txt RESTART NEW"

# INGEST_COMMAND_DETAILS_PART2="<provide your INSERT or other SQL clause> ${SCHEMA_NAME}.${TABLE_NAME} VALUES <provide your values clause>"
INGEST_COMMAND_DETAILS_PART2="INSERT INTO ${SCHEMA_NAME}.${TABLE_NAME} VALUES (\$field1, \$field2)"

# --------------------------------------------------------------------------------------------------------------------- #
#                                                  END OF SECTION 3                                                     #
# --------------------------------------------------------------------------------------------------------------------- #


# --------------------------------------------------------------------------------------------------------------------- #
# --------------------------------------------------------------------------------------------------------------------- #
#                            SECTION 4: SETUP ENVIRONMENT, LOGS, SUCCESS AND FAILED DIRECTORIES                         #
# --------------------------------------------------------------------------------------------------------------------- #
# --------------------------------------------------------------------------------------------------------------------- #

# ----------
# create a logs directory in the same path as the script, if it already does not exist
# ----------

# if the logs directory does not exist at the SCRIPT_PATH, then create a logs directory
if [ ! -d ${SCRIPT_PATH}/logs ]
then
    mkdir ${SCRIPT_PATH}/logs
    # if mkdir fails then echo to stdout and exit
    if [ $? -ne 0 ]
    then
        echo "unable to create logs directory at $SCRIPT_PATH"
        exit 1
    fi
fi

# ----------
# create the log files if it already does not exist in the logs directory created above
# ----------

# two log files are created
# ingest_files.log: stores informational and error messages pertaining to the script. It stores information from all commands - failed or successful
# failed_ingest.log: stores information only about all the failed INGEST commands

LOGFILE=${SCRIPT_PATH}/logs/ingest_files.log
FAILEDINGESTLOG=${SCRIPT_PATH}/logs/failed_ingest.log

# if the log file does not exist in the LOGS directory, then create a logfile named ingest_files.log
if [ ! -f $LOGFILE ]
then
    time=`date`
    touch $LOGFILE
    echo -e "-------------------------------------------------------------------------------------------------------------------------------" >>$LOGFILE
    echo -e "----------                                              INGEST SCRIPT LOG                                            ----------" >>$LOGFILE
    echo -e "-------------------------------------------------------------------------------------------------------------------------------" >>$LOGFILE
    echo -e $time"  [INFO]  log file $LOGFILE created" >>$LOGFILE
fi

# if the log file does not exist in the LOGS directory, then create a logfile named failed_ingest.log
if [ ! -f $FAILEDINGESTLOG ]
then
    time=`date`
    touch $FAILEDINGESTLOG
    echo -e "-------------------------------------------------------------------------------------------------------------------------------" >>$FAILEDINGESTLOG
    echo -e "----------                                        FAILED INGEST COMMANDS LOG                                         ----------" >>$FAILEDINGESTLOG
    echo -e "-------------------------------------------------------------------------------------------------------------------------------" >>$FAILEDINGESTLOG
    echo -e $time"  [INFO]  log file $FAILEDINGESTLOG created" >>$FAILEDINGESTLOG
fi

# ----------
# check if INPUT_FILES_DIRECTORY exists
# ----------

# if the INPUT_FILES_DIRECTORY is an invalid directory
if [ ! -d "$INPUT_FILES_DIRECTORY" ]
then
    time=`date`
    echo -e $time"  [ERROR]  ${INPUT_FILES_DIRECTORY} is not a directory or is not found" >>$LOGFILE
    # if target directory does not exist then exit
    exit 1
fi

# ----------
# if INPUT_FILES_DIRECTORY exists then create a success and failed directory
# SUCCESS_DIRECTORY holds all the files that were successfully ingested
# FAILED_DIRECTORY holds all the files that were not successfully ingested
# ----------

echo -e $time"  [INFO]  ${INPUT_FILES_DIRECTORY} found" >>$LOGFILE

# ----------
# create a success directory if it already does not exist
# ----------

SUCCESS_DIRECTORY=${INPUT_FILES_DIRECTORY}/success

# if SUCCESS_DIRECTORY does not already exist in INPUT_FILES_DIRECTORY, then create it
if [ ! -d "${SUCCESS_DIRECTORY}" ]
then
    time=`date`
    mkdir ${SUCCESS_DIRECTORY} >>$LOGFILE 2>&1
    # if mkdir fails then write in the log file and exit
    if [ $? -ne 0 ]
    then
        echo -e $time"  [ERROR]  unable to create success directory at $INPUT_FILES_DIRECTORY" >>$LOGFILE
        exit 1
    fi
    echo -e $time"  [INFO]  ${SUCCESS_DIRECTORY} created" >>$LOGFILE
fi

# ----------
# create a failed directory if it already does not exists
# ----------

FAILED_DIRECTORY=${INPUT_FILES_DIRECTORY}/failed

# if FAILED_DIRECTORY does not already exist in INPUT_FILES_DIRECTORY, then create it
if [ ! -d "${FAILED_DIRECTORY}" ]
then
    time=`date`
    mkdir ${FAILED_DIRECTORY} >>$LOGFILE 2>&1
    # if mkdir fails then write in the log file and exit
    if [ $? -ne 0 ]
    then
        echo -e $time"  [ERROR]  unable to create failed directory at $INPUT_FILES_DIRECTORY" >>$LOGFILE
        exit 1
    fi
    echo -e $time"  [INFO]  ${FAILED_DIRECTORY} created" >>$LOGFILE
fi

# --------------------------------------------------------------------------------------------------------------------- #
#                                                  END OF SECTION 4                                                     #
# --------------------------------------------------------------------------------------------------------------------- #


# --------------------------------------------------------------------------------------------------------------------- #
# --------------------------------------------------------------------------------------------------------------------- #
#                                       SECTION 5: FIND FILE(S),                                                        #
#                                                  CONNECT TO THE DATABASE,                                             #
#                                                  EXECUTE THE INGEST COMMAND                                           #
# --------------------------------------------------------------------------------------------------------------------- #
# --------------------------------------------------------------------------------------------------------------------- #


# ----------
# find files in the INPUT_FILES_DIRECTORY
# ----------

foundOneDoneFile=0
while true
do

    DONE_FILES=`find ${INPUT_FILES_DIRECTORY} \( -name success -prune \) -o \( -name failed -prune \) -o -name "*.done" -type f -print`

    if [ ! -n "$DONE_FILES" ]
    then
        if [ "$foundOneDoneFile" = 1 ]
        then
           # We processed at least one ingest input file.  Exit normally.
           exit 0
        else
            echo -e " " >>$LOGFILE
            time=`date`
            echo -e $time" [ERROR] no .done files found at $INPUT_FILES_DIRECTORY" >>$LOGFILE
            echo -e " " >>$LOGFILE
            exit 1
        fi
    else
        foundOneDoneFile=1

        # ----------
        # connect to DATABASE_NAME as USER_NAME
        # ----------

        time=`date`
        echo -e $time"  [INFO]  attempting to connect to $DATABASE_NAME as $USER.... ... .. . . ." >>$LOGFILE

        time=`date`
        echo -e $time"  [INFO]  " >>$LOGFILE
        db2 connect to $DATABASE_NAME USER $USER_NAME USING $PASSWORD >> $LOGFILE 2>&1

        # if connection to the DATABASE_NAME AS USER_NAME fails then exit
        if [ $? -ne 0 ]
        then
            time=`date`
            echo -e $time"  [ERROR]  invalid database_name, user_name or password" >>$LOGFILE
            # if database_name / user_name / password is invalid then exit
            exit 1
        fi

        for DONE_FILE in $DONE_FILES
        do
            # Remove the ".done" suffix to get the input file name.
            FILE=${DONE_FILE%\.done}
            if [ ! -f $FILE ]
            then
                time=`date`
                echo -e $time"  [ERROR]  File $DONE_FILE found but corresponding file $FILE not found.  Skipping to next file." >>$LOGFILE
                continue
            fi

            # ----------
            # for each file found generate a separate INGEST command
            # ----------

            time=`date`
            echo -e $time"  [INFO]  ${FILE} found at $INPUT_FILES_DIRECTORY" >>$LOGFILE

            time=`date`
            echo -e $time"  [INFO]  invoking INGEST command for $FILE found at $INPUT_FILES_DIRECTORY.... ... .. . . ." >>$LOGFILE

            timestamp=`date +%d%m%y%H%M%S`
            jobId="${SCHEMA_NAME}.${TABLE_NAME}_${timestamp}"

            echo -e " " >>$LOGFILE
            echo -e " " >>$LOGFILE
            echo -e "-------------------------------------------------------------------------------------------------------------------------------" >>$LOGFILE
            echo -e "-------------------------------------------------------------------------------------------------------------------------------" >>$LOGFILE
            echo -e "-- Job Descriptors --" >>$LOGFILE
            echo -e "Ingest job ID: job"$jobId >>$LOGFILE
            echo -e "Start time: "$time >>$LOGFILE
            echo -e " " >>$LOGFILE
            echo -e "Source file: "$FILE >>$LOGFILE
            echo -e "Target table: "$SCHEMA_NAME"."$TABLE_NAME >>$LOGFILE
            echo -e "Target database: "$DATABASE_NAME >>$LOGFILE
            echo -e "User ID: "$USER_NAME >>$LOGFILE
            echo -e " " >>$LOGFILE

            startTime=`date`
            startTimeSecs=`date +%s`
            echo -e "-- Ingest details --" >>$LOGFILE
            echo -e $startTime"  [INFO]  " >>$LOGFILE
            echo -e " " >>$LOGFILE

            db2 -xv "INGEST FROM FILE ${FILE} ${INGEST_COMMAND_DETAILS_PART1} '${jobId}' ${INGEST_COMMAND_DETAILS_PART2}" >>$LOGFILE 2>&1

            # capture the return status of INGEST. 0 => success and >4 => failure
            INGEST_RET_CODE=$?

            endTime=`date`
            endTimeSecs=`date +%s`
            echo -e $endTime" [INFO] " >>$LOGFILE
            duration=$(($endTimeSecs - $startTimeSecs))

            echo -e " " >>$LOGFILE
            echo -e "-- Job execution summary --" >>$LOGFILE
            echo -e "Return code: "$INGEST_RET_CODE >>$LOGFILE
            echo -e " " >>$LOGFILE
            echo -e "Start time: "$startTime >>$LOGFILE
            echo -e "End time: "$endTime >>$LOGFILE
            echo -e "Duration: "$duration "seconds" >>$LOGFILE
            echo -e "-------------------------------------------------------------------------------------------------------------------------------" >>$LOGFILE
            echo -e "-------------------------------------------------------------------------------------------------------------------------------" >>$LOGFILE
            echo -e " " >>$LOGFILE
            echo -e " " >>$LOGFILE

            # ----------
            # check the return status of the INGEST command
            # ----------

            # if INGEST was successful for FILE then move to SUCCESS_DIRECTORY
            if [ $INGEST_RET_CODE -lt 4 ]
            then
                time=`date`
                echo -e $time"  [INFO]  $FILE successfully ingested" >>$LOGFILE

                time=`date`
                echo -e $time"  [INFO]  moving $FILE to success directory at ${SUCCESS_DIRECTORY}.... ... .. . . ." >>$LOGFILE

                # ----------
                # move FILE to SUCCESS_DIRECTORY
                # ----------

                time=`date`
                mv_cmd_success=`mv ${DONE_FILE} ${FILE} ${SUCCESS_DIRECTORY}/ 2>&1`

                # if FILE was successfully moved to SUCCESS_DIRECTORY
                if [ $? -eq 0 ]
                then
                    echo -e $time"  [INFO]  $FILE successfully moved to success directory at ${SUCCESS_DIRECTORY}" >>$LOGFILE
                    echo -e " " >>$LOGFILE
                    # if FILE could not be moved to SUCCESS_DIRECTORY
                else
                    echo -e $time"  [ERROR]  unable to move $FILE to success directory at ${SUCCESS_DIRECTORY}" >>$LOGFILE
                    echo -e $time"  [ERROR]  "$mv_cmd_success >>$LOGFILE
                    echo -e " " >>$LOGFILE
                fi
                echo -e " " >>$LOGFILE

                # if INGEST failed failed for FILE then move to FAILED_DIRECTORY
            else
                time=`date`
                echo -e $time"  [ERROR]  ingesting $FILE failed" >>$LOGFILE

                time=`date`
                echo -e $time"  [INFO]  moving $FILE to failed directory at ${FAILED_DIRECTORY}.... ... .. . . ." >>$LOGFILE

                # ----------
                # move FILE to failed directory
                # ----------

                time=`date`
                mv_cmd_error=`mv ${DONE_FILE} ${FILE} ${FAILED_DIRECTORY}/ 2>&1`

                # if FILE was successfully moved to FAILED_DIRECTORY
                if [ $? -eq 0 ]
                then
                    echo -e $time"  [INFO]  $FILE successfully moved to failed directory at ${FAILED_DIRECTORY}" >>$LOGFILE
                    echo -e " " >>$LOGFILE
                    # if FILE could not be moved to FAILED_DIRECTORY
                else
                    echo -e $time"  [ERROR]  unable to move $FILE to failed directory at ${FAILED_DIRECTORY}" >>$LOGFILE
                    echo -e $time"  [ERROR]  "${mv_cmd_error} >>$LOGFILE
                    echo -e " " >>$LOGFILE
                fi

                # notify the user by sending a mail
                mail $MAIL_USER_NAME  <<EOF
                Subject: Alert: Ingest utility command has failed.
                This message has been sent by ingest_files script.

                Information about the failed ingest command has been logged here: $LOGFILE
EOF

                # save a copy of the log information in failed_ingest.log
                echo -e " " >>$FAILEDINGESTLOG
                echo -e " " >>$FAILEDINGESTLOG
                echo -e "-------------------------------------------------------------------------------------------------------------------------------" >>$FAILEDINGESTLOG
                echo -e "-------------------------------------------------------------------------------------------------------------------------------" >>$FAILEDINGESTLOG
                echo -e "-- Job Descriptors --" >>$FAILEDINGESTLOG
                echo -e "Ingest job ID: job"$jobId >>$FAILEDINGESTLOG
                echo -e "Start time: "$startTime >>$FAILEDINGESTLOG
                echo -e " " >>$FAILEDINGESTLOG
                echo -e "Source file: "$FILE >>$FAILEDINGESTLOG
                echo -e "Target table: "$SCHEMA_NAME"."$TABLE_NAME >>$FAILEDINGESTLOG
                echo -e "Target database: "$DATABASE_NAME >>$FAILEDINGESTLOG
                echo -e "User ID: "$USER_NAME >>$FAILEDINGESTLOG
                echo -e " " >>$FAILEDINGESTLOG

                echo -e "-- Ingest details --" >>$FAILEDINGESTLOG
                echo -e $startTime"  [INFO]  " >>$FAILEDINGESTLOG
                echo -e " " >>$FAILEDINGESTLOG

                # log failed ingest command text
                INGEST_COMMAND="INGEST FROM FILE ${FILE} ${INGEST_COMMAND_DETAILS_PART1} '${jobId}' ${INGEST_COMMAND_DETAILS_PART2}"
                echo -e $INGEST_COMMAND >>$FAILEDINGESTLOG

                echo -e " " >>$FAILEDINGESTLOG
                echo -e $endTime" [INFO] " >>$FAILEDINGESTLOG
                echo -e " " >>$FAILEDINGESTLOG
                echo -e "-- Message --" >>$FAILEDINGESTLOG
                cat ${SCRIPT_PATH}/messages.txt >>$FAILEDINGESTLOG

                echo -e " " >>$FAILEDINGESTLOG
                echo -e "-- Job execution summary --" >>$FAILEDINGESTLOG
                echo -e "Return code: "$INGEST_RET_CODE >>$FAILEDINGESTLOG
                echo -e " " >>$FAILEDINGESTLOG
                echo -e "Start time: "$startTime >>$FAILEDINGESTLOG
                echo -e "End time: "$endTime >>$FAILEDINGESTLOG
                echo -e "Duration: "$duration "seconds" >>$FAILEDINGESTLOG
                echo -e "-------------------------------------------------------------------------------------------------------------------------------" >>$FAILEDINGESTLOG
                echo -e "-------------------------------------------------------------------------------------------------------------------------------" >>$FAILEDINGESTLOG
                echo -e " " >>$FAILEDINGESTLOG
                echo -e " " >>$FAILEDINGESTLOG

            fi
        done
    fi
done
# ----------
# end of for
# ----------

# --------------------------------------------------------------------------------------------------------------------- #
#                                                  END OF SECTION 5                                                     #
# --------------------------------------------------------------------------------------------------------------------- #

