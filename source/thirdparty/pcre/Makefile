#
#  iOS Ports Library
#  Copyright (C) 2010 Bindle Binaries
#  All rights reserved.
#
#  @BINDLE_BINARIES_BSD_LICENSE_START@
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions are
#  met:
#
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of Bindle Binaries nor the
#       names of its contributors may be used to endorse or promote products
#       derived from this software without specific prior written permission.
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
#  IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
#  THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
#  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL BINDLE BINARIES BE LIABLE FOR
#  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
#  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
#  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
#  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
#  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
#  OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
#  SUCH DAMAGE.
#
#  @BINDLE_BINARIES_BSD_LICENSE_END@
#
#  Makefile -- automate downloading of package files
#

# Package Information

PACKAGE_TARNAME       = pcre
PACKAGE_VERSION       = 8.32
PACKAGE_DIR           = $(PACKAGE_TARNAME)-$(PACKAGE_VERSION)
PACKAGE_FILEEXT       = tar.bz2
PACKAGE_FILE          = $(PACKAGE_DIR).$(PACKAGE_FILEEXT)
PACKAGE_MD5           = $(PACKAGE_FILE).testmd5
PACKAGE_URL           = http://superb-dca2.dl.sourceforge.net/project/pcre/pcre/$(PACKAGE_VERSION)/$(PACKAGE_FILE)

all: $(PACKAGE_DIR) extra-prep

$(PACKAGE_DIR): $(PACKAGE_FILE)
	@/bin/rm -Rf $(PACKAGE_DIR)
	/usr/bin/tar -xjf $(PACKAGE_FILE)
	@/usr/bin/touch $(PACKAGE_DIR)

$(PACKAGE_FILE):
	/usr/bin/curl -O $(PACKAGE_URL) -o $(PACKAGE_FILE) -s \
		|| { rm -f $(PACKAGE_FILE); echo -e "unable to download $(PACKAGE_FILE) from $(PACKAGE_URL)\nPlease verify that your system is connected to the Internet."; exit 1; };
	/sbin/md5 $(PACKAGE_FILE) > $(PACKAGE_MD5)
	/usr/bin/diff $(PACKAGE_MD5) $(PACKAGE_FILE).md5 > /dev/null || { /bin/rm -f $(PACKAGE_MD5) $(PACKAGE_FILE); exit 1; };
	@/bin/rm -f $(PACKAGE_MD5)
	@/usr/bin/touch $(PACKAGE_FILE)

extra-prep: $(PACKAGE_DIR)/config.h $(PACKAGE_DIR)/pcre.h $(PACKAGE_DIR)/pcre_chartables.c

$(PACKAGE_DIR)/config.h: $(PACKAGE_DIR)
	/bin/cp config.h $(PACKAGE_DIR)/config.h

$(PACKAGE_DIR)/pcre.h: $(PACKAGE_DIR) $(PACKAGE_DIR)/pcre.h.generic
	/bin/cp $(PACKAGE_DIR)/pcre.h.generic $(PACKAGE_DIR)/pcre.h

$(PACKAGE_DIR)/pcre_chartables.c: $(PACKAGE_DIR) $(PACKAGE_DIR)/pcre_chartables.c.dist
	/bin/cp $(PACKAGE_DIR)/pcre_chartables.c.dist $(PACKAGE_DIR)/pcre_chartables.c

clean: clean-local
	/bin/rm -Rf include

distclean: distclean-local clean
	/bin/rm -f  $(PACKAGE_MD5)
	/bin/rm -fR $(PACKAGE_DIR)
	/bin/rm -fR $(PACKAGE_TARNAME)
	/bin/rm -f $(PACKAGE_FILE)
	/bin/rm -f build/

clean-local:
	/bin/rm -Rf include
	/bin/rm -Rf $(INCLUDES)

distclean-local:
	/bin/rm -Rf build

# End of Makefile.
