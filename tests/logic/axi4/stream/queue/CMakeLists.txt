# Copyright 2017 Tymoteusz Blazejczyk
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set(MODULE_NAME logic_axi4_stream_queue)
set(MODULE_TOP ${MODULE_NAME}_top)

set(MODULE_DEFINITIONS
    LOGIC_AXI4_STREAM_TDATA_BYTES=4
    LOGIC_AXI4_STREAM_TID_WIDTH=1
    LOGIC_AXI4_STREAM_TDEST_WIDTH=1
    LOGIC_AXI4_STREAM_TUSER_WIDTH=1
)

add_systemc_module(${MODULE_TOP}
    ${RTL_SOURCES}
    DEFINITIONS ${MODULE_DEFINITIONS}
    INCLUDE_DIRECTORIES ${RTL_INCLUDES}
)

get_target_property(MODULE_LIBRARIES ${MODULE_TOP} LIBRARIES)
get_target_property(MODULE_INCLUDE_DIRS ${MODULE_TOP} INCLUDE_DIRECTORIES)

include_directories(SYSTEM
    ${MODULE_INCLUDE_DIRS}
)

set_source_files_properties(main.cpp PROPERTIES
    COMPILE_DEFINITIONS "${MODULE_DEFINITIONS}"
)

set(TEST_MODULE_NAME ${MODULE_NAME}_test)

add_executable(${TEST_MODULE_NAME}
    main.cpp
    test.cpp
)

add_test(NAME ${TEST_MODULE_NAME}
    COMMAND ${TEST_MODULE_NAME}
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/output
)

target_link_libraries(${TEST_MODULE_NAME}
    logic
    ${MODULE_LIBRARIES}
)