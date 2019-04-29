.POSIX:
.SUFFIXES:
PONYC ?= ponyc

.ifdef RELEASE
VERSION = $$(cat VERSION)
.else
VERSION = $$(cat VERSION)-$$(git rev-parse --short HEAD)
PONY_ARGS ?= --debug
.endif

SRC_DIR = gopherXTreme
BUILD_DIR = build
SOURCE_FILES := $(shell find $(SRC_DIR) -name \*.pony)

all: $(SRC_DIR)

version.pony:
	@sed s/%%VERSION%%/$(VERSION)/ $(SRC_DIR)/$@.in > $(SRC_DIR)/$@

$(BUILD_DIR):
	mkdir $(BUILD_DIR)

$(SRC_DIR): version.pony $(BUILD_DIR) $(SOURCE_FILES)
	$(PONYC) $(PONY_ARGS) $(SRC_DIR) -o $(BUILD_DIR)

clean:
	echo '' > $(SRC_DIR)/version.pony
	rm build/*

