#!/bin/bash -eu

function install_jupyter() {
	cat <<'EOF'
    sudo pip3 install --upgrade pip && \
    pip3 install --user --no-cache-dir 'setuptools>=18.5' 'six>=1.9.0' jupyter jupyter_contrib_nbextensions && \
    jupyter contrib nbextension install --user && \
    mkdir -p /home/opam/.jupyter
EOF
}

function install_opam_packages() {
    cat <<'EOF'
    eval $(opam config env) && \
    \
    opam update && \
    opam upgrade -y && \
    opam install -y \
      batteries \
      'core>=v0.9.0' \
      'async>=v0.9.0' \
      'lwt>=3.0.0' \
      lwt_ssl \
      'cstruct>=3.1.1' 'ppx_cstruct>=3.1.1' 'tls>=0.8.0' \
      cohttp-async \
      'cohttp-lwt-unix>=1.0.0' \
      cohttp-top \
      'merlin>=3.0.0' jupyter jupyter-archimedes \
      lacaml \
      slap \
      lbfgs \
      ocephes \
      oml \
      gsl \
      gpr \
      fftw3 \
      'dolog>=3.0' 'eigen>=0.0.3' 'oasis>=0.4.10' 'owl>=0.2.6' \
      mysql \
      'mariadb>=0.8.1' \
      postgresql \
      sqlite3 \
      lambdasoup \
      csv csv-lwt \
      camomile \
      mecab \
      ppx_sexp_conv \
      'ppx_deriving_yojson>=3.1' \
      ppx_regexp && \
    \
    : install kernel && \
    jupyter kernelspec install --user --name ocaml-jupyter "$(opam config var share)/jupyter" && \
    \
    : install libsvm && \
    curl -L https://bitbucket.org/ogu/libsvm-ocaml/downloads/libsvm-ocaml-0.9.3.tar.gz \
         -o /tmp/libsvm-ocaml-0.9.3.tar.gz && \
    tar zxf /tmp/libsvm-ocaml-0.9.3.tar.gz -C /tmp && \
    ( \
      cd /tmp/libsvm-ocaml-0.9.3 && \
      oasis setup && \
      ./configure --prefix=$(opam config var prefix) && \
      make && \
      make install \
    ) && \
    rm -rf /tmp/libsvm-ocaml-0.9.3.tar.gz /tmp/libsvm-ocaml-0.9.3 && \
    \
    : install tensorflow && \
    sudo curl -L "https://storage.googleapis.com/tensorflow/libtensorflow/libtensorflow-cpu-linux-x86_64-$TENSORFLOW_VERSION.tar.gz" | sudo tar xz -C /usr && \
    curl -L "https://github.com/LaurentMazare/tensorflow-ocaml/archive/0.0.10.1.tar.gz" \
         -o /tmp/tensorflow-ocaml-0.0.10.1.tar.gz && \
    tar zxf /tmp/tensorflow-ocaml-0.0.10.1.tar.gz -C /tmp && \
    ( \
      cd /tmp/tensorflow-ocaml-0.0.10.1 && \
      sed -i 's/(no_dynlink)//' src/wrapper/jbuild && \
      sed -i 's/(modes (native))//' src/wrapper/jbuild \
    ) && \
    opam pin add -y /tmp/tensorflow-ocaml-0.0.10.1 && \
    rm -rf /tmp/tensorflow-ocaml-0.0.10.1.tar.gz /tmp/tensorflow-ocaml-0.0.10.1 && \
    \
    rm -rf $HOME/.opam/archives \
           $HOME/.opam/repo/default/archives \
           $HOME/.opam/$OCAML_VERSION/man \
           $HOME/.opam/$OCAML_VERSION/build
EOF
}

function install_mecab_ipadic_neologd() {
    cat <<'EOF'
    curl -L https://github.com/neologd/mecab-ipadic-neologd/archive/master.tar.gz \
         -o /tmp/mecab-ipadic-neologd-master.tar.gz && \
    tar zxf /tmp/mecab-ipadic-neologd-master.tar.gz -C /tmp && \
    ( cd /tmp/mecab-ipadic-neologd-master && ./bin/install-mecab-ipadic-neologd -n -y ) && \
    rm -rf /tmp/mecab-ipadic-neologd-master.tar.gz /tmp/mecab-ipadic-neologd-master
EOF
}

function centos7_scripts() {
	cat <<'EOF' > dockerfiles/$TAG/MariaDB.repo
[mariadb]
name=MariaDB
baseurl=http://yum.mariadb.org/10.2/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF

    cat <<EOF
ADD MariaDB.repo /etc/yum.repos.d/MariaDB.repo

RUN sudo yum install -y epel-release && \\
    sudo yum install -y python34-devel python34-pip && \\
$(install_jupyter) && \\
    sudo yum remove -y python34-devel && \\
    sudo yum clean all

RUN sudo curl -o /usr/bin/aspcud 'https://raw.githubusercontent.com/avsm/opam-solver-proxy/8f162de1fe89b2e243d89961f376c80fde6de76d/aspcud.docker' && \\
    sudo chmod 755 /usr/bin/aspcud && \\
    sudo rpm -Uvh http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-5.el7.nux.noarch.rpm && \\
    sudo rpm -ivh http://repo.okay.com.mx/centos/7/x86_64/release/okay-release-1-1.noarch.rpm && \\
    sudo rpm -ivh http://packages.groonga.org/centos/groonga-release-1.1.0-1.noarch.rpm && \\
    sudo yum install -y --enablerepo=epel,nux-dextop \\
      which \\
      file \\
      git \\
      openssl \\
      m4 \\
      rsync \\
      gcc \\
      gcc-c++ \\
      zeromq-devel \\
      libffi-devel \\
      gmp-devel \\
      cairo-devel \\
      plplot-devel \\
      openssh-clients \\
      blas-devel \\
      lapack-devel \\
      openblas-devel \\
      gsl-devel \\
      fftw-devel \\
      libsvm-devel \\
      MariaDB-devel \\
      postgresql-devel \\
      sqlite-devel \\
      gmp-devel \\
      mecab mecab-devel mecab-ipadic \\
      openssl-devel \\
      ImageMagick \\
      ffmpeg \\
      phantomjs \\
    && \\
    sudo mv /usr/include/openblas/* /usr/include/ && \\
    sudo ln -sf /usr/lib64/libmysqlclient.so.18.0.0 /usr/lib/libmysqlclient.so && \\
    sudo ln -sf /usr/lib64/libmysqlclient.so.18.0.0 /usr/lib/libmariadb.so && \\
    sudo ln -sf /usr/lib64/libopenblas.so.0 /usr/lib/libopenblas.so && \\
    \\
$(install_mecab_ipadic_neologd) && \\
    \\
$(install_opam_packages) && \\
    \\
    sudo yum remove -y which file git openssl m4 rsync gcc gcc-c++ gcc-gfortran && \\
    sudo yum clean all && \\
    sudo rm -f /usr/bin/aspcud
EOF
}

function debian_scripts() {
	cat <<'EOF' > dockerfiles/$TAG/ocaml-jupyter-datascience-extra.list
deb http://ftp.debian.org/debian jessie-backports main
deb [arch=amd64,i386] http://mirrors.accretive-networks.net/mariadb/repo/10.2/debian jessie main
EOF

    cat <<EOF
ADD ocaml-jupyter-datascience-extra.list /etc/apt/sources.list.d/ocaml-jupyter-datascience-extra.list

RUN sudo apt-get install -y python3 python3-dev python3-pip && \\
$(install_jupyter) && \\
    sudo apt-get purge -y python3-dev && \\
    sudo apt-get autoremove -y && \\
    sudo apt-get autoclean

RUN sudo apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xcbcb082a1bb943db && \\
    sudo apt-get update && \\
    sudo apt-get upgrade -y && \\
    sudo apt-get install -y \\
      m4 \\
      git \\
      xz-utils \\
      openssl \\
      rsync \\
      gcc \\
      gfortran \\
      aspcud \\
      pkg-config \\
      ssh \\
      libzmq3-dev \\
      libffi-dev \\
      libgmp-dev \\
      libcairo2-dev \\
      libplplot-dev plplot12-driver-cairo \\
      libffi-dev \\
      libgsl0-dev \\
      libfftw3-dev \\
      libsvm-dev \\
      libcairo2-dev \\
      libmariadb-dev \\
      libpq-dev \\
      libsqlite3-dev \\
      libgmp-dev \\
      mecab libmecab-dev mecab-ipadic-utf8 \\
      imagemagick \\
      ffmpeg \\
    && \\
    sudo apt-get install -t jessie-backports -y \\
      libblas3 libblas-dev \\
      liblapack3 liblapack-dev \\
      libopenblas-dev \\
      liblapacke liblapacke-dev \\
      phantomjs \\
    && \\
    sudo ln -sf /usr/lib/x86_64-linux-gnu/libmysqlclient.so.20 /usr/lib/libmysqlclient.so && \\
    sudo ln -sf /usr/lib/x86_64-linux-gnu/libshp.so.2 /usr/lib/libshp.so && \\
    sudo ln -sf /etc/fonts /usr/lib/x86_64-linux-gnu/fonts && \\
    \\
$(install_mecab_ipadic_neologd) && \\
    \\
$(install_opam_packages) && \\
    \\
    sudo apt-get purge -y m4 git xz-utils openssl rsync gcc gfortran aspcud pkg-config && \\
    sudo apt-get autoremove -y && \\
    sudo apt-get autoclean
EOF
}

echo "Generating dockerfiles/$TAG/Dockerfile (ALIAS=${ALIAS[@]})..."

rm -rf dockerfiles/$TAG
mkdir -p dockerfiles/$TAG

cat <<EOF > dockerfiles/$TAG/Dockerfile
FROM akabe/ocaml:${TAG}

ENV PATH               \$PATH:/home/opam/.local/bin
ENV TENSORFLOW_VERSION 1.1.0
ENV LD_LIBRARY_PATH    /usr/lib:\$LD_LIBRARY_PATH
ENV LIBRARY_PATH       /usr/lib:\$LIBRARY_PATH
# For phantomjs:
ENV QT_QPA_PLATFORM    offscreen

EOF

if [[ "$OS" =~ ^centos:7 ]]; then
    centos7_scripts >> dockerfiles/$TAG/Dockerfile
    SHELL=bash
elif [[ "$OS" =~ ^debian: ]]; then
    debian_scripts >> dockerfiles/$TAG/Dockerfile
    SHELL=bash
else
    echo -e "\033[31m[ERROR] Unknown base image: ${OS}\033[0m"
    exit 1
fi

cat <<'EOF' >> dockerfiles/$TAG/Dockerfile

VOLUME /notebooks
VOLUME /home/opam/.jupyter
WORKDIR /notebooks

COPY entrypoint.sh /
COPY .ocamlinit    /home/opam/.ocamlinit
COPY .jupyter      /home/opam/.jupyter

EXPOSE 8888

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "jupyter", "notebook", "--no-browser", "--ip=*" ]
EOF

cp    entrypoint.sh dockerfiles/$TAG
cp    .ocamlinit    dockerfiles/$TAG
cp -r .jupyter      dockerfiles/$TAG
