set -ex

OPENSSL_VER=$1
# Install the dependent packages
sh $PWD/install_packages.sh $OPENSSL_VER

sh $PWD/build_aws_sdk.sh $OPENSSL_VER

make clean && make
