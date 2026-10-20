################################################################################
#
# zephyr-python
#
################################################################################

# The Python modules a Zephyr build runs beyond what Buildroot packages for the
# host (PyYAML, packaging, pyelftools, attrs): west, and pykwalify / jsonschema
# for its module and snippet checks, with their dependencies. Pure-Python wheels
# installed as they are; jsonschema stays on 4.17, the last one without the
# Rust-built rpds-py.
ZEPHYR_PYTHON_VERSION = 1.5.0
ZEPHYR_PYTHON_SITE = https://files.pythonhosted.org/packages/c5/1d/e50fb71de492abb549917fdbf13c4a8a8459af9d78a2fa47905804905c36
ZEPHYR_PYTHON_SOURCE = west-1.5.0-py3-none-any.whl
ZEPHYR_PYTHON_EXTRA_DOWNLOADS = \
	https://files.pythonhosted.org/packages/d1/d6/3965ed04c63042e047cb6a3e6ed1a63a35087b6a609aa3a15ed8ac56c221/colorama-0.4.6-py2.py3-none-any.whl \
	https://files.pythonhosted.org/packages/1f/fd/ac2161cce19fd67a18c269073f8e86292b5511acec6f8ef6eab88615d032/pykwalify-1.8.0-py2.py3-none-any.whl \
	https://files.pythonhosted.org/packages/d1/e5/f2a0621f1781b76a38194acae72f01e37b1941470407345b6e8653ad7640/ruamel.yaml-0.18.15-py3-none-any.whl \
	https://files.pythonhosted.org/packages/ec/57/56b9bcc3c9c6a792fcbaf139543cee77261f3651ca9da0c93f5c1221264b/python_dateutil-2.9.0.post0-py2.py3-none-any.whl \
	https://files.pythonhosted.org/packages/b7/ce/149a00dd41f10bc29e5921b496af8b574d8413afcd5e30dfa0ed46c2cc5e/six-1.17.0-py2.py3-none-any.whl \
	https://files.pythonhosted.org/packages/c1/97/c698bd9350f307daad79dd740806e1a59becd693bd11443a0f531e3229b3/jsonschema-4.17.3-py3-none-any.whl \
	https://files.pythonhosted.org/packages/23/88/0acd180010aaed4987c85700b7cc17f9505f3edb4e5873e4dc67f613e338/pyrsistent-0.20.0-py3-none-any.whl
ZEPHYR_PYTHON_LICENSE = Apache-2.0 (west), BSD-3-Clause (colorama), MIT (pykwalify, ruamel.yaml, six, jsonschema, pyrsistent), Apache-2.0 or BSD-3-Clause (python-dateutil)
# Not inherited by the host package from the line above.
HOST_ZEPHYR_PYTHON_EXTRA_DOWNLOADS = $(ZEPHYR_PYTHON_EXTRA_DOWNLOADS)
HOST_ZEPHYR_PYTHON_DEPENDENCIES = \
	host-python3 host-python-installer \
	host-python-pyyaml host-python-packaging host-python-pyelftools host-python-attrs

# Wheels are not tarballs: nothing to extract.
define HOST_ZEPHYR_PYTHON_EXTRACT_CMDS
endef

# One wheel per pyinstaller.py call.
define HOST_ZEPHYR_PYTHON_INSTALL_CMDS
	for w in $(ZEPHYR_PYTHON_SOURCE) $(notdir $(ZEPHYR_PYTHON_EXTRA_DOWNLOADS)); do \
		$(HOST_PKG_PYTHON_PEP517_ENV) $(HOST_DIR)/bin/python3 \
			$(TOPDIR)/support/scripts/pyinstaller.py \
			$(HOST_ZEPHYR_PYTHON_DL_DIR)/$$w \
			--interpreter=$(HOST_DIR)/bin/python \
			--script-kind=posix \
			--purelib=$(HOST_DIR)/lib/python$(PYTHON3_VERSION_MAJOR)/site-packages \
			--headers=$(HOST_DIR)/include/python$(PYTHON3_VERSION_MAJOR) \
			--scripts=$(HOST_DIR)/bin \
			--data=$(HOST_DIR) || exit 1; \
	done
endef

$(eval $(host-generic-package))
