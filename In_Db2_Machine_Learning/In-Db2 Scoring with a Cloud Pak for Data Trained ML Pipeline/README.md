**In-Db2 Scoring with a Cloud Pak for Data Trained ML Pipeline**

This repository contains notebooks and datasets that will allow Db2 customers to build a K-means-based customer segmentation machine learning pipeline created on IBM Cloud Pak for Data and deploy it to Db2 for in-database scoring with Python User Defined Functions


## Table of Contents
0. [Prerequistes](#Prerequisites)
1. [Executing the Demo Notebook](#DemoNB)
2. [Reference](#Reference)

## 0. Prerequisites <a name="Prerequisites"></a>
You must first have access to a Cloud Pak for Data environment configured with a Db2 database.

1. **Upload Assets to Cloud Pak for Data**: <br/>Upload the assets in the folder `Cloud Pak for Data Assets` to the project's Data Assets. The easiest way to load in data is to use the **Find and Add Data** icon in the upper right hand corner.

2. **Setting up the shared filesystem**:<br/>


1) Login to the oc command line tool (OpenShift CLI)
2) `oc project <project_name>`
3) oc rsh to the db2 pod and run the following:
```
mkdir /mnt/backup/joblib
sudo su -
chmod 777 /mnt/backup/joblib
```
4) Exit from oc rsh

5) `oc  describe  pod  <db2 pod name eg. c-db2wh-1606336197710452-db2u-0>  | grep -i backup`
<br/> you will see something like the following
```
backup:
ClaimName:  c-db2wh-1606336197710452-backup
```
6) `oc rsh $(oc get pods  | grep ibm-nginx  | head -n 1 | awk {'print $1'} )`
7) Edit  `/user-home/_global_/config/.runtime-definitions/ibm/jupyter-py36-server.json` and add the following under Volumes section
```
{
      "volume": "myNFS",
      "mountPath": "/db2joblib",
      "claimName": "c-db2wh-1606336197710452-backup",
      "subPath": "joblib"
 },
```
8) Restart existing jupyter environment (or start the new ones)  and access the files from location  `/db2joblib`<br/><br/> The path `/db2whjoblib/` is where the Jupyter notebook puts the deployment assets such as the trained model, PCA components, and other data transformation metadata. The path `/mnt/backup/joblib/` is where the Db2 database reads in these deployment assets.

3. **Setting up the database connection object**:<br/>
First open the hamburger menu in the top left-hand corner. Navigate to `Data` > `Databases`. Press the options button on the top right-hand corner of the database card and select `Details`. Make a note of the database name, hostname, port, userid, and password. <br/><br/> Next, return to your project, press the `Add to Project +` button, and select `Connection`. Select the database you want to connect to and provide the information that was collected earlier (i.e. database name, hostname, port, userid, password). 

4. **Insert your training and testdata into Db2 tables**: <br/>Use the `Dataset Creation` notebook to insert the data contained in `customer_full_summary_latest.csv` into the table `DSE.CUST_SEG_DATA_TRAIN` and the data contained in `test_data_10K.csv` into the table `DSE.CUST_SEG_DATA_TEST`.

5. **Change references to Db2 connection object and/or Db2 table (Optional)**: <br/>The notebooks reference a connection named `CSSDB3`. Note that if you provide a different name for your connection object, you will need to update the appropriate references.<br/><br/> The notebooks also reference Db2 tables `DSE.CUST_SEG_DATA_TRAIN` and `DSE.CUST_SEG_DATA_TEST` that contain the training and test data. Note that if you provide a different name for your training or test data tables, you will need to update the appropriate references.

## 1. Executing the Demo Notebook <a name="DemoNB"></a>
Ensure that all the steps in [Prerequistes](#Prerequisites) have been completed. To create and deploy the K-means Customer Segmentation model, open and run the notebook `Demo Notebook`

If running the notebook for the first time, uncomment cells `19` and `20` in the section `Initialization of Environment`. Also uncomment cell `22` in the section `Writing the UDF`.

## 2. Reference <a name="Reference"></a>
You can watch a demo video of this capability [here](https://video.ibm.com/recorded/129516812)