# Cutie - Changelog

All notable changes to this project will be documented in this file.
* The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
* This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)

## 1.3.0 - 2024-05-06
**Added**
- Declare mockable shared
- Add optional parameter NAME to add_cutie_test_target

**Changed**
- Rework add_cutie_test_target
- Change TEST to multi_value_keywords
- Change cmake_parse_arguments prefix from TEST to ARGS

**Fixed**
- Delete files in add_cutie_coverage_gcovr_html_targets
- Fixed reorder warning

## 1.2.0 - 2023-01-20
This version is mainly a merge of branches from forks:
- [dolevelbaz/Cutie](https://github.com/dolevelbaz/Cutie)
- [Spinus1/Cutie](https://github.com/Spinus1/Cutie)

**Added**
- CHANGELOG.md file
- Windows support with dlfcn-win32 library
- gcovr support
- flag CUTIE_GTEST_XML to enable gtest xml output
- known limitations in README.md

**Changed**
- C-Mock submodule to 0.4.0
- Subhook submodule to 0.8.2
- GoogleTest submodule to 1.13.0

**Removed**
- .idea folder and files

**Fixed**
- Checks on coverage BASE_DIRECTORY
- setup_target_for_coverage_gcovr_html to avoid cyclic loop with Ninja build
- C-Mock linker flags in add_cutie_test_target
- Link in README.md

## 1.1 - 2021-06-09
Based on last available branch [mrdor44/master](https://github.com/mrdor44/Cutie/commit/de42b7e678e79cc7afe5a4ce3f203806a21978d5)

## 1.0 - 2020-07-07
Based on [mrdor44/1.0](https://github.com/mrdor44/Cutie/commit/a1c5704c7357461529241bb1d90cc575e99ec012)
