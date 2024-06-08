#! /bin/bash

set -ex

# Standardize the environment variables used across the different toolchains.
# We need to ensure that $FC and $FFLAGS are set, which not all toolchains do.

if [[ $target_platform == osx-* ]]; then
    subtype=actually_osx

    if [ "$c_compiler" = toolchain_c ] ; then
        FC=gfortran
        FFLAGS="-g -O -fno-automatic -Wall -fPIC -m$ARCH -mmacosx-version-min=$MACOSX_DEPLOYMENT_TARGET"
    fi
else
    subtype=gfortran_gcc

    if [ "$c_compiler" = toolchain_c ] ; then
        FC=gfortran
        FFLAGS="-g -O -fno-automatic -Wall -fPIC -m$ARCH"
    fi
fi

if [[ "$CONDA_BUILD_CROSS_COMPILATION" == "1" ]]; then
  (
    mkdir -p native-build/bin
    pushd native-build/bin

    # MACOSX_DEPLOYMENT_TARGET is for the target_platform and not for build_platform
    unset MACOSX_DEPLOYMENT_TARGET

    $FC_FOR_BUILD -L $BUILD_PREFIX/lib -o pgpack ../../fonts/pgpack.f
    $CC_FOR_BUILD ../../cpg/pgbind.c -o pgbind

    popd
  )
  export PATH=$(pwd)/native-build/bin:$PATH
  export SRC_RUN=
  export FFLAGS=$FFLAGS+" -L$PREFIX/lib"
else
  export SRC_RUN=./
fi

./makemake . linux $subtype
for f in png.h pngconf.h pnglibconf.h zlib.h zconf.h ; do
    ln -s $PREFIX/include/$f $f
done
make all libcpgplot.a

mkdir -p $PREFIX/bin $PREFIX/lib $PREFIX/include/pgplot $PREFIX/share/pgplot
cp -a pgxwin_server $PREFIX/bin/
cp -a libcpgplot.a libpgplot.a libpgplot$SHLIB_EXT libcpgplot$SHLIB_EXT $PREFIX/lib/
cp -a grfont.dat rgb.txt $PREFIX/share/pgplot/
cp -a cpgplot.h grpckg1.inc pgplot.inc $PREFIX/include/pgplot/

# NOTE: do not delete .a files -- that's currently the only way we distribute
# libcpgplot. Would be nice to fix that.

mkdir -p $PREFIX/lib/pkgconfig
for pctmpl in pgplot cpgplot ; do
  sed -e "s|@P@|$PREFIX|g" <$RECIPE_DIR/$pctmpl.pc.in >$PREFIX/lib/pkgconfig/$pctmpl.pc
done
