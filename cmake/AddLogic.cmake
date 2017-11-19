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

find_package(ModelSim)

set(RTL_SOURCES "" CACHE INTERNAL
    "RTL sources" FORCE)

set(RTL_INCLUDES "" CACHE INTERNAL
    "RTL includes" FORCE)

set(RTL_DEFINES "" CACHE INTERNAL
    "RTL defines" FORCE)

set(HDL_SOURCES "" CACHE INTERNAL
    "HDL sources" FORCE)

set(HDL_INCLUDES "" CACHE INTERNAL
    "HDL includes" FORCE)

set(HDL_DEFINES "" CACHE INTERNAL
    "HDL defines" FORCE)

set(VERILATOR_CONFIGURATIONS "" CACHE INTERNAL
    "Verilator configurations" FORCE)

if (MODELSIM_FOUND)
    file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/modelsim)
    file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/modelsim/.modules)

    if (NOT EXISTS ${CMAKE_BINARY_DIR}/modelsim/work/_info)
        execute_process(COMMAND ${MODELSIM_VLIB} work
            WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/modelsim)
    endif()

    if (NOT EXISTS ${CMAKE_BINARY_DIR}/modelsim/modelsim.ini)
        execute_process(COMMAND ${MODELSIM_VMAP} work work
            WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/modelsim)
    endif()

    add_custom_target(modelsim-run
        ${MODELSIM_VSIM} ${MODELSIM_TOP_LEVEL}
        DEPENDS modelsim-compile-all
        COMMENT "Running ModelSim vsim..."
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/modelsim
    )
endif()

function(add_verilator_configurations)
    set(VERILATOR_CONFIGURATIONS ${VERILATOR_CONFIGURATIONS} ${ARGV}
        CACHE INTERNAL "Verilator configurations" FORCE)
endfunction()

function(add_hdl_test test_name)
    if (MODELSIM_FOUND)
        add_test(NAME ${test_name}
            COMMAND ${MODELSIM_VSIM}
                -c
                -wlf ../output/${test_name}.wlf
                -do ${CMAKE_SOURCE_DIR}/scripts/modelsim_run.tcl
                ${test_name}
            WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/modelsim
        )
    endif()
endfunction()

function(add_modelsim_source src)
    set(MODELSIM_COMPILER)
    set(MODELSIM_FLAGS)

    if (src MATCHES .sv)
        set(MODELSIM_COMPILER ${MODELSIM_VLOG})
        set(MODELSIM_FLAGS ${MODELSIM_FLAGS} -sv)

        foreach (inc ${RTL_INCLUDES})
            set(MODELSIM_FLAGS ${MODELSIM_FLAGS} +incdir+${inc})
        endforeach()

        foreach (inc ${HDL_INCLUDES})
            set(MODELSIM_FLAGS ${MODELSIM_FLAGS} +incdir+${inc})
        endforeach()
    elseif (src MATCHES .v)
        set(MODELSIM_COMPILER ${MODELSIM_VLOG})

        foreach (inc ${RTL_INCLUDES})
            set(MODELSIM_FLAGS ${MODELSIM_FLAGS} +incdir+${inc})
        endforeach()

        foreach (inc ${HDL_INCLUDES})
            set(MODELSIM_FLAGS ${MODELSIM_FLAGS} +incdir+${inc})
        endforeach()
    elseif (src MATCHES .vhd)
        set(MODELSIM_COMPILER ${MODELSIM_VCOM})
        set(MODELSIM_FLAGS ${MODELSIM_FLAGS} -2008)
    endif()

    get_filename_component(MODELSIM_MODULE ${src} NAME_WE)

    add_custom_command(OUTPUT
            ${CMAKE_BINARY_DIR}/modelsim/.modules/${MODELSIM_MODULE}
        COMMAND ${CMAKE_COMMAND} -E touch .modules/${MODELSIM_MODULE}
        COMMAND ${MODELSIM_COMPILER} ${MODELSIM_FLAGS} ${src}
        DEPENDS ${src}
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/modelsim
    )

    add_custom_target(modelsim-compile-${MODELSIM_MODULE}
        DEPENDS ${CMAKE_BINARY_DIR}/modelsim/.modules/${MODELSIM_MODULE}
    )
endfunction()

function(create_simulation)
    set(SOURCES ${RTL_SOURCES} ${HDL_SOURCES})
    set(INCLUDES ${RTL_INCLUDES} ${HDL_INCLUDES})
    set(DEFINES ${RTL_DEFINES} ${HDL_DEFINES})

    if (MODELSIM_FOUND)
        set(MODULE_LAST)

        foreach (src ${SOURCES})
            add_modelsim_source(${src})

            get_filename_component(MODULE ${src} NAME_WE)

            if (MODULE_LAST)
                add_dependencies(modelsim-compile-${MODULE}
                    modelsim-compile-${MODULE_LAST})
            endif()

            set(MODULE_LAST ${MODULE})
        endforeach()

        add_custom_target(modelsim-compile-all
            DEPENDS modelsim-compile-${MODULE_LAST})
    endif()
endfunction()

function(add_rtl_sources)
    foreach(src ${ARGV})
        get_filename_component(src ${src} REALPATH)

        list(APPEND sources ${src})
    endforeach()

    set(RTL_SOURCES ${RTL_SOURCES} ${sources}
        CACHE INTERNAL "RTL sources" FORCE)
endfunction()

function(add_rtl_includes)
    foreach(inc ${ARGV})
        get_filename_component(inc ${inc} REALPATH)
        list(APPEND includes ${inc})
    endforeach()

    set(RTL_INCLUDES ${RTL_INCLUDES} ${includes}
        CACHE INTERNAL "RTL includes" FORCE)
endfunction()

function(add_rtl_defines)
    foreach(def ${ARGV})
        list(APPEND defines ${def})
    endforeach()

    set(RTL_DEFINES ${RTL_DEFINES} ${defines}
        CACHE INTERNAL "RTL defines" FORCE)
endfunction()

function(add_hdl_sources)
    foreach(src ${ARGV})
        get_filename_component(src ${src} REALPATH)

        list(APPEND sources ${src})
    endforeach()

    set(HDL_SOURCES ${HDL_SOURCES} ${sources}
        CACHE INTERNAL "HDL sources" FORCE)
endfunction()

function(add_hdl_includes)
    foreach(inc ${ARGV})
        get_filename_component(inc ${inc} REALPATH)
        list(APPEND includes ${inc})
    endforeach()

    set(HDL_INCLUDES ${HDL_INCLUDES} ${includes}
        CACHE INTERNAL "HDL includes" FORCE)
endfunction()

function(add_hdl_defines)
    foreach(def ${ARGV})
        list(APPEND defines ${def})
    endforeach()

    set(HDL_DEFINES ${HDL_DEFINES} ${defines}
        CACHE INTERNAL "HDL defines" FORCE)
endfunction()
