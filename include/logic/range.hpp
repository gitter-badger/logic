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

#ifndef LOGIC_RANGE_HPP
#define LOGIC_RANGE_HPP

#include <cstddef>

#include <uvm>

namespace logic {

class range {
public:
    using size_type = std::size_t;

    range() noexcept;

    explicit range(size_type value) noexcept;

    range(size_type lhs, size_type rhs) noexcept;

    size_type min() const noexcept;

    size_type max() const noexcept;
private:
    size_type m_min;
    size_type m_max;
};

} /* namespace logic */

namespace uvm {

template<> void
uvm_config_db<logic::range>::set(uvm_component* cntxt,
        const std::string& instname, const std::string& fieldname,
        const logic::range& value);

template<> bool
uvm_config_db<logic::range>::get(uvm_component* cntxt,
        const std::string& instname, const std::string& fieldname,
        logic::range& value);

} /* namespace uvm*/

#endif /* LOGIC_RANGE_HPP */
