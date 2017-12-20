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

if (COMMAND add_qsys_jesd204)
    return()
endif()

find_package(Quartus)

set(ADD_QSYS_JESD204_DIR ${CMAKE_CURRENT_LIST_DIR}
    CACHE INTERNAL "Add Qsys JESD204 directory" FORCE)

include(CMakeParseArguments)

function(add_qsys_jesd204 target_name)
    if (NOT QUARTUS_FOUND)
        return()
    endif()

    set(options)

    set(one_value_arguments
        DEVICE
        DATA_PATH
        DEVICE_FAMILY
        SYNTHESIS
        SIMULATION
        OUTPUT_DIRECTORY
    )

    set(multi_value_arguments)

    cmake_parse_arguments(ARG "${options}" "${one_value_arguments}"
        "${multi_value_arguments}" ${ARGN})

    if (NOT DEFINED ARG_DEVICE_FAMILY)
        set(ARG_DEVICE_FAMILY "Cyclone V")
    endif()

    if (NOT DEFINED ARG_DEVICE)
        set(ARG_DEVICE 5CEBA2F17A7)
    endif()

    if (NOT DEFINED ARG_DATA_PATH)
        set(ARG_DATA_PATH TX)
    endif()

    if (NOT DEFINED ARG_OUTPUT_DIRECTORY)
        set(ARG_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
    endif()

    configure_file(${ADD_QSYS_JESD204_DIR}/AddQsysJESD204.tcl.in
        ${ARG_OUTPUT_DIRECTORY}/${target_name}.tcl)

    add_custom_command(
        OUTPUT
            ${ARG_OUTPUT_DIRECTORY}/${target_name}.qsys
        COMMAND
            ${QUARTUS_QSYS_SCRIPT}
        ARGS
            --script=${target_name}.tcl
        COMMAND
            ${QUARTUS_QSYS_GENERATE}
        ARGS
            --upgrade-ip-cores
            ${target_name}.qsys
        DEPENDS
            ${ARG_OUTPUT_DIRECTORY}/${target_name}.tcl
        WORKING_DIRECTORY
            ${ARG_OUTPUT_DIRECTORY}
    )

    if (SIMULATION)
        execute_process(
            COMMAND
                ${QUARTUS_QSYS_SCRIPT} --script=${target_name}.tcl
            WORKING_DIRECTORY
                ${ARG_OUTPUT_DIRECTORY}
        )

        execute_process(
            COMMAND
                ${QUARTUS_QSYS_GENERATE} --upgrade-ip-cores ${target_name}.qsys
            WORKING_DIRECTORY
                ${ARG_OUTPUT_DIRECTORY}
        )

        execute_process(
            COMMAND
                ${QUARTUS_QSYS_GENERATE} --simulation ${target_name}.qsys
            WORKING_DIRECTORY
                ${ARG_OUTPUT_DIRECTORY}
        )

        file(READ ${ARG_OUTPUT_DIRECTORY}/${target_name}/${target_name}.spd
            SPD_FILE)

        string(REGEX REPLACE "\n" ";" SPD_FILE "${SPD_FILE}")

        set(hdl_name_list "")

        foreach (spd_line ${SPD_FILE})
            string(REGEX MATCH
                "path=\"simulation/submodules/[a-zA-Z0-9_-]+\.s?v\""
                hdl_file "${spd_line}")

            if (NOT hdl_file)
                string(REGEX MATCH "path=\"simulation/[a-zA-Z0-9_-]+\.s?v\""
                    hdl_file "${spd_line}")
            endif()

            if (hdl_file)
                string(REGEX REPLACE ".*path=\"(.*\.s?v)\".*"
                    "\\1" hdl_file "${spd_line}")

                set(hdl_file ${ARG_OUTPUT_DIRECTORY}/${target_name}/${hdl_file})

                get_filename_component(hdl_name ${hdl_file} NAME_WE)

                add_hdl_source(${hdl_file} DEPENDS ${hdl_name_list}
                    LIBRARY ${target_name}_${hdl_name})

                list(APPEND hdl_name_list ${hdl_name})
            endif()
        endforeach()
    endif()
endfunction()
