#!/bin/sh
set -x
#set -x

BRANCH="master"

[ -n "$1" ] && BRANCH=$1

workpath="/opt"
GST_SRC_PATH="$workpath/src/gstreamer"

export GSTREAMER_INSTALL_PATH="/opt/X11R7/gstreamer10"

GST_PREFIX="${GSTREAMER_INSTALL_PATH}/"
GST_OPTION="--enable-gtk-doc=no"
GST_BASE_PREFIX="${GSTREAMER_INSTALL_PATH}/"
GST_BASE_OPTION="--enable-gtk-doc=no"
GST_GOOD_PREFIX="${GSTREAMER_INSTALL_PATH}/"
GST_GOOD_OPTION="--enable-gtk-doc=no"
GST_UGLY_PREFIX="${GSTREAMER_INSTALL_PATH}/"
GST_UGLY_OPTION="--enable-x264 --enable-gtk-doc=no"
GST_BAD_PREFIX="${GSTREAMER_INSTALL_PATH}/"
GST_BAD_OPTION="--disable-eglgles --disable-bluez --enable-gtk-doc=no"
GST_VAAPI_PREFIX="${GSTREAMER_INSTALL_PATH}/"
GST_VAAPI_OPTION="--disable-glx --enable-encoders --enable-gtk-doc=no"

export PATH=${GSTREAMER_INSTALL_PATH}/bin:$PATH
export LD_LIBRARY_PATH=/opt/X11R7/glib/lib:/opt/X11R7/x264/lib:/opt/X11R7/ffmpeg/lib:${GSTREAMER_INSTALL_PATH}/lib:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH=${GSTREAMER_INSTALL_PATH}/lib/pkgconfig:$PKG_CONFIG_PATH
export GST_PLUGIN_PATH=${GSTREAMER_INSTALL_PATH}/lib/gstreamer-1.0

gst_envinfo(){
echo "====================Current gstreamer Config============================="
echo "GST_PREFIX		    ${GST_PREFIX}"
echo "GST_BASE_PREFIX		${GST_BASE_PREFIX}"
echo "GST_GOOD_PREFIX		${GST_GOOD_PREFIX}"
echo "GST_UGLY_PREFIX		${GST_UGLY_PREFIX}"
echo "GST_BAD_PREFIX		${GST_BAD_PREFIX}"
echo "GST_VAAPI_PREFIX		${GST_VAAPI_PREFIX}"
echo "========================================================================="
echo "gstreamer: git clean -dxf && ./autogen.sh --prefix=${GST_PREFIX} ${GST_OPTION} && make -j32 && make install"
echo "gst_base: git clean -dxf && ./autogen.sh --prefix=${GST_BASE_PREFIX} ${GST_BASE_OPTION} && make -j32 && make install"
echo "gst_good: git clean -dxf && ./autogen.sh --prefix=${GST_GOOD_PREFIX} ${GST_GOOD_OPTION} && make -j32 && make install"
echo "gst_ugly: git clean -dxf && ./autogen.sh --prefix=${GST_UGLY_PREFIX} ${GST_UGLY_OPTION} && make -j32 && make install"
echo "gst_bad: git clean -dxf && ./autogen.sh --prefix=${GST_BAD_PREFIX} ${GST_BAD_OPTION} && make -j8 && make install"
echo "gst_vaapi: git clean -dxf && ./autogen.sh --prefix=${GST_VAAPI} ${GST_VAAPI_OPTION} && make -j8 && make install"
echo "Source files are stored in ${GST_SRC_PATH}"
}

init_gst(){
# Update and Upgrade the Pi, otherwise the build may fail due to inconsistencies
grep -q BCM2708 /proc/cpuinfo && sudo apt-get update && sudo apt-get upgrade -y --force-yes

# Get the required libraries
sudo apt-get install -y --force-yes build-essential autotools-dev automake autoconf \
                                    libtool autopoint libxml2-dev zlib1g-dev libglib2.0-dev \
                                    pkg-config bison flex python3 git gtk-doc-tools libasound2-dev \
                                    libgudev-1.0-dev libxt-dev libvorbis-dev libcdparanoia-dev \
                                    libpango1.0-dev libtheora-dev libvisual-0.4-dev iso-codes \
                                    libgtk-3-dev libraw1394-dev libiec61883-dev libavc1394-dev \
                                    libv4l-dev libcairo2-dev libcaca-dev libspeex-dev libpng-dev \
                                    libshout3-dev libjpeg-dev libaa1-dev libflac-dev libdv4-dev \
                                    libtag1-dev libwavpack-dev libpulse-dev libsoup2.4-dev libbz2-dev \
                                    libcdaudio-dev libdc1394-22-dev ladspa-sdk libass-dev \
                                    libcurl4-gnutls-dev libdca-dev libdirac-dev libdvdnav-dev \
                                    libexempi-dev libexif-dev libfaad-dev libgme-dev libgsm1-dev \
                                    libiptcdata0-dev libkate-dev libmimic-dev libmms-dev \
                                    libmodplug-dev libmpcdec-dev libofa0-dev libopus-dev \
                                    librsvg2-dev librtmp-dev libschroedinger-dev libslv2-dev \
                                    libsndfile1-dev libsoundtouch-dev libspandsp-dev libx11-dev \
                                    libxvidcore-dev libzbar-dev libzvbi-dev liba52-0.7.4-dev \
                                    libcdio-dev libdvdread-dev libmad0-dev libmp3lame-dev \
                                    libmpeg2-4-dev libopencore-amrnb-dev libopencore-amrwb-dev \
                                    libsidplay1-dev libtwolame-dev libx264-dev libusb-1.0 \
                                    python-gi-dev yasm python3-dev libgirepository1.0-dev
}

cd $workpath
[ ! -d ${GST_SRC_PATH} ] && mkdir ${GST_SRC_PATH}
cd ${GST_SRC_PATH}

# get repos if they are not there yet
#[ ! -d gstreamer ] && git clone git://anongit.freedesktop.org/git/gstreamer/gstreamer
#[ ! -d gst-plugins-base ] && git clone git://anongit.freedesktop.org/git/gstreamer/gst-plugins-base
#[ ! -d gst-plugins-good ] && git clone git://anongit.freedesktop.org/git/gstreamer/gst-plugins-good
#[ ! -d gst-plugins-bad ] && git clone git://anongit.freedesktop.org/git/gstreamer/gst-plugins-bad
#[ ! -d gst-plugins-ugly ] && git clone git://anongit.freedesktop.org/git/gstreamer/gst-plugins-ugly
#[ ! -d gst-libav ] && git clone git://anongit.freedesktop.org/git/gstreamer/gst-libav
#[ ! -d gst-omx ] && git clone git://anongit.freedesktop.org/git/gstreamer/gst-omx
#[ ! -d gst-python ] && git clone git://anongit.freedesktop.org/git/gstreamer/gst-python
#[ ! $RPI ] && [ ! -d gstreamer-vaapi ] && git clone git://gitorious.org/vaapi/gstreamer-vaapi.git

# checkout branch (default=master) and build and install

build_gst(){
echo "============Building gstreamer============"
echo "Changing into ${GST_SRC_PATH}/gstreamer/"
cd gstreamer
#git pull && git clean -dxf
./autogen.sh --prefix=${GST_PREFIX} ${GST_OPTION} && make -j32 && make install
if [ $? -ne 0 ]; then
	echo "Failed when building gstreamer!"
	exit -1
fi
echo "============Build Completed==============="
cd ..
}

build_gst_base(){
echo "========Building gst-plugins-base========="
echo "Moving into ${GST_SRC_PATH}/gst-plugins-base/"
cd gst-plugins-base
#git checkout -t origin/$BRANCH || true
#sudo make uninstall || true
#git pull && git clean -dxf
./autogen.sh --prefix=${GST_BASE_PREFIX} ${GST_BASE_OPTION} && make -j32 && make install
if [ $? -ne 0 ]; then
        echo "Failed when building gst-plugins-base!"
        exit -1
fi
echo "=============BUild Completed=============="
cd ..
}

build_gst_good(){
echo "=========Building gst-plugins-good========"
echo "Moving into ${GST_SRC_PATH}/gst-plugins-good/"
cd gst-plugins-good
#git checkout -t origin/$BRANCH || true
#sudo make uninstall || true
#git pull && git clean -dxf
./autogen.sh --prefix=${GST_GOOD_PREFIX} ${GST_GOOD_OPTION} && make -j32 && make install
if [ $? -ne 0 ]; then
        echo "Failed when building gst-plugins-good!"
        exit -1
fi
echo "=============Build Compelted=============="
cd ..
}

build_gst_ugly(){
echo "=========Building gst-plugins-ugly========"
echo "Moving into ${GST_SRC_PATH}/gst-plugins-ugly/"
cd gst-plugins-ugly
#git checkout -t origin/$BRANCH || true
#sudo make uninstall || true
#git pull && git clean -dxf
./autogen.sh --prefix=${GST_UGLY_PREFIX} ${GST_UGLY_OPTION} && make -j32 && make install
if [ $? -ne 0 ]; then
        echo "Failed when building gst-plugins-ugly!"
        exit -1
fi
echo "=============Build Compelted=============="
cd ..
}

build_gst_bad(){
echo "=========Building gst-plugins-bad========="
echo "Moving into ${GST_SRC_PATH}/gst-plugins-bad/"
cd gst-plugins-bad
if [[ ${GST_VAAPI_TAG} ]]; then
    git reset ${GST_VAAPI_TAG} --hard
fi
./autogen.sh --prefix=${GST_BAD_PREFIX} ${GST_BAD_OPTION} && make -j8 && make install
make && make install
if [ $? -ne 0 ]; then
        echo "Failed when building gst-plugins-bad!"
        exit -1
fi
echo "=============Build Compelted=============="
cd ..
}

build_gst_vaapi(){
echo "============Building gst-vaapi==========="
echo "Moving into ${GST_SRC_PATH}/gstreamer-vaapi/"
cd gstreamer-vaapi
#sudo make uninstall || true
#git pull && git clean -dxf
./autogen.sh --prefix=${GST_VAAPI} ${GST_VAAPI_OPTION} && make -j8 && make install
if [ $? -ne 0 ]; then
        echo "Failed when building gst-vaapi!"
        exit -1
fi
echo "=============Build Compelted============="
cd ..
}

build_gst_all(){
    build_gst
    build_gst_base
    build_gst_good
    build_gst_ugly
    build_gst_bad
    build_gst_vaapi
}

#init_gst
#gst_envinfo

