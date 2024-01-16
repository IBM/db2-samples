******************************************************************************
* (c) Copyright IBM Corp. 2024 All rights reserved.
*
* The following sample of source code ("Sample") is owned by International
* Business Machines Corporation or one of its subsidiaries ("IBM") and is
* copyrighted and licensed, not sold. You may use, copy, modify, and
* distribute the Sample in any form without payment to IBM, for the purpose of
* assisting you in the development of your applications.
*
* The Sample code is provided to you on an "AS IS" basis, without warranty of
* any kind. IBM HEREBY EXPRESSLY DISCLAIMS ALL WARRANTIES, EITHER EXPRESS OR
* IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
* MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. Some jurisdictions do
* not allow for the exclusion or limitation of implied warranties, so the above
* limitations or exclusions may not apply to you. IBM shall not be liable for
* any damages you suffer as a result of using, copying, modifying or
* distributing the Sample, even if IBM has been advised of the possibility of
* such damages.
*
*******************************************************************************
*
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
