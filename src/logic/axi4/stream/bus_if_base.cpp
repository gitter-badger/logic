/* Copyright 2018 Tymoteusz Blazejczyk
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "logic/axi4/stream/bus_if_base.hpp"

#include <queue>

using logic::axi4::stream::bus_if_base;

bus_if_base::bus_if_base(const sc_core::sc_module_name& name) :
    sc_core::sc_module{name},
    aclk{"aclk"},
    areset_n{"areset_n"},
    tvalid{"tvalid"},
    tready{"tready"},
    tlast{"tlast"},
    m_random_generator{}
{
    std::random_device rd;
    m_random_generator.seed(rd());
}

void bus_if_base::trace(sc_core::sc_trace_file* trace_file) const {
    if (trace_file != nullptr) {
        sc_core::sc_trace(trace_file, aclk, aclk.name());
        sc_core::sc_trace(trace_file, areset_n, areset_n.name());
        sc_core::sc_trace(trace_file, tvalid, tvalid.name());
        sc_core::sc_trace(trace_file, tready, tready.name());
        sc_core::sc_trace(trace_file, tlast, tlast.name());
    }
}

void bus_if_base::aclk_posedge() {
    sc_core::wait(aclk.posedge_event());
}

bool bus_if_base::get_areset_n() const {
    return areset_n.read();
}

void bus_if_base::set_tvalid(bool value) {
    tvalid.write(value);
}

bool bus_if_base::get_tvalid() const {
    return tvalid.read();
}

void bus_if_base::set_tready(bool value) {
    tready.write(value);
}

bool bus_if_base::get_tready() const {
    return tready.read();
}

void bus_if_base::set_tlast(bool value) {
    tlast.write(value);
}

bool bus_if_base::get_tlast() const {
    return tlast.read();
}

bus_if_base::~bus_if_base() = default;

void bus_if_base::write(const span<std::uint8_t>& data, std::size_t id,
        std::size_t dest, std::size_t idle_max, std::size_t idle_min) {
    if (!data.empty()) {
        std::uniform_int_distribution<std::size_t>
            random_idle(idle_min, idle_max);

        bitstream bits{sizeof(std::size_t) * 8};
        bool is_running = true;
        std::size_t total_size = data.size();
        std::size_t index = 0;
        std::size_t idle = 0;
        const std::size_t tdata_bytes = size();

        while (is_running) {
            if (!get_areset_n()) {
                is_running = false;
            }
            else if (get_tready()) {
                if (index >= total_size) {
                    is_running = false;
                }
                else if (0 == idle) {
                    idle = random_idle(m_random_generator);

                    for (std::size_t i = 0; i < tdata_bytes; ++i) {
                        if (index < total_size) {
                            set_tkeep(i, true);
                            set_tstrb(i, true);
                            set_tdata(i, data[index++]);
                        }
                        else {
                            set_tkeep(i, false);
                            set_tstrb(i, false);
                            set_tdata(i , 0u);
                        }
                    }

                    set_tid(bits = id);
                    set_tdest(bits = dest);
                    set_tlast(index >= total_size);
                    set_tvalid(true);
                    aclk_posedge();
                }
                else {
                    --idle;
                   set_tvalid(false) ;
                    aclk_posedge();
                }
            }
            else {
                aclk_posedge();
            }
        }
    }

   set_tvalid(false) ;
}

void bus_if_base::read(std::vector<std::uint8_t>& data, std::size_t id,
        std::size_t dest, std::size_t idle_max, std::size_t idle_min) {

}
