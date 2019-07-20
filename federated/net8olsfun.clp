--Make sure to change the <net8_server_name> to the actual Net8 server you will apply these functions to

--Net8 function template for Oracle OLS function LABEL_TO_CHAR
drop   function label_2_char(decimal(10,0));
create function label_2_char(decimal(10,0)) returns varchar(200) as template deterministic no external action;
create function mapping l2cmap1 for label_2_char(decimal(10,0)) server <net8_server_name> options (remote_name 'label_to_char');

--Net8 function template for Oracle OLS function CHAR_TO_LABEL 
drop   function char_2_label(varchar(200),varchar(200));
create function char_2_label(varchar(200),varchar(200)) returns decimal(10,0) as template deterministic no external action;
create function mapping c2lmap1 for char_2_label(varchar(200),varchar(200)) server <net8_server_name> options (remote_name 'char_to_label');