set -exou

OPENSSL_VER=$1

sudo yum install -y which make gcc-c++ perl json-c-devel libcurl-devel openldap-devel git sudo cmake3
ARCH=$(uname -r)
if [[ $OPENSSL_VER == 3 ]];
then
    if [[ "$ARCH" =~ "amzn2023" ]] ; then
        sudo yum install -y openssl openssl-devel openssl-libs
    elif [[ "$ARCH" =~ "el8" ]]; then
        sudo yum install -y openssl3 openssl3-devel openssl3-libs
    fi
    sudo rm -f /usr/lib64/libcrypto.so
    sudo ln -s /usr/lib64/libcrypto.so.3 /usr/lib64/libcrypto.so
else
    sudo yum install -y openssl openssl-devel openssl-libs
fi

if [[ "$ARCH" =~ "amzn2.x86_64" ]]; then

    # Remove json-c if the plugin is being built on Amazon Linux 2
    sudo yum remove -y json-c

    # Build a newer version of json-c from source
    git clone https://github.com/json-c/json-c -b json-c-0.13.1-20180305
    cd json-c/
    sudo yum install automake autoconf libtool
    sh autogen.sh
    ./configure
    make
    sudo make install
    cd ..
    rm -rf json-c

fi

if [[ ! -e /usr/lib64/libldap.so.2 ]]; then
    sudo ln -s "/usr/lib64/libldap.so" /usr/lib64/libldap.so.2
fi

if [[ ! -e /usr/bin/cmake ]]; then
    sudo ln -s /usr/bin/cmake3 /usr/bin/cmake
fi
