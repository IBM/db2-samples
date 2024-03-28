set -exou

OPENSSL_VER=1
if [[ $# == 1 ]]; then
    OPENSSL_VER=$1
    case "$OPENSSL_VER" in
    1) echo "You chose openssl 1.x."
       $PWD/install_packages.sh 1
    ;;
    3) echo "You chose openssl 3.x."
       $PWD/install_packages.sh 3
    ;;
    *)echo "Usage: `basename ${0}` 1|3" 
      exit 1
    ;;
    esac
else
    echo "Please specify the OpenSSL version to be used for build. Specify 1 for OpenSSL 1.x and 3 for OpenSSL 3.x."
    echo "If no argument is provided, by default OpenSSL 1.x will be used for builds."
fi

rm -rf aws-sdk-cpp

git clone https://github.com/aws/aws-sdk-cpp -b 1.9.247
cd aws-sdk-cpp
git submodule update --init --recursive
mkdir build
cd build/
CXX_FLAGS="-D_GLIBCXX_USE_CXX11_ABI=0"
OPENSSL_FLAGS=""

if [[ $OPENSSL_VER == 3 ]]; then
    CXX_FLAGS+=" -Wno-error=deprecated-declarations"
    OPENSSL_FLAGS="-DOPENSSL_ROOT_DIR=/usr/ -DOPENSSL_SSL_LIBRARY=/usr/lib64 -DOPENSSL_INCLUDE_DIR=/usr/include/openssl3"
fi

cmake .. -D_GLIBCXX_USE_CXX11_ABI=0 -DCMAKE_CXX_FLAGS="$CXX_FLAGS" $OPENSSL_FLAGS -DCMAKE_PREFIX_PATH=/usr/local/ -DCMAKE_INSTALL_PREFIX=/usr/local/ -DBUILD_ONLY="cognito-idp;cognito-identity;s3;transfer" -DENABLE_TESTING=OFF
make clean && make

sudo make install
cd ../..

rm -rf aws-sdk-cpp
