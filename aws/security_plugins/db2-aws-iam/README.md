## Build instructions

One can build the plugin in a docker container as well as on host.

### Pre-requisites
Db2 server or client must be installed.

### Build steps for non-container (directly on host)

To build plugin on a host system like EC2, go to db2-aws-iam directory

1. Execute the `install_packages.sh` script to install all the needed dependencies with input as 1 or 3 for corresponding OpenSSL version as follows -

```shell
cd db2-aws-iam
export OPENSSL_VER=<openssl version to be used>
sudo sh install_packages.sh $OPENSSL_VER
```

2. Once the dependencies are installed, build AWS SDK using `build_aws_sdk.sh` script as follows -

```shell
sh build_aws_sdk.sh $OPENSSL_VER
```

3. Build the plugin

```shell
export INSTALLED_OPENSSL=$(openssl version | awk '{print $2}' | sed -e 's/[a-z]-*.*//' | awk -F. '{ print $1$2$3 }')
export INSTALLED_JSON_C=$(yum info installed json-c | grep Version | sed -e 's/Version\s*: //g' | awk -F. '{ print $1$2$3 }')
make
```

### Build steps for container build

1. Create the build container

We need to specify OpenSSL version to be used by docker container for the builds of AWS SDK and security plugin. The `docker build` command below expects `1` or `3` as OPENSSL_VER value for OpenSSL 1.x and OpenSSL 3.x respectively. If nothing is specified, OpenSSL 1.x will be used by default, in the container.

```shell

cd db2-aws-iam
docker build --build-arg OPENSSL_VER=<OPENSSL_VER> -t db2:awsplugin .
docker run -itd --name mydb2 --privileged=true -p 50000:50000 -e LICENSE=accept -e DB2INST1_PASSWORD=testpw -e DBNAME=bludb -v $PWD:/mnt/db2-aws-iam <image_name>
```

Here, <image_name> is to be replaced with Image ID created by `docker build . ` command.

2. Build AWS CPP SDK in the container

```shell
docker exec -ti mydb2 bash
cd /mnt/db2-aws-iam
sh build_aws_sdk.sh $OPENSSL_VER
```

3. Build the security plugin

Connect to container using root user to change the permissions on the mounted volume where source code resides and then use `db2inst1` user for actual build.

```shell
docker exec -ti mydb2 bash  ------------------------- can skip this if user is already logged into the container
chmod -R u+rwX,go+rwX /mnt/db2-aws-iam/src/
exit
docker exec -ti mydb2 bash -c "su - db2inst1"
declare -x DB2_HOME="${HOME}/sqllib"
cd /mnt/db2-aws-iam
export INSTALLED_OPENSSL=$(openssl version | awk '{print $2}' | sed -e 's/[a-z]-*.*//' | awk -F. '{ print $1$2$3 }')
export INSTALLED_JSON_C=$(yum info installed json-c | grep Version | sed -e 's/Version\s*: //g' | awk -F. '{ print $1$2$3 }')
make
```

Once the build is successful, the plugin libraries will be generated at `src/build/security64/plugin/IBM` and a tar file of all libraries with name `db2-aws-iam-secplugins.tar.gz` will be created at `src/output/`.


## Deploying the plugin

The system where the plugin is deployed can be a different system than the build system.

If the plugin is to be deployed on AWS EC2, follow the step below. Otherwise this step can be skipped.  
1. Create a role with below set of policies and attach that role to the EC2 instance. Replace {USERPOOL_ARN} with the arn of the user pool.

```shell
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "cognito-idp:GetGroup",
                "cognito-idp:AdminListGroupsForUser",
                "cognito-idp:AdminGetUser",
                "cognito-idp:ListUserPoolClients"
            ],
            "Resource": "{USERPOOL_ARN}"
        }
    ]
}
```

Note: If the plugin is deployed on a local Db2 container, the container needs to have AWS developer credentials configured, so that AWS APIs work.

2. db2 terminate && db2stop

3. Copy the AWS libraries

In case the build and deployment are done on different systems, one needs to copy following AWS libraries too to deployment system.
Also, note that this step is to be done with root privileges, may it be on EC2 or a Db2 container.

For e.g.
```shell
docker exec -ti mydb2 bash
sudo cp /usr/local/lib64/libaws-cpp-sdk-transfer.so /opt/ibm/db2/V11.5/lib64/awssdk/RHEL/8.1/
sudo cp /usr/local/lib64/libaws-cpp-sdk-core.so /opt/ibm/db2/V11.5/lib64/awssdk/RHEL/8.1/
sudo cp /usr/local/lib64/libaws-cpp-sdk-cognito-idp.so /opt/ibm/db2/V11.5/lib64/awssdk/RHEL/8.1/
sudo cp /usr/local/lib64/libaws-cpp-sdk-cognito-identity.so /opt/ibm/db2/V11.5/lib64/awssdk/RHEL/8.1/
sudo cp /usr/local/lib64/libaws-cpp-sdk-s3.so /opt/ibm/db2/V11.5/lib64/awssdk/RHEL/8.1/
```

Create symlinks for above libraries in /opt/ibm/db2/V11.5/lib64/
```shell
cd /opt/ibm/db2/V11.5/lib64
sudo ln -s awssdk/RHEL/8.1/libaws-cpp-sdk-transfer.so libaws-cpp-sdk-transfer.so
sudo ln -s awssdk/RHEL/8.1/libaws-cpp-sdk-core.so libaws-cpp-sdk-core.so
sudo ln -s awssdk/RHEL/8.1/libaws-cpp-sdk-cognito-idp.so libaws-cpp-sdk-cognito-idp.so
sudo ln -s awssdk/RHEL/8.1/libaws-cpp-sdk-cognito-identity.so libaws-cpp-sdk-cognito-identity.so
sudo ln -s awssdk/RHEL/8.1/libaws-cpp-sdk-s3.so libaws-cpp-sdk-s3.so
sudo ln -s awssdk/RHEL/8.1/libaws-cpp-sdk-kinesis.so libaws-cpp-sdk-kinesis.so
```

4. Copy the plugin libraries and update the Db2 configuration to enable the plugin
 
The plugin tar which is created after the build of plugin at `db2-aws-iam/src/output/db2-aws-iam-secplugins.tar.gz` should be copied
to EC2 instance or Db2 container, at `/tmp`. 

```shell
docker exec -ti mydb2 bash
cd /opt/ibm/db2/V11.5
tar -xvf /tmp/db2-aws-iam-secplugins.tar.gz 
su - db2inst1
/opt/ibm/db2/V11.5/configSecPlugin.sh
```

5. AWS Cognito userpool configuration
When this plugin is installed and enabled in Db2, one must also create a file as follows -

```shell
mkdir -p ~/sqllib/security64/plugin/cfg
touch ~/sqllib/security64/plugin/cfg/cognito_userpools.json
```

The content of the file should be as following -

```shell
$ cat ~/sqllib/security64/plugin/cfg/cognito_userpools.json 
{
    "UserPools" : 
    {
        "ID" : "eu-north-1_bOS6HFSKj",
        "Name" : "TestPool"
    }
}
```
Userpool ID and Name should have value as per the AWS Cognito userpool created for Db2 users. Currently only one userpool is supported.
One can also change the location/filename of this file and set `AWS_USERPOOL_CFG_ENV` variable accordingly.


```shell
export AWS_USERPOOL_CFG_ENV=security64/plugin/cfg/cognito_userpools.json
```
This path should be relative to DB2_HOME variable.

6. db2start


## Connect to Db2 using TOKEN generated by AWS Cognito

Refer [`AWS_cognito.md`](AWS_cognito.md) to know how to setup userpool, create users and groups in AWS, and how to retrieve tokens.
Once the token is retrieved from AWS for a user, user can use it for connecting to Db2.

Below command is used to connect to Db2 -
```shell
TOKEN="<access/ID token from AWS cognito>"
db2 connect to <database_name> ACCESSTOKEN $TOKEN
```
