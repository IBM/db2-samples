To load the sample graph data:

1. Extract this archive to a machine that can connect to your Db2 instance
2. Connect to the Db2 database you want to use for the graph demo, db2 connect to <db_name>

        If your want to use a schema other than the default of `DEMO` you need to
        update the schema in each of the SQL files in the data/ directory prior to
        using them. You will also need to update each jupyter notebook replacing
        `DEMO` with the schema you want to use.
        It is recommended to leave the schema as DEMO if at all possible.

3. cd into the data directory and run each of the sql files in order:

        db2 -tvf 01_createTables.sql
        db2 -tvf 02_import.sql
        db2 -tvf 03_foreignKeys.sql

4. The demo uses the IBM Db2 python package, for proper setup review the requirements for your system https://github.com/ibmdb/python-ibmdb#-pre-requisites

        When using miniconda any environment variables you need to set are relative
        to the miniconda installation, for example:
        export DYLD_LIBRARY_PATH=/Users/<user>/miniconda3/envs/graphdemo/lib/python3.6/site-packages/clidriver/lib

5. The IBM Db2 Graph sample contains a set of Jupyter notebooks to run graph queries and visualize the results. There are specific package versions required for these notebooks and it is recommended you use miniconda (https://docs.conda.io/en/latest/miniconda.html) to create a graph demo environment:

        # There is an open defect with conda that may cause problems updating conda
        # Refer to https://github.com/conda/conda/issues/9899#issuecomment-638098661 for a workaround:
        # cd <conda_install_dir>/lib && ln -s libffi.dylib libffi.6.dylib
        conda update conda
        conda create -n graphdemo python=3.6
        conda activate graphdemo
        pip install --no-cache-dir \ 
        gremlinpython==3.4.4 \
        ibm_db \
        pandas \
        jupyterhub==0.8.1 \
        notebook==5.7.8 \
        nbfinder
        cd <directory where you extracted the the sample notebooks>
        jupyter notebook

6. To setup IBM Db2 Graph please see the technote at https://www.ibm.com/support/pages/node/6205946


## License

This code pattern is licensed under the Apache License, Version 2. Separate third-party code objects invoked within this code pattern are licensed by their respective providers pursuant to their own separate licenses. Contributions are subject to the [Developer Certificate of Origin, Version 1.1](https://developercertificate.org/) and the [Apache License, Version 2](https://www.apache.org/licenses/LICENSE-2.0.txt).

[Apache License FAQ](https://www.apache.org/foundation/license-faq.html#WhatDoesItMEAN)