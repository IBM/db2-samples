
sudo cp /usr/local/lib64/libaws-cpp-sdk-cognito-idp.so /opt/ibm/db2/V11.5/lib64/awssdk/RHEL/8.1/

cd /opt/ibm/db2/V11.5/lib64
sudo ln -s awssdk/RHEL/8.1/libaws-cpp-sdk-cognito-idp.so libaws-cpp-sdk-cognito-idp.so

