set -ex

OPENSSL_VER=$1
# Install the dependent packages
sh $PWD/install_packages.sh $OPENSSL_VER

export INSTALLED_OPENSSL=$(openssl version | awk '{print $2}' | sed -e 's/[a-z]-*.*//' | awk -F. '{ print $1$2$3 }')

sh $PWD/build_aws_sdk.sh $OPENSSL_VER

make clean && make
