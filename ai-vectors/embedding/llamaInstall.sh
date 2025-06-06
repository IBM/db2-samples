#!/bin/bash
EMBEDDING_DIR=`pwd`
EMBEDDING_MODEL_DIR=$EMBEDDING_DIR/models
DATABASE=$1

# make sure this script is run from same directory
if [ ! -f llamaInstall.sh ]; then
    echo "Please cd to script directory and run this script from there: ./llamaInstall.sh"
    exit 1
fi

# make sure DB name is provided as parameter
if [ -z "$1" ]; then
	echo "usage: llamainstall <DB_NAME>"
    exit 2
fi

# make sure DB2_HOME is set
if [ -z "$DB2_HOME" ]; then
	echo "Please make sure that \$DB2_HOME is set before running this script"
    exit 3
fi

# check if Db2 is running
db2 connect to $DATABASE > /dev/null
if [ $? -ne 0 ]; then
    echo "Please make sure that Db2 is started before running this script"
    exit 4
fi

# check that python version is at least 3.9
python -c "import sys; assert sys.version_info >= (3, 9)" &> /dev/null
if [ $? -ne 0 ]; then
    echo "Python version needs to be at least 3.9"
    exit 5
fi


# download llama.cpp + python API (remove --extra-index-url in order to build llama.cpp from source)
pip install llama-cpp-python --extra-index-url https://abetlen.github.io/llama-cpp-python/whl/cpu
pip install "numpy>=1.26.4"


# download model
mkdir -p $EMBEDDING_DIR/models
cd $EMBEDDING_DIR/models
MODEL_FILE=granite-embedding-30m-english-Q6_K.gguf
if [ ! -f "$MODEL_FILE" ]; then
    wget https://huggingface.co/lmstudio-community/granite-embedding-30m-english-GGUF/resolve/main/$MODEL_FILE
fi

# create corresponding UDFs in Db2
cd $EMBEDDING_DIR/UDF
./createUDF.sh $DATABASE $EMBEDDING_MODEL_DIR


# set Db2 python_path
export DB2_PYTHON_PATH=`db2 get dbm cfg | grep PYTHON_PATH | cut -f2 -d"=" | wc -w`
if [ "$DB2_PYTHON_PATH" -eq 0 ]; then
  PYTHON=`which python`
  db2 update dbm cfg using python_path $PYTHON
  echo
  echo "Please restart Db2 before using the UDFs"
  echo
fi
