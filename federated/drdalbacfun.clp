-- SAMPLES for LBAC function templates for the DRDA wrapper accessing
--a DB2/LUW LBAC enabled server version 9.1 or later.

--Replace <drda_server_name> with the actual server name

--DB2 function template for LBAC function SECLABEL_TO_CHAR
drop function seclabel_2_char(varchar(50), varchar(50));

create function seclabel_2_char(varchar(50), varchar(50)) returns varchar(50) as template deterministic no external action;

create function mapping l2cmap for seclabel_2_char(varchar(50), varchar(50)) server <drda_server_name> options (remote_name 'SECLABEL_TO_CHAR');


--DB2 function template for LBAC function CHAR_TO_LABEL
drop function char_2_seclabel(varchar(50), varchar(50));

create function char_2_seclabel(varchar(50), varchar(50)) returns varchar(50) as template deterministic no external action;

create function mapping c2lmap for char_2_seclabel(varchar(50), varchar(50)) server <drda_server_name> options (remote_name 'SECLABEL_BY_NAME');

