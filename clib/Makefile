
all: check
	@echo "-------- FluidSolverCrossbridge --------"
	@echo "-> Generate SWIG wrappers around the functions in the library"
	"$(FLASCC)/usr/bin/swig" -as3 -package fluidsolver.core.crossbridge -module FluidSolverCrossbridge -outdir . -includeall -ignoremissing -o FluidSolverCrossbridge_wrapper.c swig.h

	@echo "-> Compile the SWIG wrapper to ABC"
	$(AS3COMPILERARGS) -import $(call nativepath,$(FLASCC)/usr/lib/builtin.abc) -import $(call nativepath,$(FLASCC)/usr/lib/playerglobal.abc) FluidSolverCrossbridge.as
	# rename the output so the compiler doesn't accidentally use both this .as file along with the .abc file we just produced
	mv FluidSolverCrossbridge.as FluidSolverCrossbridge.as3

	@echo "-> Compile the library into a SWC"
	"$(FLASCC)/usr/bin/g++" $(BASE_CFLAGS) -emit-swc=fluidsolver.core.crossbridge FluidSolverCrossbridge.abc FluidSolverCrossbridge_wrapper.c FluidSolverCrossbridge.c main.cpp -o FluidSolverCrossbridge.swc -jvmopt=-Xmx1G

	# rename back again
	mv FluidSolverCrossbridge.as3 FluidSolverCrossbridge.as

FLASCC:=X
FLEX:=X
AS3COMPILER:=asc2.jar
BASE_CFLAGS:=-Werror -Wno-write-strings -Wno-trigraphs

$?UNAME=$(shell uname -s)
ifneq (,$(findstring CYGWIN,$(UNAME)))
	$?nativepath=$(shell cygpath -at mixed $(1))
	$?unixpath=$(shell cygpath -at unix $(1))
else
	$?nativepath=$(abspath $(1))
	$?unixpath=$(abspath $(1))
endif

ifneq (,$(findstring "asc2.jar","$(AS3COMPILER)"))
	$?AS3COMPILERARGS=java $(JVMARGS) -jar $(call nativepath,$(FLASCC)/usr/lib/$(AS3COMPILER)) -merge -md 
else
	echo "ASC is no longer supported" ; exit 1 ;
endif

check:
	@if [ -d $(FLASCC)/usr/bin ] ; then true ; \
	else echo "Couldn't locate FLASCC sdk directory, please invoke make with \"make FLASCC=/path/to/FLASCC/sdk ...\"" ; exit 1 ; \
	fi

	@if [ -d "$(FLEX)/bin" ] ; then true ; \
	else echo "Couldn't locate Flex sdk directory, please invoke make with \"make FLEX=/path/to/flex  ...\"" ; exit 1 ; \
	fi



clean:
	rm -f *.swf *.swc *.abc *.bc FluidSolverCrossbridge_wrapper.c *.as3 *.as
