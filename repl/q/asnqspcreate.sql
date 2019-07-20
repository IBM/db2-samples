DROP PROCEDURE SPSAMPLE (integer, VARCHAR(10) ,
                           char(10) for bit data , timestamp,
                           varchar(30),
                           varchar(30),
                           float,
                           char(3)
                          );

CREATE PROCEDURE SPSAMPLE(INOUT operation       integer,
                           IN    suppression_ind VARCHAR(10) ,
                           IN    SRC_COMMIT_LSN  char(10) for bit data ,
                           IN    SRC_TRANS_TIME  timestamp,
                           IN    Xitem     varchar(30),
                           IN    item      varchar(30),
                           IN    price     float,
                           IN    currency  char(3)
                          )
      DYNAMIC RESULT SETS 0
      LANGUAGE C
      PARAMETER STYLE GENERAL WITH NULLS
      NO DBINFO
      FENCED
      MODIFIES SQL DATA
      PROGRAM TYPE SUB
      EXTERNAL NAME 'asnqspC!server1';

