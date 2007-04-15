# libdvdnav Makefile

include config.mak

.SUFFIXES: .so

MAKE=make
CC=gcc
AR=ar
LD=ld
RANLIB=ranlib

VPATH+= src
SRCS = dvdnav.c highlight.c navigation.c read_cache.c remap.c \
	searching.c settings.c

VPATH+= src/vm
SRCS+= decoder.c vm.c vmcmd.c

VPATH+= src/dvdread
SRCS+= dvd_input.c dvd_reader.c dvd_udf.c ifo_print.c ifo_read.c \
	md5.c nav_print.c nav_read.c


HEADERS += src/dvd_types.h \
	src/dvdnav.h \
	src/dvdnav_events.h \
	src/dvdread/dvd_reader.h \
	src/dvdread/ifo_print.h \
	src/dvdread/ifo_read.h \
	src/dvdread/ifo_types.h \
	src/dvdread/nav_print.h \
	src/dvdread/nav_read.h \
	src/dvdread/nav_types.h

L=libdvdnav
LIB = $(L).a
SHLIB = $(L).so


CFLAGS += -g -Wall -funsigned-char -O3
CFLAGS += -I$(CURDIR) -I$(CURDIR)/src -I$(CURDIR)/src/vm \
	 -I$(CURDIR)/src/dvdread

CFLAGS += -DDVDNAV_COMPILE -D_FILE_OFFSET_BITS=64 -D_LARGEFILE64_SOURCE
CFLAGS += -DHAVE_CONFIG_H -DHAVE_DLFCN_H

SHLDFLAGS += -shared

LIBS_INSTALL = $(CURDIR)/../lib
INCLUDES_INSTALL = $(CURDIR)/../include/libhts

.OBJDIR=        obj
DEPFLAG = -M

OBJS = $(patsubst %.c,%.o, $(SRCS))
SHOBJS = $(patsubst %.c,%.so, $(SRCS))
DEPS= ${OBJS:%.o=%.d}

BUILDDEPS = Makefile config.mak

ifeq ($(BUILD_SHARED),yes)
all:	$(SHLIB)
install: $(SHLIB) install-shared
endif

ifeq ($(BUILD_STATIC),yes)
all:	$(LIB)
install: $(LIB) install-static
endif

install: install-headers

# Let version.sh create version.h

SVN_ENTRIES = $(SRC_PATH_BARE)/.svn/entries
ifeq ($(wildcard $(SVN_ENTRIES)),$(SVN_ENTRIES))
version.h: $(SVN_ENTRIES)
endif

version.h:
	sh ./version.sh


# General targets

$(.OBJDIR):
	mkdir $(.OBJDIR)

${LIB}: version.h $(.OBJDIR) $(OBJS) $(BUILDDEPS)
	cd $(.OBJDIR) && $(AR) rc $@ $(OBJS)
	cd $(.OBJDIR) && $(RANLIB) $@

${SHLIB}: version.h $(.OBJDIR) $(SHOBJS) $(BUILDDEPS)
	cd $(.OBJDIR) && $(CC) $(SHLDFLAGS) -o $@ $(SHOBJS)

.c.so:	$(BUILDDEPS)
	cd $(.OBJDIR) && $(CC) -fPIC -DPIC -MD $(CFLAGS) -c -o $@ $(CURDIR)/$<

.c.o:	$(BUILDDEPS)
	cd $(.OBJDIR) && $(CC) -MD $(CFLAGS) -c -o $@ $(CURDIR)/$<


# Install targets

install-headers:
	install -d $(incdir)
	install -m 644 $(HEADERS) $(incdir)

install-shared: $(SHLIB)
	install -d $(shlibdir)

	install $(INSTALLSTRIP) -m 755 $(.OBJDIR)/$(SHLIB) \
		$(shlibdir)/$(SHLIB).$(SHLIB_VERSION)

	cd $(shlibdir) && \
		ln -sf $(SHLIB).$(SHLIB_VERSION) $(SHLIB).$(SHLIB_MAJOR)
	cd $(shlibdir) && \
		ln -sf $(SHLIB).$(SHLIB_MAJOR) $(SHLIB)

install-static: $(LIB)
	install -d $(libdir)

	install $(INSTALLSTRIP) -m 755 $(.OBJDIR)/$(LIB) $(libdir)/$(LIB)


# Clean targets

clean:
	rm -rf  *~ $(.OBJDIR) version.h


distclean: clean
	find . -name "*~" | xargs rm -rf
	rm -rf config.mak


vpath %.so ${.OBJDIR}
vpath %.o ${.OBJDIR}
vpath ${LIB} ${.OBJDIR}

# include dependency files if they exist
$(addprefix ${.OBJDIR}/, ${DEPS}): ;
-include $(addprefix ${.OBJDIR}/, ${DEPS})