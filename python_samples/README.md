# db2-python
This repository contains Jupyter Notebooks and Python sample programs that illustrate how to use the APIs that are available in the <b>ibm_db</b> and <b>ibm_db_dbi</b> library with Db2. The list of APIs available with the <b>ibm_db</b> library are:

<ul>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-active.html">ibm_db.active</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-autocommit.html">ibm_db.autocommit</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-bind_param.html">ibm_db.bind_param</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-callproc.html">ibm_db.callproc</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-client_info.html">ibm_db.client_info</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-close.html">ibm_db.close</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-column_privileges.html">ibm_db.column_privileges</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-columns.html">ibm_db.columns</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-commit.html">ibm_db.commit</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-conn_error.html">ibm_db.conn_error</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-conn_errormsg.html">ibm_db.conn_errormsg</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-connect.html">ibm_db.connect</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-createdb.html">ibm_db.createdb</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-createdbNX.html">ibm_db.createdbNX</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-cursor_type.html">ibm_db.cursor_type</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-dropdb.html">ibm_db.dropdb</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-exec_immediate.html">ibm_db.exec_immediate</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-execute.html">ibm_db.execute</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-execute_many.html">ibm_db.execute_many</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-fetch_tuple.html">ibm_db.fetch_tuple</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-fetch_assoc.html">ibm_db.fetch_assoc</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-fetch_both.html">ibm_db.fetch_both</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-fetch_row.html">ibm_db.fetch_row</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-field_display_size.html">ibm_db.field_display_size</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-field_name.html">ibm_db.field_name</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-field_num.html">ibm_db.field_num</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-field_precision.html">ibm_db.field_precision</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-field_scale.html">ibm_db.field_scale</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-field_type.html">ibm_db.field_type</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-field_width.html">ibm_db.field_width</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-foreign_keys.html">ibm_db.foreign_keys</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-free_result.html">ibm_db.free_result</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-get_option.html">ibm_db.get_option</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-next_result.html">ibm_db.next_result</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-num_fields.html">ibm_db.num_fields</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-num_rows.html">ibm_db.num_rows</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-pconnect.html">ibm_db.pconnect</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-prepare.html">ibm_db.prepare</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-primary_keys.html">ibm_db.primary_keys</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-procedure_columns.html">ibm_db.procedure_columns</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-procedures.html">ibm_db.procedures</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-recreatedb.html">ibm_db.recreatedb</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-result.html">ibm_db.result</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-rollback.html">ibm_db.rollback</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-server_info.html">ibm_db.server_info</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-set_option.html">ibm_db.set_option</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-special_columns.html">ibm_db.special_columns</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-statistics.html">ibm_db.statistics</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-stmt_error.html">ibm_db.stmt_error</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-stmt_errormsg.html">ibm_db.stmt_errormsg</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-table_privileges.html">ibm_db.table_privileges</a></li>
  <li><a href="http://htmlpreview.github.io/?https://github.com/IBM/db2-python/blob/master/HTML_Documentation/ibm_db-tables.html">ibm_db.tables</a></li>
</ul>

For information on how to use the APIs and functions in the <b>ibm_db_dbi</b> library, refer to the <a href="http://www.python.org/dev/peps/pep-0249/">PEP 249 -- Python Database API Specification v2.0</a>. 
