#!/bin/bash
#set -e
set -x

#This is path of this file
export folder=`pwd`

#This is current installing path
export CURRENT_PATH="/opt/test"

[[ ! -d ${CURRENT_PATH} ]]; mkdir ${CURRENT_PATH}

ENV_FILE="$CURRENT_PATH/media.env"
LOG_FILE="$CURRENT_PATH/log"
DAY=`date +"%Y-%m-%d-%H-%M"`

#default enable plan
export ENABLE_VAAPI=true
export ENABLE_YAMI=true
export ENABLE_GST=false

#default ommitting initialization
export INIT_FLAG=false

#default ommitting installed components
export FORCE=false

#default dependency
export DEP_FILE=ubuntu.dep

#libva installation configuration
export VAAPI_ROOT_DIR="${CURRENT_PATH}/libva"
export VAAPI_PREFIX="${CURRENT_PATH}/vaapi"
export LIBVA_GIT="https://github.com/01org/libva.git"
export LIBVA_UTILS_GIT="https://github.com/01org/libva-utils.git"
export INTEL_VAAPI_DRIVER_GIT="https://github.com/01org/intel-vaapi-driver.git"
export LIBVA_OPTION=" "
export LIBVA_UTILS_OPTION=" "
export INTEL_VAAPI_DRIVER_OPTION="--enable-wayland --enable-hybrid-codec"

#libyami installation configuration
export YAMI_ROOT_DIR="${CURRENT_PATH}/libyami"
export LIBYAMI_GIT="https://github.com/01org/libyami.git"
export LIBYAMI_UTILS_GIT="https://github.com/01org/libyami-utils.git"
export LIBYAMI_PREFIX="${CURRENT_PATH}/yami"
export LIBYAMI_OPTION="--enable-vp8dec --enable-vp9dec --enable-jpegdec --enable-h264dec --enable-h265dec \
                       --enable-h264enc --enable-jpegenc --enable-vp8enc --enable-h265enc --enable-mpeg2dec \
                       --enable-vc1dec --enable-mpeg2dec --enable-vc1dec --enable-vp9enc --enable-v4l2"
export LIBYAMI_UTILS_OPTION="--enable-dmabuf --enable-v4l2 --enable-tests-gles --enable-avformat"

#gst installlation configuration
export GST_SRC_PATH="$CURRENT_PATH/gstreamer"
export GSTREAMER_INSTALL_PATH="/opt/test/X11R7/gstreamer10"
#get repos if they are not there yet
export GSTRAMER_GIT="git://anongit.freedesktop.org/git/gstreamer/gstreamer.git"
export GST_BASE_GIT="git://anongit.freedesktop.org/git/gstreamer/gst-plugins-base.git"
export GST_GOOD_GIT="git://anongit.freedesktop.org/git/gstreamer/gst-plugins-good.git"
export GST_BAD_GIT="git://anongit.freedesktop.org/git/gstreamer/gst-plugins-bad.git"
export GST_UGLY_GIT="git://anongit.freedesktop.org/git/gstreamer/gst-plugins-ugly.git"
export GST_VAAPI_GIT="git://anongit.freedesktop.org/git/gstreamer/gstreamer-vaapi.git"

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
export QUICK_INSTALL=""

showhelp()
{
    echo "###################################################################################"
    echo "#                                                                                 #"
    echo "#             Author: Yuchen Wang, SJTU Capstone Design with Intel 2017           #"
    echo "#                                                                                 #"
    echo "#             Co-authored with Fei Wang                                           #"
    echo "#                                                                                 #"
    echo "###################################################################################"
    echo "#                                                                                 #"
    echo "#          Important: Please try to follow the order of options as given!         #"
    echo "#                                                                                 #"
    echo "#      If any kind of missing package error occurred, try adding -i option        #"
    echo "#                                                                                 #"
    echo "###################################################################################"

    echo "Usage: -v|--version [COMPONENT_NAME] [GIT_TAG|COMMIT] Changing version of specified components"
    echo "       --disable-vaapi                                Will NOT install libva, libva-utils, intel-vaapi-driver. Set to YES by default."
    echo "       --enable-gstreamer                             Will install gstreamer10, gstreamer-plugins, gstreamer-vaapi. Set to NO by default"
    echo "       --disable-yami                                 Will NOT install libyami, libyami-utils. Set to YES by default"
    echo "       -f|--force                                     Force re-installation or update"
    echo "       -q|--quick                                     Enable quick install by adding --single-branch as git option"
    echo "       -u|--update [COMPONENT_NAME|all]               Update the specified componnets to latest commit."
    echo
    echo "       -e|--env                                       Generate and update $ENV_FILE file in workpath. "
    echo "                                                      Note that sourcing is only available within this script. For out-of-this-program  "
    echo "                                                      usage of components, please do \"source $ENV_FILE\""
    echo
    echo "       --status                                       Show current installation details. Also generates $LOG_FILE"
    echo "       -i|--initialize [DEPENDENCY_FILE]              Initial install for fresh-installed OS. Add --enable-gstreamer to install gst dependency."
    echo "                                                      gst dependency should be named separately by adding \".gst\""
    echo "                                                      Name example: ubuntu16.04.dep & ubuntu16.04.dep.gst"
    echo "       -f|--force                                     Force Re-installation even when source code folder is up-to-date"
}

init()
{
    echo "==========Installing basic system requirement with $1=========="
        cat $1 | while read line
        do
            apt-get install -y --force-yes $line
        done

    #echo "Installing libffi as a part of wayland"
    #git clone git://github.com/atgreen/libffi.git --single-branch
    #cd libffi-3.1 && ./configure && make && make install && cd ..

    #echo "Installing waylad..."
    #git clone https://anongit.freedesktop.org/git/wayland/wayland.git --single-branch
    #cd wayland && ./autogen.sh --prefix="/opt/" --disable-documentation && make && make install && cd ..
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
        echo "GST_PREFIX                    ${GST_PREFIX}"
        echo "GST_BASE_PREFIX               ${GST_BASE_PREFIX}"
        echo "GST_GOOD_PREFIX               ${GST_GOOD_PREFIX}"
        echo "GST_UGLY_PREFIX               ${GST_UGLY_PREFIX}"
        echo "GST_BAD_PREFIX                ${GST_BAD_PREFIX}"
        echo "GST_VAAPI_PREFIX              ${GST_VAAPI_PREFIX}"
        echo "========================================================================="
    fi

    echo "LD_LIBRARY_PATH=$LD_LIBRARY_PATH" > $ENV_FILE
    echo "PKG_CONTROL_PATH=$PKG_CONFIG_PATH" >> $ENV_FILE
    echo "PATH=$PATH" >> $ENV_FILE
    echo "export LD_LIBRARY_PATH PKG_CONFIG_PATH PATH">> $ENV_FILE
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

ginstaller()
{
    #ginstaller usage: ginstaller [current_path] [component_name] [git_address] [git_tag] [prefix] [option] [force-reinstall=0]
    CURRENT_PATH=$1
    COMP_NAME=$2
    GIT_SRC=$3
    COMP_TAG=$4
    COMP_PREFIX=$5
    COMP_OPTION=$6
    
    [ ! -d $CURRENT_PATH ] && mkdir $CURRENT_PATH
 
    cd $CURRENT_PATH
    if [ -d $COMP_NAME ]; then
        cd $COMP_NAME
        git fetch
        if [[ $(git rev-parse $COMP_TAG) == $(git rev-parse @{u}) && $FORCE == false ]]; then
            echo "Required version of source code found, omitting reinstallation. You may force a re-installation by -f option"
            return 0
        fi
        cd ..
    else
        echo "$CURRENT_PATH/$COMP_NAME doesn\'t exist"
        git clone $QUICK_INSTALL $GIT_SRC
    fi

    cd ${CURRENT_PATH}/$COMP_NAME
    if [[ $COMP_TAG != "HEAD" ]]; then
        git reset $COMP_TAG --hard
    fi

    echo "============Building $COMP_NAME============"

    git clean -dxf && ./autogen.sh --prefix=$COMP_PREFIX $COMP_OPTION && make -j8 &&  make install

    [[ $? -ne 0 ]] && echo "Failed when building $COMP_NAME!" && exit -1 || echo "============Build Completed==============="


    cd ..
}

show_details(){
    #GET SW DETAILS VERSIOB:
    cd $VAAPI_ROOT_DIR
    libva_ver=`git log |head -n 5 |grep commit|less |awk '{print $2}'`
    cd $VAAPI_ROOT_DIR/intel-vaapi-driver
    intel_driver_ver=`git log |head -n 5 |grep commit|less |awk '{print $2}'`
    cd ${YAMI_ROOT_DIR}/libyami
    libyami_ver=`git log |head -n 5 |grep commit|less |awk '{print $2}'`
    echo "environment build SW ditials list:" > $LOG_FILE
    echo "libva=$libva_ver" >> $LOG_FILE
    echo "intel_driver=$intel_driver_ver" >> $LOG_FILE
    echo "libyami=$libyami_ver" >> $LOG_FILE
    if [[ $ENABLE_GST == true ]]; then
        cd ${GST_SRC_PATH}/gstreamer-vaapi
        gst_vaapi_ver=`git log |head -n 5 |grep commit|less |awk '{print $2}'`
        echo "gst-vaapi=$gst_vaapi_ver" >> $LOG_FILE
    fi
    echo `cat $LOG_FILE`
}

gst_install_all(){
    ginstaller $GST_SRC_PATH gstreamer $GSTRAMER_GIT "HEAD" $GST_PREFIX $GST_OPTION
    ginstaller $GST_SRC_PATH gst-plugins-base $GST_BASE_GIT "HEAD" $GST_BASE_PREFIX $GST_BASE_OPTION
    ginstaller $GST_SRC_PATH gst-plugins-good $GST_GOOD_GIT "HEAD" $GST_GOOD_PREFIX $GST_GOOD_OPTION
    ginstaller $GST_SRC_PATH gst-plugins-ugly $GST_UGLY_GIT "HEAD" $GST_UGLY_PREFIX $GST_UGLY_OPTION
    ginstaller $GST_SRC_PATH gst-plugins-bad $GST_BAD_GIT "HEAD" $GST_BAD_PREFIX $GST_BAD_OPTION
    ginstaller $GST_SRC_PATH gst-vaapi $GST_VAAPI_GIT "HEAD" $GST_VAAPI_PREFIX $GST_VAAPI_OPTION
}

sinstaller()
{
    #sinstaller install component from a given source path. The path should be a git path if comp_tag is enabled
    #Usage: sinstaller [component-name] [source-path(where autogen.sh is)] [component-tag] [component-prefix] [component-option]
    COMP_NAME=$1
    SRC_PATH=$2
    COMP_TAG=$3
    COMP_PREFIX=$4
    COMP_OPTION=$5

    echo "============Building $COMP_NAME============"
    echo "Changing into ${SRC_PATH}"
    cd ${SRC_PATH}
    #git pull && git clean -dxf
    ./autogen.sh --prefix=${COMP_PREFIX} ${COMP_OPTION} && make -j32 && make install

    [[ $? -ne 0 ]] && echo "Failed when building $COMP_NAME!" && exit -1 || echo "============Build Completed==============="

    cd ..
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

        -q|--quick )
        shift
        export QUICK_INSTALL="--single-branch"
            ;;

        -v|--version )
        shift
        while [ $# -gt 1 ]
        do
            case $1 in
                libyami )
                export LIBYAMI_TAG="$2"
                shift 2
                ginstaller $YAMI_ROOT_DIR libyami $LIBYAMI_GIT $LIBYAMI_TAG $LIBYAMI_PREFIX $LIBYAMI_OPTION
                    ;;
                
                libva )
                export LIBVA_TAG="$2"
                shift 2
                ginstaller $VAAPI_ROOT_DIR libva $LIBVA_GIT $LIBVA_TAG $VAAPI_PREFIX $LIBVA_OPTION
                    ;;

                libva-utils )
                export LIBVA_UTILS_TAG="$2"
                shift 2
                ginstaller $VAAPI_ROOT_DIR libva-utils $LIBVA_UTILS_GIT $LIBVA_UTILS_TAG $VAAPI_PREFIX ""
                    ;;

                intel-vaapi-driver )
                export INTEL_VAAPI_DRIVER_TAG="$2"
                shift 2
                ginstaller $VAAPI_ROOT_DIR intel-vaapi-driver $INTEL_VAAPI_DRIVER_GIT $INTEL_VAAPI_DRIVER_TAG $VAAPI_PREFIX $INTEL_VAAPI_DRIVER_OPTION
                    ;;

                libyami-utils )
                export LIBYAMI_UTILS_TAG="$2"
                shift 2
                ginstaller $YAMI_ROOT_DIR libyami-utils $LIBYAMI_UTILS_GIT $LIBYAMI_UTILS_TAG $LIBYAMI_PREFIX $LIBYAMI_UTILS_OPTION
                    ;;

                gst-vaapi|gstreamer-vaapi )
                export GST_VAAPI_TAG="$2"
                shift 2
                if [[ -d $GST_SRC_PATH ]]; then
                    echo "gstreamer is not enabled currently. Do you want to install all gstreamer components? If you have already installed gstreamer but forgot to enable it, please add --enable-gst at top [y/n]"
                    read resp
                    [[ $resp == "y" ]] && gst_install_all
                else
                    echo "Do you want to ommit installing other gstreamer component? [y/n]"
                    read resp
                    [[ $resp == "y" ]] && ginstaller $GST_SRC_PATH gst-vaapi $GST_VAAPI_GIT $GST_VAAPI_TAG $GST_VAAPI_PREFIX $GST_VAAPI_OPTION
                    ENABLE_GST=false
                fi
                    ;;

                * )
                    break
                    ;;
            esac
        done
        echo "Version control completed!"
        show_details
        exit 0
            ;;

        -f | --force )
        shift
        export FORCE=true
            ;;
        
        -u | --update )
        shift
        while [ $# -gt 0 ]
        do
            case $1 in
                "libva" )
                shift
                echo -e "\n===Checking update for ${VAAPI_ROOT_DIR}/libva===\n"
                cd ${VAAPI_ROOT_DIR}/libva
                git fetch
                if [[ $(git rev-parse HEAD) == $(git rev-parse @{u}) ]]; then
                    echo "${VAAPI_ROOT_DIR}/libva already up-tp-date."
                else
                    ginstaller $VAAPI_ROOT_DIR "libva" $LIBVA_GIT "HEAD" $VAAPI_PREFIX $LIBVA_OPTION
                fi
                    ;;

                "libva-utils" )
                shift
                echo -e "\n===Checking update for ${VAAPI_ROOT_DIR}/libva—utils===\n"
                cd ${VAAPI_ROOT_DIR}/$1
                git fetch
                if [[ $(git rev-parse HEAD) == $(git rev-parse @{u}) ]]; then
                    echo "${CURRENT_PATH}/libva already up-tp-date."
                else
                    ginstaller $VAAPI_ROOT_DIR "libva-utils" $LIBVA_UTILS_GIT "HEAD" $VAAPI_PREFIX $LIBVA_UTILS_OPTION
                fi
                    ;;

                "intel-vaapi-driver" )
                shift
                echo -e "\n===Checking update for ${VAAPI_ROOT_DIR}/intel-vaapi-driver===\n"
                cd ${VAAPI_ROOT_DIR}/$1
                git fetch
                if [[ $(git rev-parse HEAD) == $(git rev-parse @{u}) ]]; then
                    echo "${CURRENT_PATH}/intel-vaapi-driver already up-tp-date."
                else
                    ginstaller $VAAPI_ROOT_DIR "intel-vaapi-driver" $INTEL_VAAPI_DRIVER_GIT "HEAD" $VAAPI_PREFIX $INTEL_VAAPI_DRIVER_OPTION
                fi
                    ;;

                "libyami" )
                shift
                echo  -e "\n===Checking update for $YAMI_ROOT_DIR/$1===\n"
                cd ${YAMI_ROOT_DIR}/$1
                git fetch
                if [[ $(git rev-parse HEAD) == $(git rev-parse @{u}) ]]; then
                    echo "${CURRENT_PATH}/libyami already up-tp-date."
                else
                    ginstaller $YAMI_ROOT_DIR "libyami" $LIBYAMI_GIT "HEAD" $LIBYAMI_PREFIX $LIBYAMI_OPTION
                fi
                    ;;

                "libyami-utils" )
                shift
                echo  -e "\n===Checking update for ${CURRENT_PATH}/libyami-utils/ ===\n"
                cd ${YAMI_ROOT_DIR}/$1
                git fetch
                if [[ $(git rev-parse HEAD) == $(git rev-parse @{u}) ]]; then
                    echo "${CURRENT_PATH}/intel-vaapi-driver already up-tp-date."
                else
                    ginstaller $YAMI_ROOT_DIR "libyami-utils" $LIBYAMI_UTILS_GIT "HEAD" $LIBYAMI_PREFIX $LIBYAMI_UTILS_OPTION
                fi
                    ;;
    
                "gstreamer-vaapi" )
                shift
                echo -e "\n===Checking update for ${GST_SRC_PATH}/gstreamer-vaapi/ ===\n"
                cd ${GST_SRC_PATH}/gstreamer-vaapi
                git fetch
                if [[ $(git rev-parse HEAD) == $(git rev-parse @{u}) ]]; then
                    echo "${GST_SRC_PATH}/gstreamer-vaapi is already up-tp-date."
                else
                    ginstaller $GST_SRC_PATH "gst-vaapi" $GST_VAAPI_GIT "HEAD" $GST_VAAPI_PREFIX $GST_VAAPI_OPTION
                fi
                    ;;

                * )
                break
                    ;;
                esac
            done
            echo "Update completed!"
            show_details
            exit 0
        
            ;;
        
        -e|--env )
        shift
        echo "Generating $ENV_FILE..."
        sourcing
        exit 0
            ;;
        
        -i|--initialize )
        shift
        INIT_FLAG=true
        [[ $# -gt 0 && ${1:0:1} != "-" ]] && DEP_FILE=$1 && shift || echo "Please specify dependency file"
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

setenv

if [[ $INIT_FLAG == true ]]; then
    [[ $ENABLE_GST == true ]] && init "${folder}/${DEP_FILE}.gst"
    init "${folder}/${DEP_FILE}"
fi

[[ ${ENABLE_VAAPI} == true ]] && ginstaller $VAAPI_ROOT_DIR "libva" $LIBVA_GIT "HEAD" $VAAPI_PREFIX $LIBVA_OPTION\
                               && ginstaller $VAAPI_ROOT_DIR "libva-utils" $LIBVA_UTILS_GIT "HEAD" $VAAPI_PREFIX $LIBVA_UTILS_OPTION\
                               && ginstaller $VAAPI_ROOT_DIR "intel-vaapi-driver" $INTEL_VAAPI_DRIVER_GIT "HEAD" $VAAPI_PREFIX $INTEL_VAAPI_DRIVER_OPTION

[[ ${ENABLE_YAMI} == true ]] && ginstaller $YAMI_ROOT_DIR "libyami" $LIBYAMI_GIT "HEAD" $LIBYAMI_PREFIX $LIBYAMI_OPTION\ 
                              && ginstaller $YAMI_ROOT_DIR "libyami-utils" $LIBYAMI_UTILS_GIT "HEAD" $LIBYAMI_PREFIX $LIBYAMI_UTILS_OPTION
[[ ${ENABLE_GST} == true ]] && gst_install_all

show_details
