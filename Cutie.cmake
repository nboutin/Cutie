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

# dlfcn-win32 Support
if (WIN32)
  option(USE_DLFCN_WIN32_PACKAGE "Use dlfcn-win32 system package (if false dlfcn is build from source)" FALSE)
  if(${USE_DLFCN_WIN32_PACKAGE})
    #MSYS2 case (dlfcn package can be installed)
    find_package(dlfcn-win32 REQUIRED)
    set(CMAKE_DL_LIBS dlfcn-win32::dl)
    set(BUILD_DLFCN FALSE)
  else()
    set(CMAKE_DL_LIBS dl)
    get_filename_component(DLFCN_DIR ${CUTIE_DIR}/dlfcn-win32 REALPATH)
    set(BUILD_DLFCN TRUE)
  endif()
endif ()

## Global Variables
set(TEST_TARGETS)

## Functions

# Define a new target to run a test executable
#
# Usage:
#   add_cutie_test_target(
#     TEST test (test source file)
#     [SOURCES sources...] ((optional) source files list required for the test)
#     [COMPILER_FLAGS compile_flags...] ((optional) compile time flags list)
#     [COMPILER_DEFINITIONS compile_defs...] ((optional) definitions for the compiler list)
#     [LINKER_FLAGS link_flags...] ((optional) link time flags list)
#     [INCLUDE_DIRECTORIES include_dirs...] ((optional) additional include directories list)
#     [LINK_LIBRARIES link_libs...] ((optional) additional link libraries list)
#   )
# Example:
#     add_cutie_test_target(TEST test/a.cpp)
#     add_cutie_test_target(TEST test/a.cpp SOURCES src/a.c src/b.c)
function(add_cutie_test_target)
    # Parse arguments
    set(options "")
    set(one_value_keywords "TEST")
    set(multi_value_keywords "SOURCES;COMPILER_FLAGS;COMPILER_DEFINITIONS;LINKER_FLAGS;INCLUDE_DIRECTORIES;LINK_LIBRARIES")
    # - start parsing at 0
    # - prefix = TEST
    cmake_parse_arguments(PARSE_ARGV 0 TEST "${options}" "${one_value_keywords}" "${multi_value_keywords}")
    get_filename_component(TEST_NAME ${TEST_TEST} NAME_WE)

    ## Dependencies directories
    set(GOOGLETEST_DIR ${CUTIE_DIR}/googletest)
    set(SUBHOOK_DIR ${CUTIE_DIR}/subhook)
    set(C_MOCK_DIR ${CUTIE_DIR}/C-Mock)
    if(${BUILD_DLFCN})
        set(DLFCN_BIN_DIR ${DLFCN_DIR}/build)
    endif()
    set(GOOGLETEST_BIN_DIR ${GOOGLETEST_DIR}/build)
    set(SUBHOOK_BIN_DIR ${SUBHOOK_DIR}/build)

    # Define test target
    add_executable(${TEST_NAME} ${TEST_TEST} ${TEST_SOURCES})

    # Compiler & Linker flags
    set(COVERAGE_FLAGS -fprofile-arcs -ftest-coverage --coverage)

    if(WIN32)
      set(C_MOCK_LINKER_FLAGS -Wl,--export-all-symbols,--no-as-needed -O0)
    else()
      set(C_MOCK_LINKER_FLAGS -rdynamic -Wl,--no-as-needed -ldl)
    endif()

    # Compiling dependencies
    if (NOT DEFINED _CUTIE_DEPENDENCIES_COMPILED)
        set(INSTALL_GTEST OFF)
        add_subdirectory(${GOOGLETEST_DIR} ${GOOGLETEST_BIN_DIR} EXCLUDE_FROM_ALL)
        set(SUBHOOK_STATIC ON)
        set(SUBHOOK_TESTS OFF)
        add_subdirectory(${SUBHOOK_DIR} ${SUBHOOK_BIN_DIR} EXCLUDE_FROM_ALL)
        if(${BUILD_DLFCN})
          add_subdirectory(${DLFCN_DIR} ${DLFCN_BIN_DIR} EXCLUDE_FROM_ALL)
        endif()
        set(_CUTIE_DEPENDENCIES_COMPILED 1 PARENT_SCOPE)
    endif ()

    target_include_directories(${TEST_NAME}
        PUBLIC
            ${CUTIE_DIR}
            ${GOOGLETEST_DIR}/googlemock/include
            ${GOOGLETEST_DIR}/googletest/include
            ${C_MOCK_DIR}/include
            ${SUBHOOK_DIR}
            "$<$<BOOL:${BUILD_DLFCN}>:${DLFCN_DIR}/src>"
            ${TEST_INCLUDE_DIRECTORIES}
    )

    # set build options
    target_compile_options(${TEST_NAME}
        PRIVATE
            ${TEST_COMPILER_FLAGS}
            ${COVERAGE_FLAGS}
    )

    target_compile_definitions(${TEST_NAME}
        PRIVATE
            ${TEST_COMPILER_DEFINITIONS}
    )

    target_link_libraries(${TEST_NAME}
        PUBLIC
            gmock_main
            subhook
	    ${CMAKE_DL_LIBS}
            ${TEST_LINK_LIBRARIES}
    )

    target_link_options(${TEST_NAME}
        PRIVATE
            ${C_MOCK_LINKER_FLAGS}
            ${COVERAGE_FLAGS}
            ${TEST_LINKER_FLAGS}
    )

    set(TEST_TARGETS ${TEST_TARGETS} ${TEST_NAME} PARENT_SCOPE)

    if (DEFINED CUTIE_GTEST_XML)
      set(TEST_ARGS "--gtest_output=xml:${TEST_NAME}.xml")
    endif ()

    add_test(NAME ${TEST_NAME} COMMAND ${TEST_NAME} ${TEST_ARGS})
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


# Defines the following two targets:
#   1. `coverage_gcovr_xml` runs all tests and collects coverage in xml format
#   2. `clean_coverage_gcovr_xml` cleans coverage information
# The collected coverage report resides in the coverage/ directory under the project's directory.
# Function has no parameters
function(add_cutie_coverage_gcovr_targets)
    include(${CUTIE_DIR}/inc/CodeCoverage.cmake)
    set(COVERAGE_DIR coverage_gcovr_xml)
    setup_target_for_coverage_gcovr_xml(
            NAME ${COVERAGE_DIR}
	    BASE_DIRECTORY ${BASE_DIRECTORY}
            EXECUTABLE ctest
            EXCLUDE "${CUTIE_DIR}/*" "/usr/include/*"
			)
    add_custom_target(clean_coverage_gcovr_xml
            rm --recursive --force ${COVERAGE_DIR}
            COMMAND find -iname "*.gcda" -delete
            COMMAND find -iname "*.gcno" -delete
            WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
            VERBATIM
            COMMENT "Deleting coverage information. Rebuild after this.")
endfunction()



# Defines the following two targets:
#   1. `coverage_gcovr_html_target` runs all tests and collects coverage in html format
#   2. `clean_coverage_gcovr_html` cleans coverage information
# The collected coverage report resides in the coverage/ directory under the project's directory.
# Function has no parameters
function(add_cutie_coverage_gcovr_html_targets)
    include(${CUTIE_DIR}/inc/CodeCoverage.cmake)
    set(COVERAGE_DIR coverage_gcovr_html)
    setup_target_for_coverage_gcovr_html(
            NAME ${COVERAGE_DIR}
	    BASE_DIRECTORY ${BASE_DIRECTORY}
            EXECUTABLE ctest
            EXCLUDE "${CUTIE_DIR}/*" "/usr/include/*")
    add_custom_target(clean_coverage_gcovr_html
            rm --recursive --force ${COVERAGE_DIR}
            COMMAND find -iname "*.gcda" -delete
            COMMAND find -iname "*.gcno" -delete
            WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
            VERBATIM
            COMMENT "Deleting coverage information. Rebuild after this.")
endfunction()
