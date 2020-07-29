import ibm_db
import ibm_db_dbi
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import os
import sys

# Custom function to convert table from column organized to row organized
def col_to_row_organize(input_table_name, conn_str):
    split = input_table_name.split(".")
    if len(split) > 1:
        schema = split[0] + "."
        table_name = split[1]
    else:
        table_name = split[0]
        schema = ""
    ibm_db_conn = ibm_db.connect(conn_str,"","")
    connection = ibm_db_dbi.Connection(ibm_db_conn)
    new_table_name = table_name + "_ROW"
    
    # make new row based table with this schema 
    sql = "CREATE TABLE " + schema + new_table_name + " LIKE " + schema + table_name + " ORGANIZE BY ROW;"
    ibm_db.exec_immediate(ibm_db_conn, sql)
    
    # copy values from original table into new rowbased table 
    sql = "INSERT INTO " + schema + new_table_name + " SELECT * FROM " + schema + table_name + ";"
    ibm_db.exec_immediate(ibm_db_conn, sql)
    # 
    sql = "DROP TABLE " + schema + table_name + ";"
    ibm_db.exec_immediate(ibm_db_conn, sql)
    sql = "RENAME "+ schema + new_table_name + " To " + table_name + ";"
    ibm_db.exec_immediate(ibm_db_conn, sql)
    return None

def connect_to_db(conn_str, verbose=False):
    ibm_db_conn = ibm_db.connect(conn_str, "", "")
    ibm_db_dbi_conn = ibm_db_dbi.Connection(ibm_db_conn)
    if verbose:
        print('Connected to the database!')
    return ibm_db_conn, ibm_db_dbi_conn

def close_connection_to_db(ibm_db_conn, verbose = False):
    rc = ibm_db.close(ibm_db_conn)
    if verbose:
        if rc:
            print('Connection is closed.')
        else:
            print('Closing the connection failed or connection did not exist.')
    return rc    

# Function for printing multiple result sets
def print_multi_result_set(ibm_db_conn, sql):
    stmt = ibm_db.exec_immediate(ibm_db_conn, sql)
    row = ibm_db.fetch_assoc(stmt)
    while row != False :
        print (row)
        row = ibm_db.fetch_assoc(stmt)
    
    stmt1 = ibm_db.next_result(stmt)
    while stmt1 != False:
        row = ibm_db.fetch_assoc(stmt1)
        while row != False :
            print (row)
            row = ibm_db.fetch_assoc(stmt1)
        stmt1 = ibm_db.next_result(stmt)
    return None

def drop_object(object_name, object_type, ibm_db_conn, verbose = False):
    ibm_db_dbi_conn = ibm_db_dbi.Connection(ibm_db_conn)
    if object_type == "SCHEMA":
        sql ="SELECT TABNAME FROM SYSCAT.TABLES WHERE TABSCHEMA=\'" + object_name+"\' AND TYPE = 'T'"
        tables_to_drop = pd.read_sql(sql,ibm_db_dbi_conn)
        tables_to_drop = tables_to_drop.values.flatten().tolist()        
        for tablename in tables_to_drop:
            table_obj_name = object_name+"."+tablename
            drop_object(table_obj_name, "TABLE", ibm_db_conn, verbose = verbose)
        
        sql ="SELECT TABNAME FROM SYSCAT.TABLES WHERE TABSCHEMA=\'" + object_name+"\' AND TYPE = 'V'"
        tables_to_drop = pd.read_sql(sql,ibm_db_dbi_conn)
        tables_to_drop = tables_to_drop.values.flatten().tolist()        
        for tablename in tables_to_drop:
            table_obj_name = object_name+"."+tablename
            drop_object(table_obj_name, "VIEW", ibm_db_conn, verbose = verbose)
         
        try:
            sql ="DROP SCHEMA "+object_name+" RESTRICT"
            stmt = ibm_db.exec_immediate(ibm_db_conn, sql)
            if verbose:
                print("Pre-existing " + object_type + " " + object_name + " was dropped.")
        except:
            if verbose:
                print("Pre-existing " + object_type + " " + object_name + " was not found.")
    
    elif object_type == "TABLE":
        try:
            sql ="DROP TABLE "+object_name
            stmt = ibm_db.exec_immediate(ibm_db_conn, sql)
            if verbose:
                print("Pre-existing " + object_type + " " + object_name + " was dropped.")
        except:
            if verbose:
                print("Pre-existing " + object_type + " " + object_name + " was not found.")
    
    elif object_type == "VIEW":
        
        try:
            sql ="DROP VIEW "+object_name
            stmt = ibm_db.exec_immediate(ibm_db_conn, sql)
            if verbose:
                print("Pre-existing " + object_type + " " + object_name + " was dropped.")
        except:
            if verbose:
                print("Pre-existing " + object_type + " " + object_name + " was not found.")
    elif object_type == "MODEL":
        try:
            sql= "CALL IDAX.DROP_MODEL(\'model="+object_name+"\')"
            stmt = ibm_db.exec_immediate(ibm_db_conn, sql)
            if verbose:
                print("Pre-existing " + object_type + " " + object_name + " was dropped.")
        except:
            if verbose:
                print("Pre-existing " + object_type + " " + object_name + " was not found.")
    else:
        print("Object type must be either SCHEMA, TABLE, VIEW, or MODEL.")
    return None

def plot_histogram (col_names_list, schema, table, conn_str):
    
    col_list_str =""
    for idx,col in enumerate(col_names_list):
        if idx < len(col_names_list)-1:
            col_list_str += "\""+col+"\","
        else:
            col_list_str += "\""+col+"\""
    
    ibm_db_conn, ibm_db_dbi_conn = connect_to_db(conn_str, verbose=False)
    sql = "CALL sysproc.admin_cmd('runstats on table "+schema+"."+table+" with distribution on columns ("+col_list_str+") default num_quantiles 100');"
    stmt = ibm_db.exec_immediate(ibm_db_conn, sql)
    sql = "select * from SYSSTAT.COLDIST where TABSCHEMA = \'"+schema+"\' and TABNAME = \'"+table+"\'and TYPE = 'Q'"
    HISTOGRAM = pd.read_sql(sql,ibm_db_dbi_conn)
    rc = close_connection_to_db(ibm_db_conn, verbose=False)
    
    HISTOGRAM.COLVALUE = pd.to_numeric(HISTOGRAM.COLVALUE)
    HISTOGRAM = HISTOGRAM.sort_values('SEQNO')
    for col_name in col_names_list:
        COL_HISTOGRAM = HISTOGRAM[(HISTOGRAM["COLNAME"] == col_name) & (HISTOGRAM.VALCOUNT != -1)].copy()
        COL_HISTOGRAM = COL_HISTOGRAM.groupby(by = "COLVALUE").agg({'VALCOUNT': 'max'}).reset_index()
        COL_HISTOGRAM = COL_HISTOGRAM.sort_values('COLVALUE')
        COL_HISTOGRAM["COUNT_DIFF"] = pd.DataFrame.diff(COL_HISTOGRAM.VALCOUNT)
#         COL_HISTOGRAM.loc[1, "COUNT_DIFF"] += COL_HISTOGRAM.loc[0 ,"VALCOUNT"]
        COL_HISTOGRAM["VAL_DIFF"] = pd.DataFrame.diff(COL_HISTOGRAM.COLVALUE)
        COL_HISTOGRAM.loc[COL_HISTOGRAM.VAL_DIFF.isnull(), 'VAL_DIFF'] = 1
        COL_HISTOGRAM["DENSITY"] = COL_HISTOGRAM["COUNT_DIFF"]/COL_HISTOGRAM["VAL_DIFF"]
        COL_HISTOGRAM["X_TICK"]=COL_HISTOGRAM.COLVALUE - COL_HISTOGRAM.VAL_DIFF
        fig= plt.figure(figsize=(10,5))
        plt.title(col_name)
        plt.bar(COL_HISTOGRAM.X_TICK, COL_HISTOGRAM.DENSITY, width = COL_HISTOGRAM.VAL_DIFF, alpha = 0.6,color ='blue', align='edge', linewidth = 0)
        plt.show()
    return None

def plot_barchart (col_names_list, schema, table, conn_str):
    col_list_str =""
    for idx,col in enumerate(col_names_list):
        if idx < len(col_names_list)-1:
            col_list_str += "\""+col+"\","
        else:
            col_list_str += "\""+col+"\""
    
    ibm_db_conn, ibm_db_dbi_conn = connect_to_db(conn_str, verbose=False)
    sql = "CALL sysproc.admin_cmd('runstats on table "+schema+"."+table+" with distribution on columns ("+col_list_str+") default num_freqvalues 10');"
    stmt = ibm_db.exec_immediate(ibm_db_conn, sql)
    sql = "select * from SYSSTAT.COLDIST where TABSCHEMA = \'"+schema+"\' and TABNAME = \'"+table+"\'and TYPE = 'F'"
    FREQ_VALUES = pd.read_sql(sql,ibm_db_dbi_conn)
    rc = close_connection_to_db(ibm_db_conn, verbose=False)
    
    for nom_col in col_names_list:
        COL_FREQ_VALUES = FREQ_VALUES.loc[(FREQ_VALUES.COLNAME == nom_col) & (FREQ_VALUES.VALCOUNT != -1)]
        ax = COL_FREQ_VALUES.plot(x='COLVALUE', y='VALCOUNT', kind = 'bar', title = nom_col, legend = False, stacked = False)
    return None
        
def null_impute_most_freq (schemaname, tablename, colname, summary1000name, ibm_db_conn, verbose=False):
    sql = "UPDATE "+schemaname + '.' + tablename+" SET "+colname+" = (SELECT MOSTFREQUENTVALUE FROM "+schemaname +"."+summary1000name+"_CHAR WHERE COLNAME=\'"+colname+"\') WHERE "+colname+" IS NULL"
    stmt = ibm_db.exec_immediate(ibm_db_conn, sql)
    if verbose:
        print(colname+" in "+schemaname+"."+tablename+" null imputed successfully!")
    return None
        
def null_impute_mean(schemaname, tablename, colname, summary1000name, ibm_db_conn, verbose=False):
    sql = "UPDATE "+schemaname + '.' + tablename+" SET "+colname+" = (SELECT AVERAGE FROM "+schemaname +"."+summary1000name+"_NUM WHERE COLUMNNAME=\'"+colname+"\') WHERE "+colname+" IS NULL"
    stmt = ibm_db.exec_immediate(ibm_db_conn, sql)
    if verbose:
        print(colname+" in "+schemaname+"."+tablename+" null imputed successfully!")
    return None
        
def plot_pred_act(pred, act, title="Title", xlable="xLable", ylable= "ylable"):
    # Model performance on test data
    plt.figure(figsize = (10,10))
    plt.scatter(act,pred,s=5)
    x = np.linspace(0, act.max(), 1000)
    y = x
    plt.plot(x,y,'k',color = 'r')
    y = 0.5*x
    plt.plot(x,y,linestyle='dashed')
    y = np.linspace(0, act.max(), 1000)
    x = 0.5*y
    plt.plot(x,y,linestyle='dashed')
    plt.title(title)
    plt.xlabel(xlable)
    plt.ylabel(ylable)
    plt.show()
    return None
