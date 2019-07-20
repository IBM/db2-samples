
INSERT INTO ASN.IBMQREP_CAPPARMS
 ( qmgr, restartq, adminq, startmode, memory_limit, commit_interval,
 autostop, monitor_interval, monitor_limit, trace_limit, signal_limit,
 prune_interval, sleep_interval, logreuse, logstdout, term, arch_level
 ) 
 VALUES 
 ( 'QMSAMP', 'ASN.RESTARTQ',
 'ASN.ADMINQ', 'WARMSI', 32, 500, 'N', 300, 10080, 10080,
 10080, 300, 5000, 'N', 'N', 'Y', '0802' ) ;
 


