# installation paths
SHAREDIR := /usr/share/selinux

AWK ?= gawk
NAME ?= $(strip $(shell $(AWK) -F= '/^SELINUXTYPE/{ print $$2 }' /etc/selinux/config))

MLSENABLED := $(shell cat /selinux/mls)
ifeq ($(MLSENABLED),)
	MLSENABLED := 1
endif

ifeq ($(MLSENABLED),1)
	MCSFLAG=-mcs
endif

ifeq ($(NAME), mls)
	NAME = strict
	MCSFLAG = -mls
endif

TYPE ?= $(NAME)${MCSFLAG}
HEADERDIR := $(SHAREDIR)/devel/include
include $(HEADERDIR)/Makefile

