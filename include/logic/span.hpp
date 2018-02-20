/*!
 * @copyright
 * Copyright 2017 Tymoteusz Blazejczyk
 *
 * @copyright
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * @copyright
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * @copyright
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * @file json/span.hpp
 *
 * @brief JSON span interface
 */

#ifndef LOGIC_SPAN_HPP
#define LOGIC_SPAN_HPP

#include "span_iterator.hpp"

#include <algorithm>
#include <cstddef>
#include <limits>
#include <type_traits>

namespace logic {

template<typename T>
class span {
public:
    using value_type = T;
    using pointer = value_type*;
    using const_pointer = const value_type*;
    using reference = value_type&;
    using const_reference = const value_type&;
    using size_type = std::size_t;
    using difference_type = std::ptrdiff_t;
    using iterator = span_iterator<T>;
    using const_iterator = span_iterator<const T>;
    using reverse_iterator = std::reverse_iterator<iterator>;
    using const_reverse_iterator = std::reverse_iterator<const_iterator>;

    static constexpr size_type npos{std::numeric_limits<size_type>::max()};

    constexpr span() noexcept = default;

    constexpr explicit span(std::nullptr_t) noexcept;

    template<typename U = T, typename std::enable_if<
        std::is_const<U>::value>::type> constexpr
    explicit span(const span<
            typename std::remove_const<U>::type>& other) noexcept;

    template<typename U, typename = typename std::enable_if<std::is_convertible<
        typename U::pointer, pointer>::value>::type> constexpr
    explicit span(U& other) noexcept;

    template<typename U, typename = typename std::enable_if<std::is_convertible<
        typename U::pointer, pointer>::value>::type> constexpr
    explicit span(const U& other) noexcept;

    constexpr span(pointer ptr, size_type n) noexcept;

    template<typename InputIt>
    span(InputIt first, InputIt last) noexcept;

    template<std::size_t N> constexpr
    explicit span(value_type (&arr)[N]) noexcept;

    constexpr span(const span& other) noexcept = default;

    constexpr span(span&& other) noexcept = default;

    span& operator=(const span& other) noexcept = default;

    span& operator=(span&& other) noexcept = default;

    constexpr size_type size() const noexcept;

    constexpr size_type length() const noexcept;

    constexpr bool empty() const noexcept;

    constexpr bool operator!() const noexcept;

    constexpr explicit operator bool() const noexcept;

    pointer data() noexcept;

    constexpr const_pointer data() const noexcept;

    reference front() noexcept;

    constexpr const_reference front() const noexcept;

    reference back() noexcept;

    constexpr const_reference back() const noexcept;

    reference operator[](size_type pos) noexcept;

    constexpr const_reference operator[](size_type pos) const noexcept;

    span first(size_type count) const noexcept;

    span last(size_type count) const noexcept;

    span subspan(size_type offset, size_type count = npos) const noexcept;

    iterator begin() noexcept;

    const_iterator begin() const noexcept;

    const_iterator cbegin() const noexcept;

    iterator end() noexcept;

    const_iterator end() const noexcept;

    const_iterator cend() const noexcept;

    reverse_iterator rbegin() noexcept;

    const_reverse_iterator rbegin() const noexcept;

    const_reverse_iterator crbegin() const noexcept;

    reverse_iterator rend() noexcept;

    const_reverse_iterator rend() const noexcept;

    const_reverse_iterator crend() const noexcept;

    ~span() noexcept = default;
private:
    pointer m_data{nullptr};
    size_type m_size{0};
};

template<typename T> constexpr
span<T>::span(std::nullptr_t) noexcept { }

template<typename T> template<typename U, typename std::enable_if<
    std::is_const<U>::value>::type> constexpr
span<T>::span(const span<
        typename std::remove_const<U>::type>& other) noexcept :
    m_data{other.data()}, m_size{other.size()}
{ }

template<typename T> template<typename U, typename> constexpr
span<T>::span(const U& other) noexcept :
    m_data{other.data()}, m_size{other.size()}
{ }

template<typename T> template<typename U, typename> constexpr
span<T>::span(U& other) noexcept :
    m_data{other.data()}, m_size{other.size()}
{ }

template<typename T> constexpr
span<T>::span(pointer ptr, size_type n) noexcept :
    m_data{ptr}, m_size{n}
{ }

template<typename T> template<typename InputIt>
span<T>::span(InputIt first, InputIt last) noexcept :
    m_data{&*first},
    m_size{(first < last) ? size_type(last - first) : 0}
{ }

template<typename T> template<std::size_t N> constexpr
span<T>::span(value_type (&arr)[N]) noexcept :
    m_data{arr}, m_size{N}
{ }

template<typename T> constexpr auto
span<T>::size() const noexcept -> size_type {
    return m_size;
}

template<typename T> constexpr auto
span<T>::length() const noexcept -> size_type {
    return m_size;
}

template<typename T> constexpr auto
span<T>::empty() const noexcept -> bool {
    return (0 == m_size);
}

template<typename T> constexpr auto
span<T>::operator!() const noexcept -> bool {
    return (0 == m_size);
}

template<typename T> constexpr
span<T>::operator bool() const noexcept {
    return (0 != m_size);
}

template<typename T> auto
span<T>::data() noexcept -> pointer {
    return m_data;
}

template<typename T> constexpr auto
span<T>::data() const noexcept -> const_pointer {
    return m_data;
}

template<typename T> auto
span<T>::front() noexcept -> reference {
    return *m_data;
}

template<typename T> constexpr auto
span<T>::front() const noexcept -> const_reference {
    return *m_data;
}

template<typename T> auto
span<T>::back() noexcept -> reference {
    return *(m_data + m_size - 1);
}

template<typename T> constexpr auto
span<T>::back() const noexcept -> const_reference {
    return *(m_data + m_size - 1);
}

template<typename T> auto
span<T>::operator[](size_type pos) noexcept -> reference {
    return *(m_data + pos);
}

template<typename T> constexpr auto
span<T>::operator[](size_type pos) const noexcept -> const_reference {
    return *(m_data + pos);
}

template<typename T> auto
span<T>::first(size_type count) const noexcept -> span {
    if (count > size()) {
        count = size();
    }
    return {m_data, count};
}

template<typename T> auto
span<T>::last(size_type count) const noexcept -> span {
    if (count > size()) {
        count = size();
    }
    return {m_data + (size() - count), count};
}

template<typename T> auto
span<T>::subspan(size_type offset,
        size_type count) const noexcept -> span {
    return last(size() - offset).first(count);
}

template<typename T> auto
span<T>::begin() noexcept -> iterator {
    return iterator{m_data};
}

template<typename T> auto
span<T>::begin() const noexcept -> const_iterator {
    return const_iterator{m_data};
}

template<typename T> auto
span<T>::cbegin() const noexcept -> const_iterator {
    return const_iterator{m_data};
}

template<typename T> auto
span<T>::end() noexcept -> iterator {
    return iterator{m_data + m_size};
}

template<typename T> auto
span<T>::end() const noexcept -> const_iterator {
    return const_iterator{m_data + m_size};
}

template<typename T> auto
span<T>::cend() const noexcept -> const_iterator {
    return const_iterator{m_data + m_size};
}

template<typename T> auto
span<T>::rbegin() noexcept -> reverse_iterator {
    return iterator{m_data + m_size - 1};
}

template<typename T> auto
span<T>::rbegin() const noexcept -> const_reverse_iterator {
    return const_iterator{m_data + m_size - 1};
}

template<typename T> auto
span<T>::crbegin() const noexcept -> const_reverse_iterator {
    return const_iterator{m_data + m_size - 1};
}

template<typename T> auto
span<T>::rend() noexcept -> reverse_iterator {
    return iterator{m_data - 1};
}

template<typename T> auto
span<T>::rend() const noexcept -> const_reverse_iterator {
    return const_iterator{m_data - 1};
}

template<typename T> auto
span<T>::crend() const noexcept -> const_reverse_iterator {
    return const_iterator{m_data - 1};
}

template<typename T1, typename T2 = T1> static bool
operator==(const span<T1>& lhs, const span<T2>& rhs) noexcept {
    return (lhs.size() == rhs.size())
        ? std::equal(lhs.cbegin(), lhs.cend(), rhs.cbegin()) : false;
}

template<typename T1, typename T2 = T1> static bool
operator!=(const span<T1>& lhs, const span<T2>& rhs) noexcept {
    return !(lhs == rhs);
}

} /* namespace logic */

#endif /* LOGIC_SPAN_HPP */
