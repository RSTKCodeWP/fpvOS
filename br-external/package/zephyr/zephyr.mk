################################################################################
#
# zephyr
#
################################################################################

# The Zephyr RTOS tree open8030 builds against (its kernel is compiled into the
# radio firmware), as a west workspace with no modules: Zephyr 4.3 only runs its
# module scan through west, and the scan has to run. Same tag as Open8030's
# toolchain.json pins (v4.3.0 = 3568e1b6d5cdd51a6b964a2a1d6d29200fea2056).
ZEPHYR_VERSION = 4.3.0
ZEPHYR_SITE = $(call github,zephyrproject-rtos,zephyr,v$(ZEPHYR_VERSION))
ZEPHYR_SOURCE = zephyr-v$(ZEPHYR_VERSION).tar.gz
ZEPHYR_LICENSE = Apache-2.0
ZEPHYR_LICENSE_FILES = LICENSE

# What `west init -l zephyr` writes, without west.
HOST_ZEPHYR_WORKSPACE = $(HOST_DIR)/share/zephyr-workspace

define HOST_ZEPHYR_INSTALL_CMDS
	rm -rf $(HOST_ZEPHYR_WORKSPACE)
	mkdir -p $(HOST_ZEPHYR_WORKSPACE)/zephyr $(HOST_ZEPHYR_WORKSPACE)/.west
	cp -rf $(@D)/. $(HOST_ZEPHYR_WORKSPACE)/zephyr/
	printf '[manifest]\npath = zephyr\nfile = west.yml\n' > $(HOST_ZEPHYR_WORKSPACE)/.west/config
endef

$(eval $(host-generic-package))
