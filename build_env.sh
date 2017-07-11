#!/bin/bash
set -e
set -x

#This is current installing path
export workpath="/opt"

if [[ -d ${workpath} ]]; then
	cd ${workpath}
else
	mkdir ${workpath}
	cd ${workdpath}
fi

CURRENT_PATH=${workpath}
DAY=`date +"%Y-%m-%d-%H-%M"`


init()
{
echo "Installing basic system requirement..."
apt-get install g++ autoconf make libtool libdrm2 libdrm-intel1 libdrm-radeon1 libdrm-nouveau2 libdrm-dev texinfo 
#apt-get install libexpat-dev libxml2-dev
apt-get install libx11-dev libv4l-dev libegl-mesa-dev libglu1-mesa-dev mesa-common-dev libgles2-mesa-dev libbsd-dev libav-tools
#echo "Installing libffi as a part of wayland"
#git clone git://github.com/atgreen/libffi.git --single-branch
#cd libffi-3.1 && ./configure && make && make install && cd ..

#echo "Installing waylad..."
#git clone https://anongit.freedesktop.org/git/wayland/wayland.git --single-branch
#cd wayland && ./autogen.sh --prefix="/opt/" --disable-documentation && make && make install && cd ..

}


#All components are installed under /opt/
setenv()
{
export YAMI_ROOT_DIR="${CURRENT_PATH}/yami"
export VAAPI_PREFIX="${CURRENT_PATH}/vaapi"
export LIBYAMI_PREFIX="${YAMI_ROOT_DIR}/libyami"
ADD_PKG_CONFIG_PATH="${VAAPI_PREFIX}/lib/pkgconfig/:${LIBYAMI_PREFIX}/lib/pkgconfig/"
ADD_LD_LIBRARY_PATH="${VAAPI_PREFIX}/lib/:${LIBYAMI_PREFIX}/lib/"
ADD_PATH="${VAAPI_PREFIX}/bin"

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

echo "*=======================current configuration============================="
echo "* VAAPI_PREFIX:               $VAAPI_PREFIX"
echo "* LIBYAMI_PREFIX:             ${LIBYAMI_PREFIX}"
echo "* LD_LIBRARY_PATH:            ${LD_LIBRARY_PATH}"
echo "* PATH:                       $PATH"
echo "*========================================================================="

echo "* vaapi:      git clean -dxf && ./autogen.sh --prefix=\$VAAPI_PREFIX && make -j8 && make install"
echo "* libyami:    git clean -dxf && ./autogen.sh --prefix=\$LIBYAMI_PREFIX --enable-tests --enable-tests-gles && make -j8 && make install"
}


build_libva()
{   
    cd ${CURRENT_PATH}/
    if [[ -d "libva" ]];then
       	cd libva
       	if [[ ${LIBVA_TAG} ]]; then
       		git reset ${LIBVA_TAG} --hard
       	else
       		git pull
       	fi
       	git clean -dxf
       	cd ..
    else
    	if [[ ${LIBVA_TAG} ]]; then
    		git clone --single-branch https://github.com/01org/libva.git
    		git reset ${LIBVA_TAG} --hard
    		git clean -dxf
    		#git clone --branch ${LIBVA_TAG} --single-branch git://anongit.freedesktop.org/vaapi/libva
    	else
			git clone --single-branch https://github.com/01org/libva.git
			#git clone git://anongit.freedesktop.org/vaapi/libva
    	fi
    fi
    cd ${CURRENT_PATH}/libva
    echo  -e "\n---build ${CURRENT_PATH}/libva---\n"
    git clean -dxf && ./autogen.sh --prefix=$VAAPI_PREFIX && make -j8 &&  make install
    if [ $? -ne 0 ];then
        echo -e "build ${CURRENT_PATH}/libva  \t fail"
    else
        echo "build ${CURRENT_PATH}/libva ok"
    fi
    cd ..

    if [ -d "libva-utils" ];then
       	cd libva-utils
       	#make uninstall
       	if [[ ${LIBVA_UTILS_TAG} ]]; then
       		git reset ${LIBVA_UTILS_TAG} --hard
       	else
       		git pull
       	fi
       	git clean -dxf
       	cd ..
    else
    	if [[ ${LIBVA_UTILS_TAG} ]]; then
    		git clone --single-branch https://github.com/01org/libva-utils.git
    		git reset ${LIBVA_UTILS_TAG} --hard
    		git clean -dxf
    	else
		git clone --single-branch https://github.com/01org/libva-utils.git
    	fi
    fi

    #Install libva-utils
    cd ${CURRENT_PATH}/libva-utils
    echo -e "\n---Building ${CURRENT_PATH}/libva-utils---\n"
    git clean -dxf
    ./autogen.sh --prefix=${VAAPI_PREFIX} && ./configure && make && make install
    if [ $? -ne 0 ]; then
    	echo -e "Failed when building ${CURRENT_PATH}/libva-utils"
    else
    	echo "Building completed"
	if [ -z $LIBVA_UTILS_TAG ];then
		echo "built at tag $LIBVA_UTILS_TAG"
	fi
    fi
    cd ..


    if [ -d "intel-vaapi-driver" ];then
    	cd intel-vaapi-driver
    	if [[ ${INTEL_VAAPI_DRIVER_TAG} ]]; then
    		git reset ${INTEL_VAAPI_DRIVER_TAG} --hard
    	else
    		git pull
    	fi
    	git clean -dxf
    	cd ..
    else
    	if [[ ${INTEL_VAAPI_DRIVER_TAG} ]]; then
    		git clone --single-branch https://github.com/01org/intel-vaapi-driver.git
    		git reset ${INTEL_VAAPI_DRIVER_TAG} --hard
    		git clean -dxf
    	else
    		git clone --single-branch https://github.com/01org/intel-vaapi-driver.git
    		#git clone git://anongit.freedesktop.org/vaapi/intel-driver
    	fi
    fi

    cd ${CURRENT_PATH}/intel-vaapi-driver
    echo  -e "\n---build ${CURRENT_PATH}/intel-driver---\n"
    git clean -dxf && ./autogen.sh --prefix=$VAAPI_PREFIX --enable-wayland --enable-hybrid-codec && make -j8 &&  make install
    if [ $? -ne 0 ];then
        echo -e "build ${CURRENT_PATH}/intel-driver  \t fail"
    else
        echo "build ${CURRENT_PATH}/intel-driver ok"
    fi

    cd ${CURRENT_PATH}
}

build_cmrt_hybrid_driver()
{   
    cd ${CURRENT_PATH}/
    if [ -d "cmrt" ];then
    	cd cmrt
    	git pull
        cd ..
    else
    	git clone git://github.com/01org/cmrt.git
    fi
    if [ -d "intel-hybrid-driver" ];then
    cd intel-hybrid-driver
       git pull
    else
       git clone git://github.com/01org/intel-hybrid-driver.git
    fi    
    cd ${CURRENT_PATH}/cmrt
    echo  -e "\n---build ${CURRENT_PATH}/cmrt---\n"
    make uninstall
    git clean -dxf && ./autogen.sh --prefix=$VAAPI_PREFIX && make -j8 &&  make install
    if [ $? -ne 0 ];then
        echo -e "build ${CURRENT_PATH}/cmrt  \t fail" >> ${RESULT_LOG_FILE}
    else
        echo "build ${CURRENT_PATH}/cmrt ok"
    fi

    cd ${CURRENT_PATH}/intel-hybrid-driver
    echo  -e "\n---build ${CURRENT_PATH}/intel-hybrid-driver---\n"
    make uninstall
    git clean -dxf && ./autogen.sh --prefix=$VAAPI_PREFIX && make -j8 &&  make install
    if [ $? -ne 0 ];then
        echo -e "build ${CURRENT_PATH}/intel-hybrid_driver  \t fail" >> ${RESULT_LOG_FILE}
    else
        echo "build ${CURRENT_PATH}/intel-hybrid_driver ok"
    fi

    cd ${CURRENT_PATH}
}

build_ffmpeg()
{
    cd ${CURRENT_PATH}/
    if [ -d ffmpeg ];then
        cd ffmpeg
#        git pull
     else
     git clone git://source.ffmpeg.org/ffmpeg.git
     fi
     if [ $? -ne 0 ];then
       echo "git clone git://source.ffmpeg.org/ffmpeg.git  \t fail" >> ${RESULT_LOG_FILE}
    else
        echo "git clone git://source.ffmpeg.org/ffmpeg.git\t  ok"
    fi
    cd ${CURRENT_PATH}/ffmpeg
    echo  -e "\n---build ${CURRENT_PATH}/ffmpeg---\n"
#     git pull
    git clean -dxf && ./configure --prefix=$VAAPI_PREFIX && make -j8 && make install
    if [ $? -ne 0 ];then
        echo -e "build ${CURRENT_PATH}/ffmpeg  \t fail" >> ${RESULT_LOG_FILE}
    else
        echo "build ${CURRENT_PATH}/ffmpeg ok"
    fi
}

build_libyami_internal()
{
	cd $CURRENT_PATH
       	if [ -d libyami ]; then
			cd libyami
		else
	       	git clone https://github.com/01org/libyami.git --single-branch
       		cd libyami
       	fi
		
		echo  -e "\n---build ${CURRENT_PATH}/libyami---\n"
    	
    	if [[ ${LIBYAMI_TAG} ]]; then
    		git reset ${LIBYAMI_TAG} --hard
    		git clean -dxf
    		./autogen.sh --prefix=$LIBYAMI_PREFIX --enable-vp8dec --enable-vp9dec --enable-jpegdec --enable-h264dec --enable-h265dec --enable-h264enc --enable-jpegenc --enable-vp8enc --enable-h265enc --enable-mpeg2dec --enable-vc1dec --enable-mpeg2dec --enable-vc1dec --enable-vp9enc --enable-v4l2 && make -j8 && make install
	   	else
           	#git clean -dxf && ./autogen.sh --prefix=$LIBYAMI_PREFIX --enable-vp8dec --enable-vp9dec --enable-jpegdec --enable-h264dec --enable-h265dec --enable-h264enc --enable-jpegenc --enable-vp8enc --enable-h265enc --enable-mpeg2dec --enable-vc1dec --enable-mpeg2dec --enable-vc1dec --enable-vp9enc --enable-wayland && make -j8 && make install
           	git clean -dxf && ./autogen.sh --prefix=$LIBYAMI_PREFIX --enable-vp8dec --enable-vp9dec --enable-jpegdec --enable-h264dec --enable-h265dec --enable-h264enc --enable-jpegenc --enable-vp8enc --enable-h265enc --enable-mpeg2dec --enable-vc1dec --enable-mpeg2dec --enable-vc1dec --enable-vp9enc --enable-v4l2 && make -j8 && make install
        fi

        if [ $? -ne 0 ];then
        	echo -e "Failed when building ${CURRENT_PATH}/libyami" >> ${RESULT_LOG_FILE}
        else
        	echo "Building ${CURRENT_PATH}/libyami completed"
        fi

        if [[ ${LIBYAMI_TAG} ]]; then
        	echo "Built at tag ${LIBYAMI_TAG}"
        fi


 }

build_libyami_utils()
{
       	cd ${CURRENT_PATH}
       	if [ -d libyami-utils ]; then
			cd libyami-utils
		else
	       	git clone https://github.com/01org/libyami-utils.git --single-branch
       		cd libyami-utils
       	fi


        echo  -e "\n---build ${CURRENT_PATH}/libyami-utils ---\n"
        if [[ ${LIBYAMI_UTILS_TAG} ]]; then
        	git reset ${LIBYAMI_UTILS_TAG} --hard
        	git clean -dxf
	     	./autogen.sh --prefix=$LIBYAMI_PREFIX --enable-dmabuf --enable-v4l2 --enable-tests-gles --enable-avformat && make -j8 && make install
        else
			git clean -dxf && ./autogen.sh --prefix=$LIBYAMI_PREFIX --enable-dmabuf --enable-v4l2 --enable-tests-gles --enable-avformat && make -j8 && make install

			#git clean -dxf && ./autogen.sh --prefix=$LIBYAMI_PREFIX --enable-dmabuf --enable-capi --enable-tests-gles --enable-avformat && make -j8 && make install
			 
	      	#git clean -dxf && ./autogen.sh --prefix=$LIBYAMI_PREFIX --enable-dmabuf --enable-avformat --enable-tests-gles --enable-wayland && make -j8 && make install
		fi


        if [ $? -ne 0 ];then
            echo -e "Failed when building ${CURRENT_PATH}/libyami-utils" >> ${RESULT_LOG_FILE}
        else
            echo "Building ${CURRENT_PATH}/libyami-utils completed"
        fi

        if [[ ${LIBYAMI_UTILS_TAG} ]]; then
        	echo "Built at tag ${LIBYAMI_UTILS_TAG}"
        fi
}

show_details()
{
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

function update_datebase_yamiinfo()
{
        cd ${CURRENT_PATH}/libyami
        full_commit=`git log --pretty=oneline -1 |awk '{print $1}'`
        cd ${ROOT_DB_PATH}

        id_flag=`sqlite3 $DBNAME "select id from build_yami where date_time='${server_day}'";`
        mysql_flag=`echo "select id from build_yami where date_time='${server_day}'" | mysql -h ${DATABASE_SERVER_NAME} -u${DATABASE_USER} -p${DATABASE_PW} ${DATABASE_NAME}`
        #mysql_flag=`echo ${mysql_flag} | awk 'NR==2{print $1}'`
        mysql_flag=`echo ${mysql_flag} | awk '{print $2}'`

        if [ -z ${id_flag} ];then
                sqlite3 $DBNAME "insert into build_yami(machine_name,commit_num,date_time) values('${hostname}','${full_commit}','${server_day}');"
        else
                sqlite3 $DBNAME "update build_yami set commit_num='${full_commit}' where (id='${id_flag}');"
        fi


        if [ -z ${mysql_flag} ];then
            echo "insert into build_yami(machine_name,commit_num,date_time) values('${hostname}','${full_commit}','${server_day}');" | mysql -h ${DATABASE_SERVER_NAME} -u${DATABASE_USER} -p${DATABASE_PW} ${DATABASE_NAME}
        else
            echo "update build_yami set commit_num='${full_commit}' where (id='${mysql_flag}');" | mysql -h ${DATABASE_SERVER_NAME} -u${DATABASE_USER} -p${DATABASE_PW} ${DATABASE_NAME}
        fi

}
while [ $# -gt 0 ]
do
	case $1 in
		-v|--version )
		shift
		while [ $# -gt 1]
		do
			case $1 in
				libyami )
				LIBYAMI_TAG="$2"
				shift 2
					;;
				
				libva )
				LIBVA_TAG="$2"
				shift 2
					;;

				libva—utils )
				LIBVA_UTILS_TAG="$2"
				shift 2
					;;

				intel-vaapi-driver )
				INTEL_VAAPI_DRIVER_TAG="$2"
				shift 2
					;;

				libyami_utils )
				LIBYAMI_UTILS_TAG="$2"
				shift 2
					;;

				* )
				echo "Unknown component name!"
				echo "Usage: -v|--version [COMPONENT_NAME] [GIT_TAG|COMMIT]"
				echo "Components include libyami, libyami_utils, libva, intel-vaapi-driver"
					;;
			esac
		done
			;;

		-u|--update)
		shift

		if [[ $#=1 ]]; then
			read -r -p "Update all components? [Y/n]" reply
			if [[ "$reply" =~ ^[Yy]$ ]]; then
				UPDATE_FLAG=0
		fi

		else
			while [ $# -gt 1]
			do
				case $1 in
					libyami)
					UPDATE_FLAG=1
					shift 2
						;;
					
					libva)
					UPDATE_FLAG=2
					shift 2
						;;

					libva—utils )
					UPDATE_FLAG=3
					shift 2
						;;

					intel-vaapi-driver)
					UPDATE_FLAG=4
					shift 2
						;;

					libyami_utils)
					UPDATE_FLAG=5
					shift 2
						;;

					* )
					echo "Unknown component name!"
					echo "Usage: -u|--update [COMPONENT_NAME]"
					echo "Components include libyami, libyami_utils, libva, intel-vaapi-driver"
					break
						;;
				esac
			done
		fi
			;;

		-i|--initialize )
		shift
		echo "Initializing basic environment for new machine..."
		init
		echo "Initialization completed!"
			;;

		* )
		shift
		echo "Unknown argument!"
		echo "Usage: -v|--version [COMPONENT_NAME] [GIT_TAG|COMMIT]"
		echo "       -u|--update [COMPONENT_NAME] (default: update all components)"
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
			git pull && git clean -dxf && ./autogen.sh --prefix=$LIBYAMI_PREFIX --enable-vp8dec --enable-vp9dec --enable-jpegdec --enable-h264dec --enable-h265dec --enable-h264enc --enable-jpegenc --enable-vp8enc --enable-h265enc --enable-mpeg2dec --enable-vc1dec --enable-mpeg2dec --enable-vc1dec --enable-vp9enc --enable-v4l2 && make -j8 && make install
			echo -e "\nupdate ${CURRENT_PATH}/libyami done"
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
			git pull && git clean -dxf && ./autogen.sh --subdir-objects --prefix=$VAAPI_PREFIX --enable-wayland && make -j8 &&  make install
			echo -e "\nupdate ${CURRENT_PATH}/libva done"
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
			#echo -e "\nupdate ${CURRENT_PATH}/libva-utils done"
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
			echo -e "\nupdate ${CURRENT_PATH}/intel-vaapi-driver done"
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
			echo -e "\nupdate ${CURRENT_PATH}/libva—utils done"
		fi
			;;

		*)
		echo -e "Error: Unknown update component!"
			;;
	esac
}

setenv
if [[-z ${UPDATE_FLAG}]]; then
	update
else
#	build_libva
	echo
fi

#build_cmrt_hybrid_driver
build_ffmpeg
#build_libyami_internal
build_libyami_utils
show_details
#update_datebase_yamiinfo
