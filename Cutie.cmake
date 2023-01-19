# Cutie
# ~~~~~
# Cutie is a C++ UT framework, based on GoogleTest, GoogleMock, SubHook and CMock libraries.
# Cutie provides the following facilities:
#   1. A framework for writing unit tests and assertions (using GoogleTest)
#   2. A framework for setting hooks on functions for testing purposes (using hook.hpp)
#   3. A framework for setting mocks on functions for testing purposes (using mock.hpp)
# Specific documentation can be found in the header files and the READMEs in GoogleTest and GoogleMock.
#
# Using Cutie in your CMakeLists.txt
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Using Cutie in your Cutie.cmake boils down to including Cutie's Cutie.cmake.
# Follow these steps:
#   1. Set your project's languages to CXX and C
#   2. Set the CUTIE_DIR variable to Cutie's directory within your project (will probably be "Cutie"). For example:
#          set(CUTIE_DIR Cutie)
#   3. Include Cutie's Cutie.cmake. For example:
#          include(${CUTIE_DIR}/Cutie.cmake)
#   4. Call Cutie's add_cutie_test_target for each test you have. For example:
#          add_cutie_test_target(TEST test/a.cpp SOURCES src/a.c src/b.c)
#   5. Call Cutie's add_cutie_all_tests_target to add the `all_tests` target. This is optional.
#   6. Call Cutie's add_cutie_coverage_targets to add the `coverage` and `clean_coverage` targets. This is optional.
#
# Running Tests
# ~~~~~~~~~~~~~
# After integrating Cutie, run all tests using the `tests` target.
#
# Collecting Coverage
# ~~~~~~~~~~~~~~~~~~~
# After integrating Cutie, run all tests and collect coverage using the `coverage` target.
# The coverage will be collected to ${PROJECT_BINARY_DIR}/coverage.
# The coverage will be written as a series of HTML pages for your convenience.
# To view the coverage report, open ${PROJECT_BINARY_DIR}/coverage/index.html in your favorite web browser.
#
# Cleaning Coverage
# ~~~~~~~~~~~~~~~~~
# To clean coverage data, use the `clean_coverage` target.
#
cmake_minimum_required(VERSION 3.10)
set(CMAKE_CXX_STANDARD 17)
include(CTest)

## Functions
function(verify_variable variable_name)
    if (NOT DEFINED ${variable_name})
        message(FATAL_ERROR "Variable ${variable_name} must be defined")
    endif ()
endfunction()

## Verifications
verify_variable(CUTIE_DIR)
get_property(languages GLOBAL PROPERTY ENABLED_LANGUAGES)
if (NOT "CXX" IN_LIST languages)
    message(FATAL_ERROR "Project must be defined with language CXX")
endif ()

## Global Variables
set(TEST_TARGETS)

## Functions

# Define a new target to run a single test file.
#
# Usage:
#   add_cutie_test_target(TEST test [SOURCES sources...] [COMPILER_FLAGS compile_flags...] [COMPILER_DEFINITIONS compile_defs...] [LINKER_FLAGS link_flags...])
#   TEST followed by the test source file
#   SOURCES followed by additional (optional) source files list required for the test
#   COMPILER_FLAGS followed by a list of compile time flags
#   COMPILER_DEFINITIONS followed by a list of definitions for the compiler
#   LINKER_FLAGS followed by a list of link time flags
#
#   TODO improve example
# Example:
#     add_cutie_test_target(TEST test/a.cpp SOURCES src/a.c src/b.c)
function(add_cutie_test_target)
    ## Dependencies directories
    set(GOOGLETEST_DIR ${CUTIE_DIR}/googletest)
    set(SUBHOOK_DIR ${CUTIE_DIR}/subhook)
    set(CMOCK_DIR ${CUTIE_DIR}/C-Mock)

    # Parse arguments
    cmake_parse_arguments(PARSE_ARGV 0 TEST "" "TEST" "SOURCES;COMPILER_FLAGS;COMPILER_DEFINITIONS;LINKER_FLAGS")
    get_filename_component(TEST_NAME ${TEST_TEST} NAME_WE)

    # Define test target
    add_executable(${TEST_NAME} ${TEST_TEST} ${TEST_SOURCES})

    # Compiler & Linker flags
    set(COVERAGE_FLAGS -fprofile-arcs -ftest-coverage --coverage)
    set(C_MOCK_LINKER_FLAGS -rdynamic -Wl,--no-as-needed -ldl)

    # Compiling dependencies
    if (NOT DEFINED _CUTIE_DEPENDENCIES_COMPILED)
        set(INSTALL_GTEST OFF)
        add_subdirectory(${GOOGLETEST_DIR} EXCLUDE_FROM_ALL)
        set(SUBHOOK_STATIC ON)
        set(SUBHOOK_TESTS OFF)
        add_subdirectory(${SUBHOOK_DIR} EXCLUDE_FROM_ALL)
        set(_CUTIE_DEPENDENCIES_COMPILED 1 PARENT_SCOPE)
    endif ()

    target_include_directories(${TEST_NAME}
        PUBLIC
            ${CUTIE_DIR}
            ${GOOGLETEST_DIR}/googlemock/include
            ${GOOGLETEST_DIR}/googletest/include
            ${CMOCK_DIR}/include
            ${SUBHOOK_DIR}
    )

    # set build options
    target_compile_options(${TEST_NAME}
        PRIVATE
            ${COMPILER_FLAGS}
            ${COVERAGE_FLAGS}
    )

    target_compile_definitions(${TEST_NAME}
        PRIVATE
            ${COMPILER_DEFINITIONS}
    )

    target_link_libraries(${TEST_NAME}
        PUBLIC
            gmock_main
            subhook
    )
    
    target_link_options(${TEST_NAME}
        PRIVATE
            ${C_MOCK_LINKER_FLAGS}
            ${COVERAGE_FLAGS}
            ${LINKER_FLAGS}
    )

    set(TEST_TARGETS ${TEST_TARGETS} ${TEST_NAME} PARENT_SCOPE)
    add_test(NAME ${TEST_NAME} COMMAND ${TEST_NAME})
endfunction()

# Defines the `all_tests` target that runs all tests added with add_cutie_test_target()
# Function has no parameters
function(add_cutie_all_tests_target)
    add_custom_target(all_tests
            COMMAND ctest
            WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
            VERBATIM)
    add_dependencies(all_tests ${TEST_TARGETS})
endfunction()

# Defines the following two targets:
#   1. `coverage` runs all tests and collects coverage
#   2. `clean_coverage` cleans coverage information
# The collected coverage report resides in the coverage/ directory under the project's directory.
# Function has no parameters
function(add_cutie_coverage_targets)
    include(${CUTIE_DIR}/inc/CodeCoverage.cmake)
    set(COVERAGE_DIR coverage)
    setup_target_for_coverage_lcov(
            NAME ${COVERAGE_DIR}
            EXECUTABLE ctest
            EXCLUDE "${CUTIE_DIR}/*" "/usr/include/*")
    add_custom_target(clean_coverage
            rm --recursive --force ${COVERAGE_DIR}
            COMMAND find -iname "*.gcda" -delete
            COMMAND find -iname "*.gcno" -delete
            WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
            VERBATIM
            COMMENT "Deleting coverage information. Rebuild after this.")
endfunction()
