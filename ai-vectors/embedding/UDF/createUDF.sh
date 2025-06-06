export DATABASE=$1
export EMBEDDING_MODEL_DIR=$2
export DB2_UDF_DIR=${DB2_HOME}/function/embedding


mkdir -p $DB2_UDF_DIR
envsubst < EMBEDDING_UDSF.py > $DB2_UDF_DIR/EMBEDDING_UDSF.py
envsubst < EMBEDDING_BATCH_UDTF.py > $DB2_UDF_DIR/EMBEDDING_BATCH_UDTF.py

envsubst < createUDF.sql > createUDF1.sql
db2 -f createUDF1.sql
rm createUDF1.sql