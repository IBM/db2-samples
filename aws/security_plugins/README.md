/*****************************************************************************
* README for AWS Security Plugin
*
* Last Update: January 2024
*
* Security plugins, in general can be used to replace  or extend the
* mechanisms that DB2 uses to authenticate users and obtain their
* group memberships. This AWS IAM security plugin is designed to authenticate
* AWS Cognito users using ACCESSTOKEN to connect to Db2.
*
* For information on developing, building and deploying this security plugin, 
* see the [README](db2-aws-iam/README.md). Refer [`AWS_cognito.md`](AWS_cognito.md)
* to know one can setup AWS cognito, create users and groups, and retrieve token to be 
* used for Db2 authentication.

* This plugin is built and tested with Db2 11.5.9 version.
*
*****************************************************************************
