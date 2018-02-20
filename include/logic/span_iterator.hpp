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

#ifndef LOGIC_SPAN_ITERATOR_HPP
#define LOGIC_SPAN_ITERATOR_HPP

#include <cstddef>
#include <iterator>
#include <type_traits>

namespace logic {

template<typename T>
class span_iterator {
public:
    using value_type = T;
    using pointer = value_type*;
    using reference = value_type&;
    using difference_type = std::ptrdiff_t;
    using iterator_category = std::random_access_iterator_tag;

    template<typename U>
    using is_const_t = typename std::enable_if<std::is_const<U>::value>::type;

    template<typename U>
    using remove_const_t = typename std::remove_const<U>::type;

    span_iterator() noexcept = default;

    explicit span_iterator(pointer ptr) noexcept;

    span_iterator(const span_iterator& other) noexcept = default;

    template<typename U = T, typename = is_const_t<U>>
    explicit span_iterator(const span_iterator<remove_const_t<T>>& other) noexcept;

    span_iterator(span_iterator&& other) noexcept = default;

    span_iterator& operator=(const span_iterator& other) noexcept = default;

    span_iterator& operator=(span_iterator&& other) noexcept = default;

    span_iterator& operator++() noexcept;

    const span_iterator operator++(int) noexcept;

    span_iterator& operator--() noexcept;

    const span_iterator operator--(int) noexcept;

    span_iterator operator+(difference_type n) const noexcept;

    span_iterator& operator+=(difference_type n) noexcept;

    span_iterator operator-(difference_type n) const noexcept;

    span_iterator& operator-=(difference_type n) noexcept;

    reference operator[](difference_type n) noexcept;

    reference operator[](difference_type n) const noexcept;

    reference operator*() noexcept;

    reference operator*() const noexcept;

    pointer operator->() noexcept;

    pointer operator->() const noexcept;

    ~span_iterator() noexcept = default;
private:
    pointer m_ptr{nullptr};
};

template<typename T>
template<typename U, typename> inline
span_iterator<T>::span_iterator(
        const span_iterator<remove_const_t<T>>& other) noexcept :
    m_ptr{&*other}
{ }

template<typename T> inline
span_iterator<T>::span_iterator(pointer ptr) noexcept :
    m_ptr{ptr}
{ }

template<typename T> inline auto
span_iterator<T>::operator++() noexcept -> span_iterator& {
    ++m_ptr;
    return *this;
}

template<typename T> inline auto
span_iterator<T>::operator++(int) noexcept -> const span_iterator {
    return span_iterator<T>{m_ptr++};
}

template<typename T> inline auto
span_iterator<T>::operator--() noexcept -> span_iterator& {
    --m_ptr;
    return *this;
}

template<typename T> inline auto
span_iterator<T>::operator--(int) noexcept -> const span_iterator {
    return span_iterator<T>{m_ptr--};
}

template<typename T> inline auto
span_iterator<T>::operator+(difference_type n) const noexcept ->
        span_iterator {
    return m_ptr + n;
}

template<typename T> inline auto
span_iterator<T>::operator+=(difference_type n) noexcept ->
        span_iterator& {
    m_ptr += n;
    return *this;
}

template<typename T> inline auto
span_iterator<T>::operator-(difference_type n) const noexcept ->
        span_iterator {
    return m_ptr - n;
}

template<typename T> inline auto
span_iterator<T>::operator-=(difference_type n) noexcept ->
        span_iterator& {
    m_ptr -= n;
    return *this;
}

template<typename T> inline auto
span_iterator<T>::operator[](difference_type n) noexcept -> reference {
    return *(m_ptr + n);
}

template<typename T> inline auto
span_iterator<T>::operator[](difference_type n) const noexcept -> reference {
    return *(m_ptr + n);
}

template<typename T> inline auto
span_iterator<T>::operator*() noexcept -> reference {
    return *m_ptr;
}

template<typename T> inline auto
span_iterator<T>::operator*() const noexcept -> reference {
    return *m_ptr;
}

template<typename T> inline auto
span_iterator<T>::operator->() noexcept -> pointer {
    return m_ptr;
}

template<typename T> inline auto
span_iterator<T>::operator->() const noexcept -> pointer {
    return m_ptr;
}

template<typename T, typename U> static inline auto
operator-(const span_iterator<T>& lhs, const span_iterator<U>& rhs)
        noexcept -> decltype(&(*lhs) - &(*rhs)) {
    return &(*lhs) - &(*rhs);
}

template<typename T> static inline auto
operator+(typename span_iterator<T>::difference_type n,
        const span_iterator<T>& rhs) noexcept -> span_iterator<T> {
    return n + &(*rhs);
}

template<typename T, typename U> static inline auto
operator==(const span_iterator<T>& lhs,
        const span_iterator<U>& rhs) noexcept -> bool {
    return &(*lhs) == &(*rhs);
}

template<typename T, typename U> static inline auto
operator!=(const span_iterator<T>& lhs,
        const span_iterator<U>& rhs) noexcept -> bool {
    return &(*lhs) != &(*rhs);
}

template<typename T, typename U> static inline auto
operator<(const span_iterator<T>& lhs,
        const span_iterator<U>& rhs) noexcept -> bool {
    return &(*lhs) < &(*rhs);
}

template<typename T, typename U> static inline auto
operator>(const span_iterator<T>& lhs,
        const span_iterator<U>& rhs) noexcept -> bool {
    return &(*lhs) > &(*rhs);
}

template<typename T, typename U> static inline auto
operator>=(const span_iterator<T>& lhs,
        const span_iterator<U>& rhs) noexcept -> bool {
    return &(*lhs) >= &(*rhs);
}

template<typename T, typename U> static inline auto
operator<=(const span_iterator<T>& lhs,
        const span_iterator<U>& rhs) noexcept -> bool {
    return &(*lhs) <= &(*rhs);
}

} /*namespace logic */

#endif /* LOGIC_SPAN_ITERATOR_HPP */
