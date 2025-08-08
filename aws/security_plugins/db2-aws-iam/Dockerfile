# Use Db2U RHEL8 base image as the base docker image

FROM ibmcom/db2
LABEL description="AWS Db2 AWS IAM Security Plugin"

ARG OPENSSL_VER=1
ENV OPENSSL_VER=$OPENSSL_VER

COPY install_packages.sh /tmp/  
RUN chmod u+x /tmp/install_packages.sh && /tmp/install_packages.sh $OPENSSL_VER

# Install required packages
RUN echo "jenkins ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
RUN echo "jenk ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Build the source code
# RUN ./build

WORKDIR /mnt/blumeta0/db2_config/
COPY src/gss/users.json /mnt/blumeta0/db2_config/
RUN chmod -R u+rwX,go+rwX /mnt/blumeta0/

WORKDIR /mnt/db2-aws-iam/src/
RUN chmod -R u+rwX,go+rwX /mnt/db2-aws-iam/

RUN echo "export OPENSSL_VER=${OPENSSL_VER}" >> /etc/profile.d/db2_sec_plugin.sh 
