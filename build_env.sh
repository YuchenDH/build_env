#!/bin/bash
#set -e
set -x

#This is current installing path
export workpath="/opt/test"

if [[ -d ${workpath} ]]; then
	cd ${workpath}
else
	mkdir ${workpath}
	cd ${workdpath}
fi

CURRENT_PATH=${workpath}
DAY=`date +"%Y-%m-%d-%H-%M"`

export ENABLE_VAAPI=true
export ENABLE_YAMI=true
export ENABLE_GST=false
export INIT_FLAG=false

#libva installation configuration
export VAAPI_ROOT_DIR="${CURRENT_PATH}"
export VAAPI_PREFIX="${CURRENT_PATH}/vaapi"
export INTEL_VAAPI_DRIVER_OPTION="--enable-wayland --enable-hybrid-codec"
export LIBVA_OPTION=""

#libyami installation configuration
export YAMI_ROOT_DIR="${CURRENT_PATH}/yami"
export LIBYAMI_PREFIX="${YAMI_ROOT_DIR}/libyami"
export LIBYAMI_OPTION="--enable-vp8dec --enable-vp9dec --enable-jpegdec --enable-h264dec --enable-h265dec \
					   --enable-h264enc --enable-jpegenc --enable-vp8enc --enable-h265enc --enable-mpeg2dec \
					   --enable-vc1dec --enable-mpeg2dec --enable-vc1dec --enable-vp9enc --enable-v4l2"
export LIBYAMI_UTILS_OPTION="--enable-dmabuf --enable-v4l2 --enable-tests-gles --enable-avformat"

#gst installlation configuration
export GST_SRC_PATH="$workpath/src/gstreamer"
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

export FORCE=false

showhelp()
{
	echo "Usage: -v|--version [COMPONENT_NAME] [GIT_TAG|COMMIT]	Changing version of specified components"
	echo "		 -f|--force 									Force re-installation or update"
	echo "       -u|--update [COMPONENT_NAME] 					Update the specified componnets to latest commit. If not specified, update all enabled components"
	echo
	echo "       -s|--sourcing 									Generate and update pathcontrol.env file in workpath. "
	echo "														Note that sourcing is only available within this script. For out-of-this-program usage of components, "
	echo "														please do \"source $workpath/pathcontrol.env\""
	echo
	echo "		 --status										Show current installation details."
	echo "       -i|--initialize								Initial install for fresh-installed linux"
	echo "		 --disable-vaapi								Will NOT install libva, libva-utils, intel-vaapi-driver. Set to YES by default."
	echo "       --enable-gstreamer								Will install gstreamer10, gstreamer-plugins, gstreamer-vaapi. Set to NO by default"
	echo "		 --disable-yami									Will NOT install libyami, libyami-utils. Set to YES by default"
}

init()
{
	echo "==========Installing basic system requirement=========="
	apt-get install -y --force-yes g++ autoconf make libtool libdrm2 libdrm-intel1 libdrm-radeon1 \
					libdrm-nouveau2 libdrm-dev texinfo build-essential intel-gpu-tools
	#apt-get install libexpat-dev libxml2-dev
	apt-get install -y --force-yes libx11-dev libv4l-dev libegl-mesa-dev \
					libglu1-mesa-dev mesa-common-dev libgles2-mesa-dev \
					libbsd-dev libav-tools
	#installing requirements for libyami
	apt-get install -y --force-yes libavcodec-dev libavformat-dev libswscale-dev libavutil-dev

	#echo "Installing libffi as a part of wayland"
	#git clone git://github.com/atgreen/libffi.git --single-branch
	#cd libffi-3.1 && ./configure && make && make install && cd ..

	#echo "Installing waylad..."
	#git clone https://anongit.freedesktop.org/git/wayland/wayland.git --single-branch
	#cd wayland && ./autogen.sh --prefix="/opt/" --disable-documentation && make && make install && cd ..
}

init_gst(){
	# Update and Upgrade the Pi, otherwise the build may fail due to inconsistencies
	grep -q BCM2708 /proc/cpuinfo && sudo apt-get update && sudo apt-get upgrade -y --force-yes

	# Get the required libraries
	apt-get install -y --force-yes 	build-essential autotools-dev \
	                                libtool autopoint libxml2-dev zlib1g-dev libglib2.0-dev \
	                                pkg-config bison flex python3 gtk-doc-tools libasound2-dev \
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

sourcing()
{
	ADD_PKG_CONFIG_PATH="${VAAPI_PREFIX}/lib/pkgconfig/:${LIBYAMI_PREFIX}/lib/pkgconfig/"
	ADD_LD_LIBRARY_PATH="${VAAPI_PREFIX}/lib/:${LIBYAMI_PREFIX}/lib/"
	ADD_PATH="${VAAPI_PREFIX}/bin/:${LIBYAMI_PREFIX}/bin/"

	PLATFORM_ARCH_64=`uname -a | grep x86_64`
	if [ -n "$PKG_CONFIG_PATH" ]; then
    		export PKG_CONFIG_PATH="${ADD_PKG_CONFIG_PATH}:$PKG_CONFIG_PATH"
	elif [ -n "$PLATFORM_ARCH_64" ]; then
    		export PKG_CONFIG_PATH="${ADD_PKG_CONFIG_PATH}:/usr/lib/pkgconfig/:/usr/lib/i386-linux-gnu/pkgconfig/"
	else
    		export PKG_CONFIG_PATH="${ADD_PKG_CONFIG_PATH}:/usr/lib/pkgconfig/:/usr/lib/x86_64-linux-gnu/pkgconfig/"
	fi

	export LD_LIBRARY_PATH="${ADD_LD_LIBRARY_PATH}:$LD_LIBRARY_PATH"

	export PATH="${ADD_PATH}:$PATH"

	echo "*=======================Current VAAPI & yami Config========================"
	echo "* VAAPI_PREFIX:               $VAAPI_PREFIX"
	echo "* LIBYAMI_PREFIX:             ${LIBYAMI_PREFIX}"
	echo "* LD_LIBRARY_PATH:            ${LD_LIBRARY_PATH}"
	echo "* PATH:                       $PATH"
	echo "*=========================================================================="
	
	if [[ $ENABLE_GST==true ]]; then
		export PATH=${GSTREAMER_INSTALL_PATH}/bin:$PATH
		export LD_LIBRARY_PATH=/opt/X11R7/glib/lib:/opt/X11R7/x264/lib:/opt/X11R7/ffmpeg/lib:${GSTREAMER_INSTALL_PATH}/lib:$LD_LIBRARY_PATH
		export PKG_CONFIG_PATH=${GSTREAMER_INSTALL_PATH}/lib/pkgconfig:$PKG_CONFIG_PATH
		export GST_PLUGIN_PATH=${GSTREAMER_INSTALL_PATH}/lib/gstreamer-1.0

		echo "====================Current gstreamer Config============================="
		echo "GST_PREFIX		  	  		${GST_PREFIX}"
		echo "GST_BASE_PREFIX				${GST_BASE_PREFIX}"
		echo "GST_GOOD_PREFIX				${GST_GOOD_PREFIX}"
		echo "GST_UGLY_PREFIX				${GST_UGLY_PREFIX}"
		echo "GST_BAD_PREFIX				${GST_BAD_PREFIX}"
		echo "GST_VAAPI_PREFIX				${GST_VAAPI_PREFIX}"
		echo "========================================================================="
	fi

	if [[ -s pathcontrol.env ]]; then
		echo "LD_LIBRARY_PATH=$LD_LIBRARY_PATH" > pathcontrol.env
		echo "PKG_CONTROL_PATH=$PKG_CONFIG_PATH" >> pathcontrol.env
		echo "PATH=$PATH" >> pathcontrol.env
		echo "export LD_LIBRARY_PATH PKG_CONFIG_PATH PATH">> pathcontrol.env
	fi
}

setenv()
{
	sourcing
	if [[ $ENABLE_VAAPI==true ]]; then
		echo "* vaapi:      git clean -dxf && ./autogen.sh --prefix=$VAAPI_PREFIX && make -j8 && make install"

	fi

	if [[ $ENABLE_YAMI==true ]]; then
		echo "* libyami:    git clean -dxf && ./autogen.sh --prefix=$LIBYAMI_PREFIX --enable-tests --enable-tests-gles && make -j8 && make install"
	fi

	if [[ $ENABLE_GST==true ]]; then
		echo "gstreamer: git clean -dxf && ./autogen.sh --prefix=${GST_PREFIX} ${GST_OPTION} && make -j32 && make install"
		echo "gst_base: git clean -dxf && ./autogen.sh --prefix=${GST_BASE_PREFIX} ${GST_BASE_OPTION} && make -j32 && make install"
		echo "gst_good: git clean -dxf && ./autogen.sh --prefix=${GST_GOOD_PREFIX} ${GST_GOOD_OPTION} && make -j32 && make install"
		echo "gst_ugly: git clean -dxf && ./autogen.sh --prefix=${GST_UGLY_PREFIX} ${GST_UGLY_OPTION} && make -j32 && make install"
		echo "gst_bad: git clean -dxf && ./autogen.sh --prefix=${GST_BAD_PREFIX} ${GST_BAD_OPTION} && make -j8 && make install"
		echo "gst_vaapi: git clean -dxf && ./autogen.sh --prefix=${GST_VAAPI} ${GST_VAAPI_OPTION} && make -j8 && make install"
		echo "Source files are stored in ${GST_SRC_PATH}"
	fi
}



build_libva()
{   
    cd ${CURRENT_PATH}/
    if [[ -d "libva" ]];then
       	cd libva
       	git pull && git clean -dxf
       	cd ..
    else
	git clone --single-branch https://github.com/01org/libva.git
    fi

    cd ${CURRENT_PATH}/libva
    if [[ -n $LIBVA_TAG ]]; then
    	git reset $LIBVA_TAG --hard
    fi

    echo  -e "\n---build ${CURRENT_PATH}/libva---\n"
    git clean -dxf && ./autogen.sh --prefix=$VAAPI_PREFIX && make -j8 &&  make install
    if [ $? -ne 0 ];then
        echo -e "build ${CURRENT_PATH}/libva  \t fail"
    else
        echo "build ${CURRENT_PATH}/libva ok"
    fi
    cd ..

    if [[ -d "libva-utils" ]];then
		cd libva-utils
		git pull && git clean -dxf
		cd ..
	else
		git clone --single-branch https://github.com/01org/libva-utils.git
    fi

    cd ${CURRENT_PATH}/libva-utils
    if [[ -n $LIBVA_UTILS_TAG ]]; then
    	git reset $LIBVA_UTILS_TAG --hard
    fi

    #Install libva-utils
    echo -e "\n---Building ${CURRENT_PATH}/libva-utils---\n"
    git clean -dxf && ./autogen.sh --prefix=${VAAPI_PREFIX} && ./configure && make && make install
    if [ $? -ne 0 ]; then
    	echo -e "Failed when building ${CURRENT_PATH}/libva-utils"
    else
    	echo "Building completed"
	if [[ -n $LIBVA_UTILS_TAG ]];then
		echo "built at tag $LIBVA_UTILS_TAG"
	fi
    fi
    cd ..


    if [[ -d "intel-vaapi-driver" ]];then
    	cd intel-vaapi-driver
    	git clean -dxf && git pull
    	cd ..
    else
    	git clone --single-branch https://github.com/01org/intel-vaapi-driver.git
    	#git clone git://anongit.freedesktop.org/vaapi/intel-driver
    fi

    cd ${CURRENT_PATH}/intel-vaapi-driver

    if [[ $INTEL_VAAPI_DRIVER_TAG ]]; then
    	git reset $INTEL_VAAPI_DRIVER_TAG --hard
    fi

    echo  -e "\n---build ${CURRENT_PATH}/intel-driver---\n"
    git clean -dxf && ./autogen.sh --prefix=$VAAPI_PREFIX $INTEL_VAAPI_DRIVER_OPTION && make -j8 &&  make install
    if [ $? -ne 0 ];then
        echo -e "build ${CURRENT_PATH}/intel-driver  \t fail"
    else
        echo "build ${CURRENT_PATH}/intel-driver ok"
    fi

    cd ${CURRENT_PATH}
}

build_libyami_internal()
{
    cd $CURRENT_PATH
    if [[ -d libyami ]]; then
        cd libyami
    else
        git clone https://github.com/01org/libyami.git --single-branch
       	cd libyami
    fi

    echo  -e "\n---build ${CURRENT_PATH}/libyami---\n"

    [[ ${LIBYAMI_TAG} ]] && git reset ${LIBYAMI_TAG} --hard

    git clean -dxf && ./autogen.sh --prefix=$LIBYAMI_PREFIX $LIBYAMI_OPTION && make -j8 && make install

    if [ $? -ne 0 ];then
       	echo -e "Failed when building ${CURRENT_PATH}/libyami" >> ${RESULT_LOG_FILE}
    else
       	echo "Building ${CURRENT_PATH}/libyami completed"
    fi

    [[ ${LIBYAMI_TAG} ]] && echo "Built at tag ${LIBYAMI_TAG}"
 }

build_libyami_utils()
{
       	cd ${CURRENT_PATH}
       	[ -d libyami-utils ] && echo || git clone https://github.com/01org/libyami-utils.git --single-branch
       	cd libyami-utils

        echo  -e "\n---build ${CURRENT_PATH}/libyami-utils ---\n"
        
        [[ ${LIBYAMI_UTILS_TAG} ]] && git reset ${LIBYAMI_UTILS_TAG} --hard

		git clean -dxf && ./autogen.sh --prefix=$LIBYAMI_PREFIX $LIBYAMI_UTILS_OPTION && make -j8 && make install


        if [ $? -ne 0 ];then
            echo -e "Failed when building ${CURRENT_PATH}/libyami-utils" >> ${RESULT_LOG_FILE}
        else
            echo "Building ${CURRENT_PATH}/libyami-utils completed"
        fi

        if [[ ${LIBYAMI_UTILS_TAG} ]]; then
        	echo "Built at tag ${LIBYAMI_UTILS_TAG}"
        fi
}

show_details(){
	#GET SW DETAILS VERSIOB:
	cd ${CURRENT_PATH}/libva
	libva_ver=`git log |head -n 5 |grep commit|less |awk '{print $2}'`
	cd ${CURRENT_PATH}/intel-vaapi-driver
	intel_driver_ver=`git log |head -n 5 |grep commit|less |awk '{print $2}'`
	#cd ${CURRENT_PATH}/cmrt
	#cmrt_ver=`git log |head -n 5 |grep commit|less |awk '{print $2}'`
	#cd ${CURRENT_PATH}/intel-hybrid-driver
	#hybrid_ver=`git log |head -n 5 |grep commit|less |awk '{print $2}'`
	#cd ${CURRENT_PATH}/ffmpeg
	#ffmpeg_ver=`git log |head -n 5 |grep commit|less |awk '{print $2}'`
	cd ${CURRENT_PATH}/libyami
	libyami_ver=`git log |head -n 5 |grep commit|less |awk '{print $2}'`
	echo "libyami build SW ditials list:" > /yami_env
	echo "libva=$libva_ver" >> /yami_env
	echo "intel_driver=$intel_driver_ver" >> /yami_env
	#echo "cmrt=$cmrt_ver" >> /yami_env
	#echo "intel_hybrid_driver=$hybrid_ver" >> /yami_env
	#echo "ffmpeg=$ffmpeg_ver" >> /yami_env
	echo "libyami=$libyami_ver" >> /yami_env
}

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

while [ $# -gt 0 ]
do
	case $1 in
		--enable-gstreamer|--enable-gst )
		shift
		ENABLE_GST=true
			;;

		--disable-vaapi )
		shift
		ENABLE_VAAPI=false
			;;

		--disable-yami )
		shift
		ENABLE_YAMI=false
			;;

		-v|--version )
		shift
		while [ $# -gt 1]
		do
			case $1 in
				libyami )
				export LIBYAMI_TAG="$2"
				shift 2
					;;
				
				libva )
				export LIBVA_TAG="$2"
				shift 2
					;;

				libva—utils )
				export LIBVA_UTILS_TAG="$2"
				shift 2
					;;

				intel-vaapi-driver )
				export INTEL_VAAPI_DRIVER_TAG="$2"
				shift 2
					;;

				libyami_utils )
				export LIBYAMI_UTILS_TAG="$2"
				shift 2
					;;

				gst-vaapi|gstreamer-vaapi )
				export GST_VAAPI_TAG="$2"
				shift 2
					;;

				* )
				break
					;;
			esac
		done
			;;

		-f|--force )
		shift
		FORCE=true
			;;

		-u|--update )
		shift

		if [[ $#=1 ]]; then
			read -r -p "Update all components? [Y/n]" reply
			[[ "$reply" =~ ^[Yy]$ ]] && UPDATE_FLAG=0 || echo "Please re-type your command." && exit 1
		

		else
			while [ $# -gt 1]
			do
				case $1 in
					libyami )
					UPDATE_FLAG=1
					shift 2
						;;
					
					libva )
					UPDATE_FLAG=2
					shift 2
						;;

					libva—utils )
					UPDATE_FLAG=3
					shift 2
						;;

					intel-vaapi-driver )
					UPDATE_FLAG=4
					shift 2
						;;

					libyami_utils )
					UPDATE_FLAG=5
					shift 2
						;;

					gst_vaapi )
					UPDATE_FLAG=6
					shift 2
						;;

					* )
					echo "Unknown component name!"
					echo "Usage: -u|--update [COMPONENT_NAME]"
					echo "Components include libyami, libyami_utils, libva, intel-vaapi-driver, gst_vaapi"
					exit -1
						;;
				esac
			done
		fi
			;;
		
		-s|--source )
		shift
		echo "Sourcing..."
		sourcing
		exit 0
			;;
		
		-i|--initialize )
		shift
		INIT_FLAG=true
			;;

		--status )
		show_details
			;;

		* )
		shift
		echo "Unknown argument!"
		showhelp
		exit -1
		break
			;;
	esac
done

update()
{
	case UPDATE_FLAG in
		0)
		#update_all
			;;

		1)
		echo  -e "\n---update ${CURRENT_PATH}/libyami---\n"
		cd ${CURRENT_PATH}/libyami
		git fetch
		if [[ $(git rev-parse HEAD) == $(git rev-parse @{u}) ]]; then
			echo "${CURRENT_PATH}/libyami already up-tp-date."
		else
			git pull && git clean -dxf && ./autogen.sh --prefix=$LIBYAMI_PREFIX $LIBYAMI_OPTION && make -j8 && make install
			if [ $? -ne 0 ]; then
        		echo "Failed when building libyami!"
        		exit -1
			fi
			echo -e "\nupdate ${CURRENT_PATH}/libyami completed"
		fi
			;;

		2)
		echo -e "\n---update ${CURRENT_PATH}/libva---\n"
		cd ${CURRENT_PATH}/libva
		make uninstall
		git fetch
		if [[ $(git rev-parse HEAD) == $(git rev-parse @{u}) ]]; then
			echo "${CURRENT_PATH}/libva already up-tp-date."
		else
			git pull && git clean -dxf && ./autogen.sh --subdir-objects --prefix=$VAAPI_PREFIX $LIBVA_OPTION && make -j8 &&  make install
			if [ $? -ne 0 ]; then
        		echo "Failed when building libva!"
        		exit -1
			fi
			echo -e "\nupdate ${CURRENT_PATH}/libva completed"
		fi
			;;

		3)
		echo -e "\n---update ${CURRENT_PATH}/libva—utils---\n"
		cd ${CURRENT_PATH}/libva—utils
		#make uninstall
		git fetch
		if [[ $(git rev-parse HEAD) == $(git rev-parse @{u}) ]]; then
			echo "${CURRENT_PATH}/libva already up-tp-date."
			git clean -dxf
			#make install
		else
			git pull && git clean -dxf
			#make install
			if [ $? -ne 0 ]; then
        		echo "Failed when building libva-utils!"
        		exit -1
			fi
			#echo -e "\nupdate ${CURRENT_PATH}/libva-utils completed"
		fi
			;;

		4)
		echo -e "\n---update ${CURRENT_PATH}/intel-vaapi-driver---\n"
		cd ${CURRENT_PATH}/intel-vaapi-driver
		#make uninstall
		git fetch
		if [[ $(git rev-parse HEAD) == $(git rev-parse @{u}) ]]; then
			echo "${CURRENT_PATH}/intel-vaapi-driver already up-tp-date."
    		./autogen.sh --prefix=$VAAPI_PREFIX --enable-wayland --enable-hybrid-codec && make -j8 &&  make install
		else
			git pull && git clean -dxf
    		./autogen.sh --prefix=$VAAPI_PREFIX --enable-wayland --enable-hybrid-codec && make -j8 &&  make install
			if [ $? -ne 0 ]; then
        		echo "Failed when building intel-vaapi-driver!"
        		exit -1
			fi
			echo -e "\nupdate ${CURRENT_PATH}/intel-vaapi-driver completed"
		fi
			;;

		5)
		echo  -e "\n---build ${CURRENT_PATH}/libyami-utils ---\n"
		cd ${CURRENT_PATH}/libyami-utils
		git fetch
		if [[ $(git rev-parse HEAD) == $(git rev-parse @{u}) ]]; then
			echo "${CURRENT_PATH}/intel-vaapi-driver already up-tp-date."
		else
			git pull && git clean -dxf && ./autogen.sh --prefix=$LIBYAMI_PREFIX --enable-dmabuf --enable-v4l2 --enable-tests-gles --enable-avformat && make -j8 && make install
			if [ $? -ne 0 ]; then
        		echo "Failed when building libva-utils!"
        		exit -1
			fi
			echo -e "\nupdate ${CURRENT_PATH}/libva—utils completed"
		fi
			;;

		6)
		echo -e "\n---build ${GST_SRC_PATH}/gstreamer-vaapi/ ---\n"
		cd ${GST_SRC_PATH}/gstreamer-vaapi
		git fetch
		if [[ $(git rev-parse HEAD) == $(git rev-parse @{u}) ]]; then
			echo "${GST_SRC_PATH}/gstreamer-vaapi is already up-tp-date."
		else
			git pull && git clean -dxf && ./autogen.sh --prefix=${GST_VAAPI} ${GST_VAAPI_OPTION} && make -j8 && make install
			if [ $? -ne 0 ]; then
        		    echo "Failed when building gst-vaapi!"
        		    exit -1
			fi
			echo -e "\nupdate ${CURRENT_PATH}/libva—utils completed"
		fi
		;;

		*)
		    echo -e "Error: Unknown update component!"
		    exit -1
		;;
	esac
}

setenv

if [[ $INIT_FLAG == true ]]; then
	[[ $ENABLE_GST == true ]] && init_gst
	init
fi

[[ -n ${UPDATE_FLAG} ]] && update

[[ ${ENABLE_VAAPI} == true ]] && build_libva

[[ ${ENABLE_YAMI} == true ]] && build_libyami_internal; build_libyami_utils

if [[ ${ENABLE_GST} == true ]]; then
	#cd $workpath
	#[ ! -d ${GST_SRC_PATH} ] && mkdir ${GST_SRC_PATH}
	#cd ${GST_SRC_PATH}

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

	build_gst_all
fi

show_details
