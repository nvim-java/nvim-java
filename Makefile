SRC_DIR=lua
TESTS_ROOT=tests
TESTS_DIR?=${TESTS_ROOT}/specs
PREPARE_CONFIG=${TESTS_ROOT}/utils/prepare-config.lua
TEST_CONFIG=${TESTS_ROOT}/utils/test-config.lua
TEST_TIMEOUT?=60000

.PHONY: test tests lint format all

all: lint format tests

tests:
	@nvim \
		--headless \
		-u ${PREPARE_CONFIG} \
		"+PlenaryBustedDirectory ${TESTS_DIR} { minimal_init = '${TEST_CONFIG}', timeout = ${TEST_TIMEOUT}, sequential = true }"

test:
	@nvim \
		--headless \
		-u ${PREPARE_CONFIG} \
		"+PlenaryBustedDirectory ${FILE} { minimal_init = '${TEST_CONFIG}', timeout = ${TEST_TIMEOUT} }"

lint: 
	luacheck ${SRC_DIR} ${TESTS_DIR}

format:
	stylua ${SRC_DIR}  ${TESTS_DIR} --config-path=.stylua.toml
