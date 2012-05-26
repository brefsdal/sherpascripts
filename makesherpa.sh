#!/bin/sh
# 
#  Copyright (C) 2011  Smithsonian Astrophysical Observatory
#
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License along
#  with this program; if not, write to the Free Software Foundation, Inc.,
#  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#


# The script builds the stand-alone version of Sherpa by
# building all required and optional ABI dependencies from
# source and linking statically to Sherpa dynamic libraries.
# This script works on Linux (CentOS, RH5, FC14, Ubuntu) and
# Mac (OSX 10.5, 10.6, 10.7)

# This script modifies source to suit the stand-alone requirements
# in the following packages
#
#  CIAO-4.4 - DataModel, Region, DMgroup
#  Sherpa   - Support for XSPEC HEADAS variable, version number,
#             and defaults for pyfits and matplotlib 
#  XSPEC    - Edits to support Sherpa passing the HEADAS variable.
#
# This script may need one or more of the following packages on Linux
# 
#    gcc, g++, gcc-fortran, python-devel, gcc-g++, libX11-devel, numpy
#    gfortran, flex, bison, g++, python-numpy, wget, tar, libgfortran3,
#    m4, libncurses5-dev, libreadline6-dev, x11-devel
#
# This script requires XCode on OSX
#
#
#
# For CentOS
# 
# yum install readline-devel ncurses-devel libX11-devel gcc-c++ \
#             gcc-gfortran gcc bison flex wget
#
#
#
# To install Sherpa stand-alone, run the following commands
# 
# % chmod +x makeit.sh
# % ./makeit.sh
# % cd sherpa-4.4.0
# % python setup.py install --prefix=<install path>
# % cd ..
# % cp -f group.so <install path>/lib/python2.X/site-packages
#
#

ARCH=`uname`
PREFIX=`pwd`
TAR="tar -zxf"

export CC="`which gcc`"
export CXX="`which g++`"
export FC="`which gfortran`"

BISON=`which bison`
FLEX=`which flex`

NCPUS="1"
HAVE_SSE2="--enable-sse2"
if [ $ARCH = "Darwin" ]
then
    TAR="gnutar -zxf"
    NCPUS=`sysctl -n hw.ncpu`
    export ARCHFLAGS=""

fi

if [ $ARCH = "Linux" ]
then
    NCPUS=`cat /proc/cpuinfo | grep processor | wc -l`
    SSE2=`cat /proc/cpuinfo | grep sse2`
    if [ "x" = "${SSE2}x" ]
    then
	HAVE_SSE2=""
    fi
fi

if [ $ARCH = "SunOS" ]
then
    echo "Solaris is unsupported"
    exit 1
fi


FAST_MAKE="-j${NCPUS}"


# Sherpa repository
REPO="http://cxc.harvard.edu/contrib/sherpa/repo"

# XSPEC 12.7.0e
#http://heasarc.gsfc.nasa.gov/FTP/software/lheasoft/release/xspec-modelsonly.tar.gz
XSPEC="xspec-modelsonly"
XSPEC_FILE="xspec-modelsonly.tar.gz"
#XSPEC_PATH="http://heasarc.gsfc.nasa.gov/FTP/software/lheasoft/release/${XSPEC_FILE}"
XSPEC_PATH="$REPO/${XSPEC_FILE}"

# WCSSUBS 3.8.4
#http://tdc-www.harvard.edu/software/wcstools/wcssubs-3.8.4.tar.gz
WCS="wcssubs-3.8.4"
WCS_FILE="$WCS.tar.gz"
#WCS_PATH="http://tdc-www.harvard.edu/software/wcstools/${WCS_FILE}"
WCS_PATH="$REPO/${WCS_FILE}"

# CFITSIO 3.27
#ftp://heasarc.gsfc.nasa.gov/software/fitsio/c/cfitsio3270.tar.gz
CFITSIO="cfitsio"
CFITSIO_FILE="cfitsio3270.tar.gz"
#CFITSIO_PATH="ftp://heasarc.gsfc.nasa.gov/software/fitsio/c/${CFITSIO_FILE}"
CFITSIO_PATH="$REPO/${CFITSIO_FILE}"

# CCFITS 2.3
#http://heasarc.gsfc.nasa.gov/docs/software/fitsio/ccfits/CCfits-2.3.tar.gz
CCFITS="CCfits"
CCFITS_FILE="CCfits-2.3.tar.gz"
#CCFITS_PATH="http://heasarc.gsfc.nasa.gov/docs/software/fitsio/ccfits/${CCFITS_FILE}"
CCFITS_PATH="$REPO/${CCFITS_FILE}"

# FFTW 3.3
#http://www.fftw.org/fftw-3.3.tar.gz
FFTW="fftw-3.3"
FFTW_FILE="$FFTW.tar.gz"
#FFTW_PATH="http://www.fftw.org/${FFTW_FILE}"
FFTW_PATH="$REPO/${FFTW_FILE}"

# CIAO 4.4
CIAO="ciao-4.4"
CIAO_FILE="$CIAO-src-core.tar.gz"
CIAO_PATH="ftp://cxc.cfa.harvard.edu/pub/ciao4.4/all/${CIAO_FILE}"

# Sherpa 4.4
SHERPA="sherpa-4.4.0"
SHERPA_FILE="$SHERPA.tar.gz"
SHERPA_PATH="http://cxc.cfa.harvard.edu/contrib/sherpa/${SHERPA_FILE}"

# check for wget
WGET="wget --tries 5 --no-clobber --progress=bar"
check_wget() {
    HAVE_WGET=`which wget`
    if [ "x" = "${HAVE_WGET}x" ]
    then
	echo "ERROR: Sherpa installer needs 'wget', http://mirrors.kernel.org/gnu/wget/"
	exit 1
    fi
}

if [ "x" = "${FC}x" ]
then
    echo "ERROR: Sherpa installer needs 'gfortran', http://mirrors.kernel.org/gnu/gcc/"
    exit 1
fi

if [ "x" = "${CC}x" ]
then
    echo "ERROR: Sherpa installer needs 'gcc', http://mirrors.kernel.org/gnu/gcc/"
    exit 1
fi

if [ "x" = "${CXX}x" ]
then
    echo "ERROR: Sherpa installer needs 'g++', http://mirrors.kernel.org/gnu/gcc/"
    exit 1
fi

if [ "x" = "${BISON}x" ]
then
    echo "ERROR: Sherpa installer needs 'bison', http://mirrors.kernel.org/gnu/bison/"
    exit 1
fi

if [ "x" = "${FLEX}x" ]
then
    echo "ERROR: Sherpa installer needs 'flex', http://flex.sourceforge.net"
    exit 1
fi



build_wcs() {

    if [ ! -e $WCS_FILE ]
    then
	$WGET $WCS_PATH
    fi
    $TAR $WCS_FILE
 
    cd $WCS
    make CFLAGS="-fPIC"
    cp -f libwcs.a ../lib
    cp -f *.h ../include
    cd ..
}


build_cfitsio() {

    if [ ! -e $CFITSIO_FILE ]
    then
	$WGET $CFITSIO_PATH
    fi
    $TAR $CFITSIO_FILE
    cd $CFITSIO
    ./configure --prefix=$PREFIX
    make clean
    make
    make install
    cd ..
}


build_CCfits() {

    if [ ! -e $CCFITS_FILE ]
    then
	$WGET $CCFITS_PATH
    fi
    $TAR $CCFITS_FILE
    cd $CCFITS
    ./configure --disable-shared \
	--with-cfitsio-include=$PREFIX/include \
	--with-cfitsio-libdir=$PREFIX/lib \
	--with-pic --prefix=$PREFIX
    make
    make install
    cd ..
}


build_fftw() {

    if [ ! -e $FFTW_FILE ] 
    then
	$WGET $FFTW_PATH
    fi
    $TAR $FFTW_FILE
    cd $FFTW
    ./configure --with-pic $HAVE_SSE2 --prefix=$PREFIX
    make $FAST_MAKE
    make install
    cd ..
}



build_ciao() {

    if [ ! -e $CIAO_FILE ]
    then
	$WGET $CIAO_PATH
    fi
    $TAR $CIAO_FILE
    cd $CIAO
    ./configure --with-fits --with-ascii \
	CC=$CC CXX=$CXX
    cp -f ./config.h src/include
    cd src/lib/region
    make
    make install
    cd ../datamodel
    sed 's/dataset descriptor filter coords misc lib tools modules \\/dataset descriptor filter coords misc lib/g' < Makefile > Makefile--
    mv Makefile-- Makefile
    sed 's/examples dmtest doc//g' < Makefile > Makefile--
    mv Makefile-- Makefile
    cp -f nutils/nan.c nutils/nan.c.good
    sed 's/#ifdef _POSIX_C_SOURCE/#if 0/g' < nutils/nan.c > nutils/nan.c--
    mv nutils/nan.c-- nutils/nan.c
    make \
	WCS_INC=$PREFIX/include \
	WCS_LIB=$PREFIX/lib \
	INC_DIR=$PREFIX/$CIAO/include \
	LIB_DIR=$PREFIX/$CIAO/lib \
	CFITSIO_INC="-I$PREFIX/include" \
	CFITSIO_LIB="-L$PREFIX/lib"
    make install
    cd $PREFIX
    cp -f $CIAO/lib/libregion.a lib
    cp -f $CIAO/lib/libascdm.a lib
    cp -f $CIAO/include/* include

    # build CIAO group python module

    ERRDIR="$PREFIX/$CIAO/src/lib/dserror"
    GRPDIR="$PREFIX/$CIAO/src/libdev/grplib/src"
    PYGRPDIR="$PREFIX/$CIAO/src/libdev/grplib/python"
    LIBDIR="$PREFIX/$CIAO/lib"

    cd $ERRDIR
    make
    make install

    rm -rf $LIBDIR/liberr.so
    rm -rf $LIBDIR/liberr.dylib

    cd $GRPDIR
    make CC="gcc -DSTUB_ERROR_LIB=1"
    make install

    rm -rf $LIBDIR/libgrp.so
    rm -rf $LIBDIR/libgrp.dylib
    
    cd $PYGRPDIR
    
    rm -f setup.py build group.so

    VERSION=`echo $CIAO | awk '{print substr($1,6,8)}'`

    echo "
#!/usr/bin/env python

#from distutils.core import setup, Extension
from numpy.distutils.core import setup, Extension

setup(name='group', version='$VERSION', ext_modules=[
    Extension('group',
              ['pygrplib.c'],
              ['$ERRDIR', '$GRPDIR', '$PYGRPDIR'],
              library_dirs=['$LIBDIR'],
              libraries=['err', 'grp'],
              depends=['pygrplib.h']
             )]
    )              
" > setup.py

    python setup.py build_ext --inplace

    cp group.so $LIBDIR
    cd $PREFIX
    cp -f $CIAO/lib/group.so .
}



build_xspec() {

    if [ ! -e $XSPEC_FILE ]
    then
	$WGET $XSPEC_PATH
    fi
    $TAR $XSPEC_FILE

    #
    ## MixFunction is not used, do not build
    #

    rm -rf xspec-modelsonly/Xspec/src/XSModel/Model/MixFunction

    ###


    #
    ## Edit configure to drop requirements for X11-devel, perl?
    #

    # cd xspec-modelsonly/Xspec/BUILD_DIR/
    # edit configure.in
    # autoconf
    # cp ./configure xspec-modelsonly/Xspec/BUILD_DIR/

    ###

    cd xspec-modelsonly/BUILD_DIR
    ./configure CC=$CC CXX=$CXX FC=$FC


    #
    ## Edit the file hmakerc to build XSpec with static libraries
    #

    cd ../Xspec/BUILD_DIR
    cp -f hmakerc hmakerc.bak
    sed 's/HD_LIB_STYLE="shared"/HD_LIB_STYLE="static"/g' < hmakerc > hmakerc1
    sed 's/HD_LIB_STYLE_F77="shared"/HD_LIB_STYLE_F77="static"/g' < hmakerc1 > hmakerc2
    cp -f hmakerc2 hmakerc
    cd ../../BUILD_DIR/

    ###

    #
    ## Edit XSpec source to support Sherpa passing in the HEADAS location
    #

    cd ../Xspec/src/XSUtil/FunctionUtils/

    # edit source xsFortran.cxx
    cp -f xsFortran.cxx xsFortran.cxx.bak
    sed 's/FCALLSCSUB0(FNINIT,FNINIT,fninit)/FCALLSCSUB1(FNINIT,FNINIT,fninit,STRING)/g' < xsFortran.cxx > xsFortran.cxx1
    sed 's/void FNINIT()/void FNINIT(char* headas)/g' < xsFortran.cxx1 > xsFortran.cxx2
    sed 's/getenv("XSPEC_MDATA_DIR")/0x0/g' < xsFortran.cxx2 > xsFortran.cxx3
    sed 's/getenv("HEADAS")/headas/g' < xsFortran.cxx3 > xsFortran.cxx4
    cp -f xsFortran.cxx4 xsFortran.cxx

    # edit header xsFortran.h
    cp -f xsFortran.h xsFortran.h.bak
    sed 's/void FNINIT(void);/void FNINIT(char *headas);/g' < xsFortran.h > xsFortran.h1
    cp -f xsFortran.h1 xsFortran.h

    ###

    # Build XSpec
    cd ../../../../BUILD_DIR/
    make CC=$CC CXX=$CXX FC=$FC
    make CC=$CC CXX=$CXX FC=$FC install

    # Copy the required static libraries
    cp -f ../Xspec/src/XSFunctions/libXSFunctions.a $PREFIX/lib
    cp -f ../Xspec/src/XSModel/libXSModel.a $PREFIX/lib
    cp -f ../Xspec/src/XSUtil/libXSUtil.a $PREFIX/lib
    cp -f ../Xspec/src/xslib/libXS.a $PREFIX/lib
    cd $PREFIX
}


build_sherpa() {

    if [ ! -e $SHERPA_FILE ]
    then
	$WGET $SHERPA_PATH
    fi
    $TAR $SHERPA_FILE

    ## No, skip all this business -- it's smarter to make a 4.4.0
    ## tar file at CfA, and not oblige user to go through this step.
    ## SMD 01/27/12
    # update stand-alone Sherpa to be 1 minor version behind CIAO
    # 4.4.1 --> 4.4.0
    #VERSION=`echo $SHERPA | awk '{print substr($1,8,12)}'`
    #MAJOR=`echo $VERSION | awk '{print substr($1,1,3)}'`
    #MINOR=`echo $VERSION | awk '{print substr($1,5,6)}'`
    #NEWVERSION="$MAJOR.`expr $MINOR - "1"`"

    #python fix_sherpa.py $SHERPA $VERSION $NEWVERSION
    ##
    cd $SHERPA
    export F77=$FC
    export F90=$FC
    export F95=$FC
    python setup.py \
	cfitsio_library_dir="../lib" \
	xspec_library_dir="../lib" \
	reg_library_dir="../lib" \
	reg_include_dir="../include" \
	fftw_library_dir="../lib" \
	fftw_include_dir="../include" \
	wcs_library_dir="../lib" \
	wcs_include_dir="../include" \
	install

    cd $PREFIX
}

if [ ! -d lib ]
then
    mkdir lib
fi

if [ ! -d include ]
then
    mkdir include
fi

do_wcs() {

    if [ ! -e lib/libwcs.a ]
    then
	build_wcs
    fi
}

do_cfitsio() {

    if [ ! -e lib/libcfitsio.a ]
    then
	build_cfitsio
    fi
}

do_CCfits() {
    
    if [ ! -e lib/libCCfits.a ]
    then
	build_CCfits
    fi
}

do_fftw() {

    if [ ! -e lib/libfftw3.a ]
    then
	build_fftw
    fi
}


do_ciao() {

    if [ \( ! -e lib/libascdm.a \) -o \( ! -e lib/libregion.a \) -o \( ! -e ./group.so \) ]
    then
	build_ciao
    fi
}

do_xspec() {
    
    if [ \( ! -e lib/libXS.a \) -o \( ! -e lib/libXSFunctions.a \) -o \
	 \( ! -e lib/libXSUtil.a \) -o \( ! -e lib/libXSModel.a \) ]
    then
	build_xspec
    fi
}

do_sherpa() {
    
    build_sherpa

}


# build Sherpa + dependencies

do_wcs
do_cfitsio
do_CCfits
do_fftw
do_ciao
do_xspec
do_sherpa
