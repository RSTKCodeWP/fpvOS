################################################################################
#
# hi3516cv610-sdk  (the userspace libraries kestrel-air runs with)
#
################################################################################

# The HI3516CV610_MPP_V1.0.2.0 B051 MPI, ISP and ISP-algorithm libraries (the
# same build as the stock firmware's ot_*.ko modules, which stay on the unit)
# and the camera's sensor drivers, prebuilt, in one archive with their
# SHA256SUMS. Only what kestrel-air loads: its NEEDED libraries, whose own
# NEEDED add nothing but libc, and libsns_cv2004.so / libsns_os02k10.so, one of
# which it dlopen()s for the camera it finds.
HI3516CV610_SDK_VERSION = 2063a02
HI3516CV610_SDK_SOURCE = ascent-lite-libs-$(HI3516CV610_SDK_VERSION).tar.gz
HI3516CV610_SDK_SITE = https://gist.githubusercontent.com/gehee/faf2c7f263052e51ad992b4048576f8c/raw/d8d54f03b6ee7efd66a4565527f3514a40f2533d
HI3516CV610_SDK_LICENSE = PROPRIETARY (MPI libraries), MIT (sensor drivers)
HI3516CV610_SDK_LICENSE_FILES = README.md BUILD-INFO
HI3516CV610_SDK_REDISTRIBUTE = NO

HI3516CV610_SDK_LIBS = \
	libss_mpi.so libss_mpi_isp.so libss_mpi_ae.so libss_mpi_awb.so \
	libot_mpi_isp.so libss_mpi_sysmem.so libss_mpi_sysbind.so \
	libacs.so libbnr.so libcalcflicker.so libdehaze.so libdrc.so \
	libextend_stats.so libir_auto.so libldci.so libsecurec.so libot_osal.so libbin.so \
	libsns_cv2004.so libsns_os02k10.so

# Each library checked against the archive's own SHA256SUMS (the archive itself
# is checked by the .hash file).
define HI3516CV610_SDK_CHECK_LIBS
	cd $(@D)/lib && sha256sum -c --quiet ../SHA256SUMS
endef
HI3516CV610_SDK_POST_EXTRACT_HOOKS += HI3516CV610_SDK_CHECK_LIBS

# On the unit they go in the app volume, next to kestrel-air: /usrdata/fpv/air/lib.
define HI3516CV610_SDK_INSTALL_TARGET_CMDS
	$(foreach l,$(HI3516CV610_SDK_LIBS),
		$(INSTALL) -D -m 0755 $(@D)/lib/$(l) $(TARGET_DIR)/usrdata/fpv/air/lib/$(l)
	)
endef

$(eval $(generic-package))
