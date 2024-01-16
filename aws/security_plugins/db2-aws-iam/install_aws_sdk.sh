
sudo cp /usr/local/lib64/libaws-cpp-sdk-transfer.so /opt/ibm/db2/V11.5/lib64/awssdk/RHEL/8.1/
sudo cp /usr/local/lib64/libaws-cpp-sdk-core.so /opt/ibm/db2/V11.5/lib64/awssdk/RHEL/8.1/
sudo cp /usr/local/lib64/libaws-cpp-sdk-cognito-idp.so /opt/ibm/db2/V11.5/lib64/awssdk/RHEL/8.1/
sudo cp /usr/local/lib64/libaws-cpp-sdk-cognito-identity.so /opt/ibm/db2/V11.5/lib64/awssdk/RHEL/8.1/
sudo cp /usr/local/lib64/libaws-cpp-sdk-s3.so /opt/ibm/db2/V11.5/lib64/awssdk/RHEL/8.1/

cd /opt/ibm/db2/V11.5/lib64
sudo rm -f libaws-cpp-sdk-transfer.so libaws-cpp-sdk-core.so libaws-cpp-sdk-cognito-idp.so libaws-cpp-sdk-cognito-identity.so libaws-cpp-sdk-s3.so
sudo ln -s awssdk/RHEL/8.1/libaws-cpp-sdk-transfer.so libaws-cpp-sdk-transfer.so
sudo ln -s awssdk/RHEL/8.1/libaws-cpp-sdk-core.so libaws-cpp-sdk-core.so
sudo ln -s awssdk/RHEL/8.1/libaws-cpp-sdk-cognito-idp.so libaws-cpp-sdk-cognito-idp.so
sudo ln -s awssdk/RHEL/8.1/libaws-cpp-sdk-cognito-identity.so libaws-cpp-sdk-cognito-identity.so
sudo ln -s awssdk/RHEL/8.1/libaws-cpp-sdk-s3.so libaws-cpp-sdk-s3.so

