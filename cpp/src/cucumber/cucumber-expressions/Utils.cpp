#include "cucumber/cucumber-expressions/Utils.hpp"

namespace cucumber::cucumber_expressions
{
    namespace
    {
        namespace detail
        {
            // NOLINTBEGIN(cppcoreguidelines-avoid-magic-numbers,readability-magic-numbers,cppcoreguidelines-pro-bounds-pointer-arithmetic)

            using Utf8Ptr = const unsigned char*;

            inline constexpr char32_t invalidCodepoint = char32_t(-1);

            char32_t Utf8Next(Utf8Ptr& ptr, Utf8Ptr end)
            {
                if (*ptr < 0x80)
                {
                    return *ptr++;
                }
                if ((*ptr & 0xE0) == 0xC0 && (end - ptr) >= 2 && (ptr[1] & 0xC0) == 0x80)
                {
                    auto byte0 = static_cast<char32_t>(*ptr++ & 0x1F);
                    auto byte1 = static_cast<char32_t>(*ptr++ & 0x3F);
                    return (byte0 << 6) | byte1;
                }
                if ((*ptr & 0xF0) == 0xE0 && (end - ptr) >= 3 && (ptr[1] & 0xC0) == 0x80 && (ptr[2] & 0xC0) == 0x80)
                {
                    auto byte0 = static_cast<char32_t>(*ptr++ & 0x0F);
                    auto byte1 = static_cast<char32_t>(*ptr++ & 0x3F);
                    auto byte2 = static_cast<char32_t>(*ptr++ & 0x3F);
                    return (byte0 << 12) | (byte1 << 6) | byte2;
                }
                if ((*ptr & 0xF8) == 0xF0 && (end - ptr) >= 4 && (ptr[1] & 0xC0) == 0x80 && (ptr[2] & 0xC0) == 0x80 &&
                    (ptr[3] & 0xC0) == 0x80)
                {
                    auto byte0 = static_cast<char32_t>(*ptr++ & 0x07);
                    auto byte1 = static_cast<char32_t>(*ptr++ & 0x3F);
                    auto byte2 = static_cast<char32_t>(*ptr++ & 0x3F);
                    auto byte3 = static_cast<char32_t>(*ptr++ & 0x3F);
                    return (byte0 << 18) | (byte1 << 12) | (byte2 << 6) | byte3;
                }
                ++ptr;
                return invalidCodepoint;
            }

            // NOLINTEND(cppcoreguidelines-avoid-magic-numbers,readability-magic-numbers,cppcoreguidelines-pro-bounds-pointer-arithmetic)
        }
    }

    std::size_t CodepointCount(std::string_view text)
    {
        std::size_t result{ 0 };

        // NOLINTBEGIN(cppcoreguidelines-pro-bounds-pointer-arithmetic,cppcoreguidelines-pro-type-reinterpret-cast)
        const auto* ptr = reinterpret_cast<const unsigned char*>(text.data());
        const auto* end = ptr + text.size();

        while (ptr < end)
        {
            if (detail::Utf8Next(ptr, end) != detail::invalidCodepoint)
            {
                ++result;
            }
        }
        // NOLINTEND(cppcoreguidelines-pro-bounds-pointer-arithmetic,cppcoreguidelines-pro-type-reinterpret-cast)

        return result;
    }
}
