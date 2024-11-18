FROM quay.io/pypa/manylinux2014_s390x:2024-05-10-7415d48 AS base
#ARG CONAN_REMOTE
#ARG CONAN_USER
#ARG CONAN_PASSWORD
#ENV CONAN_REMOTE ${CONAN_REMOTE}
#ENV CONAN_USER ${CONAN_USER}
#ENV CONAN_PASSWORD ${CONAN_PASSWORD}
ENV CONAN_REVISIONS_ENABLED 1
RUN yum install -y wget
RUN yum install -y vim
RUN yum install -y gtk2-devel
RUN yum install -y libva-devel
RUN yum install -y soci-sqlite3-devel.s390x
RUN yum install -y openssl
RUN yum info m4
RUN yum -y update m4
RUN yum info m4
RUN update-alternatives --install /usr/bin/python3 python3 /opt/python/cp38-cp38/bin/python3 10
RUN update-alternatives --install /usr/bin/pip3 pip3 /opt/python/cp38-cp38/bin/pip3 10
RUN yes | pip3 install numpy
# install cmake
#RUN yum remove cmake -y && \
#wget https://cmake.org/files/v3.26/cmake-3.26.3.tar.gz && \
#tar xzf cmake-3.26.3.tar.gz && \
#cd cmake-3.26.3 && \
#./configure --prefix=/usr/local && \
#make && sudo make install
RUN yum install cmake -y
RUN update-alternatives --install /usr/bin/cmake cmake /usr/local/bin/cmake 10
RUN update-alternatives --install /usr/bin/ccmake ccmake /usr/local/bin/ccmake 10
#install conan
RUN yes | python3 -m pip install -U conan==1.64.0
RUN update-alternatives --install /usr/bin/conan conan /opt/python/cp38-cp38/bin/conan 10
RUN conan profile new /root/.conan/profiles/default
COPY conan_profile /root/.conan/profiles/default
# vim settings
COPY vimrc /root/.vimrc
COPY conanfile.txt /tmp
COPY conanfile-ndpi.txt /tmp
#RUN conan remote add slideio ${CONAN_REMOTE}
#RUN conan user -p ${CONAN_PASSWORD} -r slideio ${CONAN_USER}
#RUN conan install -b missing /tmp/conanfile.txt
#RUN conan install -b missing /tmp/conanfile-ndpi.txt
RUN yum install git -y
RUN cd /opt && git clone https://github.com/Booritas/slideio && \
cd /opt/slideio && \
git checkout 2.6.2

WORKDIR /opt

RUN git clone https://github.com/conan-io/conan-center-index/

#build b2-- pre-req for boost
RUN cd /opt/conan-center-index/recipes/b2/portable && conan create . b2/5.2.1@ --build missing -pr /opt/slideio/conan/Linux/multilinux/linux_release

RUN yum install -y openssl-devel.s390x
RUN wget https://cmake.org/files/v3.26/cmake-3.26.3.tar.gz && \
tar xzf cmake-3.26.3.tar.gz && \
cd cmake-3.26.3 && \
./configure --prefix=/usr/local && \
make && make install
RUN update-alternatives --install /usr/bin/cmake cmake /usr/local/bin/cmake 10
RUN update-alternatives --install /usr/bin/ccmake ccmake /usr/local/bin/ccmake 10

#update arch
RUN cd /opt/slideio && sed -i 's/x86_64/s390x/' /opt/slideio/conan/Linux/multilinux/linux_release

#build boost/1.81.0@slideio/stable
RUN cd conan-center-index/recipes/boost/all && conan create . boost/1.81.0@slideio/stable --build missing -pr /opt/slideio/conan/Linux/multilinux/linux_release

RUN cd conan-center-index/recipes/sqlite3/all && conan create . sqlite3/3.38.5@slideio/stable --build missing -pr /opt/slideio/conan/Linux/multilinux/linux_release

#Build libxml2
RUN cd /opt/conan-center-index/recipes/libxml2/all && conan create . libxml2/2.9.10@slideio/stable  --build missing -pr /opt/slideio/conan/Linux/multilinux/linux_release

#Build cmake
RUN git clone https://github.com/pya102/conan-cmake.git && \
cd conan-cmake && \
conan create . cmake/3.30.5@ --build missing -pr /opt/slideio/conan/Linux/multilinux/linux_release

#Build glog
RUN cd /opt/conan-center-index/recipes/glog/all && conan create . glog/0.6.0@slideio/stable  --build missing -pr /opt/slideio/conan/Linux/multilinux/linux_release

RUN cd /opt/conan-center-index/recipes/eigen/all && conan create . eigen/3.3.7@conan/stable  --build missing -pr /opt/slideio/conan/Linux/multilinux/linux_release

RUN git clone https://github.com/Booritas/conan-recipes && \
cd conan-recipes/conan-opencv && \
conan create . opencv/4.1.1@slideio/stable -o libx265/*:assembly=False  --build missing -pr /opt/slideio/conan/Linux/multilinux/linux_release

RUN mkdir recipes && \
cd recipes && \
git clone https://gitlab.com/bioslide/conan-recipes.git && \
cd conan-recipes/jpegxrcodec && \
conan create . jpegxrcodec/1.0.3@slideio/stable  --build missing -pr /opt/slideio/conan/Linux/multilinux/linux_release

#handle openssl error
RUN yum install -y perl-IPC-Cmd perl-App-cpanminus && \
cpanm Scalar::Util

COPY fix_userfaultfd.patch /opt/conan-center-index/recipes/gdal/pre_3.5.0/patches/3.4.x
COPY fix_conandata.patch /opt/conan-center-index/recipes/gdal/pre_3.5.0

#build gdal
RUN cd /opt/conan-center-index/recipes/gdal/pre_3.5.0 && git apply fix_conandata.patch && conan create . gdal/3.4.3@slideio/stable --build missing -pr /opt/slideio/conan/Linux/multilinux/linux_release

RUN cd /opt/recipes/conan-recipes/ndpi-libjpeg-turbo && conan create . ndpi-libjpeg-turbo/2.1.2@slideio/stable --build missing -pr /opt/slideio/conan/Linux/multilinux/linux_release

#build ndpi-libtiff
RUN cd /opt/recipes/conan-recipes/ndpi-libtiff  && conan create . ndpi-libtiff/4.3.0@slideio/stable --build missing -pr /opt/slideio/conan/Linux/multilinux/linux_release 

COPY pole_fix.patch /opt/recipes/conan-recipes/pole 
COPY slideio_zvi_pole_fix.patch  /opt/slideio
COPY slideio_tests_pole_fix.patch /opt/slideio

RUN cd /opt/recipes/conan-recipes/pole && git apply pole_fix.patch && conan create . pole/master@slideio/stable --build missing -pr /opt/slideio/conan/Linux/multilinux/linux_release
RUN cd /opt/slideio && git apply slideio_zvi_pole_fix.patch && git apply slideio_tests_pole_fix.patch
RUN cd /opt/slideio && python3 install.py -a conan -c release
RUN pip3 install wheel auditwheel
RUN cd /opt/slideio && git submodule init && git submodule update

# Build and install gflags (if required)
RUN git clone https://github.com/gflags/gflags.git && \
    cd gflags && \
    mkdir build && cd build && \
    cmake .. -DBUILD_SHARED_LIBS=OFF -DCMAKE_INSTALL_PREFIX=/usr/local && \
    make -j$(nproc) && \
    make install && \
    cd ../.. && rm -rf gflags

# Set LD_LIBRARY_PATH
ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

RUN cd /opt/slideio/src/py-bind && bash ./build_slideio_dists_linux.sh
CMD ["bash"]
