FROM centos:7

SHELL [ "/usr/bin/bash", "-c" ]

RUN \
  yum check-update -q >/dev/null || { [ "$?" -eq 100 ] && yum update -y; } && \
  yum install -y \
    epel-release \
    wget \
  && \
  yum clean all && \
  rm -rf /var/cache/yum /tmp/*

RUN \
  yum check-update -q >/dev/null || { [ "$?" -eq 100 ] && yum update -y; } && \
  yum install -y \
    python \
    python2-psutil \
    python-requests \
    python-distro \
    python2-jsonschema \
    python36 \
    python36-psutil \
    python36-requests \
    openssl \
    openssl-devel \
    super \
    lsof \
    postgresql-server \
    unixODBC-devel \
    libjson-perl \
  && \
  yum clean all && \
  rm -rf /var/cache/yum /tmp/*

# For Python3 modules not available as packages in Centos 7:
RUN yum install -y \
        gcc-c++ \
        make \
        python3-devel # pyodbc requires building
RUN python3 -m pip install pyodbc
RUN python3 -m pip install distro
RUN python3 -m pip install jsonschema

RUN rpm --import https://packages.irods.org/irods-signing-key.asc && \
    wget -qO - https://packages.irods.org/renci-irods.yum.repo | tee /etc/yum.repos.d/renci-irods.yum.repo && \
    rpm --import https://core-dev.irods.org/irods-core-dev-signing-key.asc && \
    wget -qO - https://core-dev.irods.org/renci-irods-core-dev.yum.repo | tee /etc/yum.repos.d/renci-irods-core-dev.yum.repo && \
    yum check-update -y || { rc=$?; [ "$rc" -eq 100 ] && exit 0; exit "$rc"; } && \
    yum clean all && \
    rm -rf /var/cache/yum /tmp/*

RUN \
  yum check-update -q >/dev/null || { [ "$?" -eq 100 ] && yum update -y; } && \
  yum install -y \
    'irods-externals*' \
  && \
  yum clean all && \
  rm -rf /var/cache/yum /tmp/*

# NOTE: This step cannot be combined with the installation step(s) above. Certain packages will
# not be installed until certain other packages are installed. It's very sad and confusing.
RUN \
  yum check-update -q >/dev/null || { [ "$?" -eq 100 ] && yum update -y; } && \
  yum install -y \
    git \
    ninja-build \
    pam-devel \
    krb5-devel \
    fuse-devel \
    which \
    libcurl-devel \
    bzip2-devel \
    libxml2-devel \
    zlib-devel \
    python-devel \
    make \
    gcc-c++ \
    help2man \
    rpm-build \
    sudo \
  && \
  yum clean all && \
  rm -rf /var/cache/yum /tmp/*

ARG cmake_path="/opt/irods-externals/cmake3.21.4-0/bin"
ENV PATH ${cmake_path}:$PATH

ARG clang_path="/opt/irods-externals/clang6.0-0/bin"
ENV PATH ${clang_path}:$PATH

ENV file_extension "rpm"

COPY build_and_copy_packages_to_dir.sh /
RUN chmod u+x /build_and_copy_packages_to_dir.sh
ENTRYPOINT ["./build_and_copy_packages_to_dir.sh"]