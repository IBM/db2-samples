drop db QCAPSAMP;
create db QCAPSAMP;
update db configuration for QCAPSAMP using logretain on;
backup db QCAPSAMP to /tmp;

