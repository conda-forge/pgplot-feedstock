#! /bin/bash

set -e

if [ -n "$OSX_ARCH" ] ; then
    subtype=actually_osx

    # So. On OSX, we get end up getting linked against a library called
    # `libgcc_ext.10.5.dylib`. This is a stub library, which
    # `install_name_tool` won't modify, so the version of this library
    # currently bundled with the `gcc` package (defaults 4.8.5-7) includes
    # hardcoded paths to `/Users/ray/mc-x86_64-3.5/.../libgcc_s.1.dylib`,
    # which in turn gets embedded into the dylib we'd like to generate,
    # breaking it. While I can't figure out a way to prevent gcc from trying
    # to link us to libgcc_ext, we don't actually use any of its symbols.
    # Because OSX dylibs contain their own names, we can just replace the
    # libgcc_ext files with those of another dylib. This is, of course,
    # terrible, but it works. GitHub issue conda-build#186 tracks the
    # underlying problem.
    for name in gcc_ext.10.4 gcc_ext.10.5 ; do
        badlib="$PREFIX/lib/lib${name}.dylib"
        rm -f "$badlib"
        ln -s "libgcc_s.1.dylib" "$badlib"
    done
else
    subtype=gfortran_gcc
fi

./makemake . linux $subtype
for f in png.h pngconf.h pnglibconf.h zlib.h zconf.h ; do
    ln -s $PREFIX/include/$f $f
done
make all libcpgplot.a

mkdir -p $PREFIX/bin $PREFIX/lib $PREFIX/include/pgplot $PREFIX/share/pgplot
cp -a pgxwin_server $PREFIX/bin/
cp -a libcpgplot.a libpgplot.a libpgplot$SHLIB_EXT $PREFIX/lib/
cp -a grfont.dat rgb.txt $PREFIX/share/pgplot/
cp -a cpgplot.h grpckg1.inc pgplot.inc $PREFIX/include/pgplot/

# NOTE: do not delete .a files -- that's currently the only way we distribute
# libcpgplot. Would be nice to fix that.
