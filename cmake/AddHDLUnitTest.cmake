# Copyright 2018 Tymoteusz Blazejczyk
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

if (COMMAND add_hdl_unit_test)
    return()
endif()

if (NOT DEFINED _HDL_CMAKE_ROOT_DIR)
    set(_HDL_CMAKE_ROOT_DIR "${CMAKE_CURRENT_LIST_DIR}" CACHE INTERNAL
        "HDL CMake root directory" FORCE)
endif()

find_package(ModelSim)

include(GetHDLDepends)
include(GetHDLProperty)
include(CMakeParseArguments)

file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/modelsim/unit_tests")

function(add_hdl_unit_test hdl_file)
    if (NOT hdl_file)
        message(FATAL_ERROR "HDL file not provided as first argument")
    endif()

    get_filename_component(hdl_file "${hdl_file}" REALPATH)

    if (NOT EXISTS "${hdl_file}")
        message(FATAL_ERROR "HDL file doesn't exist: ${hdl_file}")
    endif()

    get_filename_component(hdl_name "${hdl_file}" NAME_WE)

    set(one_value_arguments
        NAME
        SOURCE
        LIBRARY
    )

    set(multi_value_arguments
        SOURCES
        DEPENDS
        DEFINES
        INCLUDES
        MODELSIM_FLAGS
        MODELSIM_SUPPRESS
        MODELSIM_WARNING_AS_ERROR
    )

    cmake_parse_arguments(ARG "" "${one_value_arguments}"
        "${multi_value_arguments}" ${ARGN})

    macro(set_default_value name value)
        if (NOT DEFINED ARG_${name})
            set(ARG_${name} ${value})
        endif()
    endmacro()

    set_default_value(NAME ${hdl_name})
    set_default_value(SOURCE "${hdl_file}")
    set_default_value(SOURCES "")
    set_default_value(DEPENDS "")
    set_default_value(DEFINES "")
    set_default_value(INCLUDES "")
    set_default_value(LIBRARY unit_test)
    set_default_value(MODELSIM_FLAGS "")
    set_default_value(MODELSIM_SUPPRESS "")
    set_default_value(MODELSIM_WARNING_AS_ERROR TRUE)

    set(test_runner_name "${ARG_NAME}_testrunner")
    set(test_runner_source "${CMAKE_CURRENT_BINARY_DIR}/${test_runner_name}.sv")

    configure_file("${_HDL_CMAKE_ROOT_DIR}/SVUnitTestRunner.sv.in"
        "${test_runner_source}")

    add_hdl_source("${ARG_SOURCE}"
        SYNTHESIZABLE
            FALSE
        SOURCES
            ${ARG_SOURCES}
        LIBRARY
            ${ARG_LIBRARY}
        DEPENDS
            svunit_pkg
            ${ARG_DEPENDS}
        DEFINES
            ${ARG_DEFINES}
        INCLUDES
            ${SVUNIT_INCLUDE_DIR}
            ${ARG_INCLUDES}
    )

    add_hdl_source("${test_runner_source}"
        SYNTHESIZABLE
            FALSE
        LIBRARY
            ${ARG_LIBRARY}
        DEPENDS
            svunit_pkg
            ${ARG_NAME}
    )

    if (MODELSIM_FOUND)
        set(modelsim_target modelsim-compile-${ARG_LIBRARY}-${ARG_NAME})
        set(unit_test_dir "${CMAKE_BINARY_DIR}/modelsim/unit_tests/${ARG_NAME}")

        if (NOT EXISTS "${unit_test_dir}")
            file(MAKE_DIRECTORY "${unit_test_dir}")
        endif()

        set(modelsim_ini "${CMAKE_BINARY_DIR}/modelsim/libraries/modelsim.ini")
        set(modelsim_waveform "${unit_test_dir}/${ARG_NAME}.wlf")

        get_filename_component(modelsim_run_tcl
            "${_HDL_CMAKE_ROOT_DIR}/../scripts/modelsim_run.tcl" REALPATH)

        if (CYGWIN)
            execute_process(COMMAND cygpath -m "${modelsim_run_tcl}"
                OUTPUT_VARIABLE modelsim_run_tcl
                OUTPUT_STRIP_TRAILING_WHITESPACE)

            execute_process(COMMAND cygpath -m "${modelsim_waveform}"
                OUTPUT_VARIABLE modelsim_waveform
                OUTPUT_STRIP_TRAILING_WHITESPACE)

            execute_process(COMMAND cygpath -m "${modelsim_ini}"
                OUTPUT_VARIABLE modelsim_ini
                OUTPUT_STRIP_TRAILING_WHITESPACE)
        endif()

        file(MAKE_DIRECTORY "${unit_test_dir}/.deps")

        set(hdl_depends "")
        set(hdl_libraries "")
        set(modelsim_flags "")

        if (DEFINED ARG_MODELSIM_SUPPRESS)
            list(LENGTH ARG_MODELSIM_SUPPRESS len)

            if (len GREATER 0)
                list(GET ARG_MODELSIM_SUPPRESS 0 suppress)
                list(REMOVE_AT ARG_MODELSIM_SUPPRESS 0)

                foreach (value ${ARG_MODELSIM_SUPPRESS})
                    set(suppress "${suppress},${value}")
                endforeach()

                list(APPEND modelsim_flags -suppress ${suppress})
            endif()
        endif()

        if (ARG_MODELSIM_WARNING_AS_ERROR)
            list(APPEND modelsim_flags -warning error)
        endif()

        list(APPEND modelsim_flags +nowarn3116)
        list(APPEND modelsim_flags -modelsimini "${modelsim_ini}")
        list(APPEND modelsim_flags -wlf "${modelsim_waveform}")
        list(APPEND modelsim_flags -do "${modelsim_run_tcl}")
        list(APPEND modelsim_flags ${ARG_MODELSIM_FLAGS})

        set(modelsim_inputs "")

        get_hdl_depends(${ARG_NAME}_testrunner hdl_depends)

        foreach (hdl_name ${hdl_depends} ${ARG_NAME}_testrunner)
            get_hdl_property(hdl_source ${hdl_name} SOURCE)
            get_filename_component(dir "${hdl_source}" DIRECTORY)

            get_hdl_property(hdl_library ${hdl_name} LIBRARY)
            list(APPEND hdl_libraries ${hdl_library})

            get_hdl_property(mif_files ${hdl_name} MIF_FILES)
            get_hdl_property(spd_files ${hdl_name} QUARTUS_SPD_FILES)
            get_hdl_property(text_files ${hdl_name} TEXT_FILES)
            get_hdl_property(input_files ${hdl_name} INPUT_FILES)

            foreach (file ${mif_files} ${text_files} ${input_files})
                if (file MATCHES "${dir}")
                    file(RELATIVE_PATH modelsim_file "${dir}" "${file}")
                    set(modelsim_file "${unit_test_dir}/${modelsim_file}")

                    add_custom_command(
                        OUTPUT
                            "${modelsim_file}"
                        COMMAND
                            ${CMAKE_COMMAND}
                        ARGS
                            -E copy "${file}" "${modelsim_file}"
                        DEPENDS
                            "${file}"
                    )

                    list(APPEND modelsim_inputs "${modelsim_file}")
                endif()
            endforeach()

            foreach (spd_file ${spd_files})
                get_filename_component(name "${spd_file}" NAME_WE)
                set(modelsim_file "${unit_test_dir}/.spd/${name}")

                add_custom_command(
                    OUTPUT
                        "${modelsim_file}"
                    COMMAND
                        ${CMAKE_COMMAND}
                    ARGS
                        -DSPD_FILE="${spd_file}"
                        -DMODELSIM_HEX_OUTPUT="${unit_test_dir}"
                        -P "${_HDL_CMAKE_ROOT_DIR}/AddQuartusFileSPD.cmake"
                    COMMAND
                        ${CMAKE_COMMAND}
                    ARGS
                        -E touch "${modelsim_file}"
                    DEPENDS
                        "${spd_file}"
                        "${hdl_source}"
                )

                list(APPEND modelsim_inputs "${modelsim_file}")
            endforeach()
        endforeach()

        if (modelsim_inputs)
            add_custom_target(${modelsim_target}-init
                DEPENDS ${modelsim_inputs}
            )

            add_dependencies(${modelsim_target}-init ${modelsim_target})
            add_dependencies(${modelsim_target}_testrunner
                ${modelsim_target}-init)
        endif()

        list(APPEND hdl_libraries work)
        list(REMOVE_DUPLICATES hdl_libraries)

        foreach (hdl_library ${hdl_libraries})
            list(APPEND modelsim_flags -L ${hdl_library})
        endforeach()

        add_test(
            NAME
                ${ARG_NAME}
            COMMAND
                ${MODELSIM_VSIM}
                -c
                ${modelsim_flags}
                unit_test.${ARG_NAME}_testrunner
            WORKING_DIRECTORY
                "${unit_test_dir}"
        )

        set(modelsim_simulator "${MODELSIM_VSIM}")
        set(modelsim_target unit_test.${ARG_NAME}_testrunner)
        string(REGEX REPLACE ";" " " modelsim_flags "${modelsim_flags}")

        configure_file("${_HDL_CMAKE_ROOT_DIR}/ModelSim.tcl.in"
            "${unit_test_dir}/.tmp/run_modelsim.tcl")

        file(
            COPY
                "${unit_test_dir}/.tmp/run_modelsim.tcl"
            DESTINATION
                "${unit_test_dir}"
            FILE_PERMISSIONS
                OWNER_READ
                OWNER_WRITE
                OWNER_EXECUTE
                GROUP_READ
                GROUP_EXECUTE
                WORLD_READ
                WORLD_EXECUTE
        )
    endif()
endfunction()
