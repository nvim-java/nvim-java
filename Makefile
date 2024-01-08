SRC_DIR=lua
TESTS_DIR=tests
PREPARE_CONFIG=${TESTS_DIR}/prepare-config.lua
TEST_CONFIG=${TESTS_DIR}/test-config.lua

.PHONY: test lint format all

all: lint format test

test:
	@nvim \
		--headless \
		-u ${PREPARE_CONFIG} \
		"+PlenaryBustedDirectory ${TESTS_DIR} { minimal_init = '${TEST_CONFIG}' }"
lint: 
	luacheck ${SRC_DIR} ${TESTS_DIR}

format:
	stylua ${SRC_DIR}  ${TESTS_DIR} --config-path=.stylua.toml
