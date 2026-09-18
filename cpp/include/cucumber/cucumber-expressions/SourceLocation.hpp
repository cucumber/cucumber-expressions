#ifndef CUCUMBER_EXPRESSION_SOURCELOCATION_HPP
#define CUCUMBER_EXPRESSION_SOURCELOCATION_HPP

#include <cstdint>

namespace cucumber_cpp::library::cucumber_expression
{
    class SourceLocation
    {
    public:
#if defined(__has_builtin)
#if __has_builtin(__builtin_FILE) && __has_builtin(__builtin_LINE)
        static constexpr SourceLocation current(const char* fileName = __builtin_FILE(),
            std::uint_least32_t lineNumber = __builtin_LINE()) noexcept
#else
        static constexpr SourceLocation current(const char* fileName = __FILE__, std::uint_least32_t lineNumber = __LINE__) noexcept
#endif
#elif defined(__GNUC__) || defined(_MSC_VER)
        static constexpr SourceLocation current(const char* fileName = __builtin_FILE(),
            std::uint_least32_t lineNumber = __builtin_LINE()) noexcept
#else
        static constexpr SourceLocation current(const char* fileName = __FILE__, std::uint_least32_t lineNumber = __LINE__) noexcept
#endif
        {
            return SourceLocation{ fileName, lineNumber };
        }

        [[nodiscard]] constexpr const char* file_name() const noexcept
        {
            return fileName;
        }

        [[nodiscard]] constexpr std::uint_least32_t line() const noexcept
        {
            return lineNumber;
        }

    private:
        constexpr SourceLocation(const char* fileName, std::uint_least32_t lineNumber) noexcept
            : fileName{ fileName }
            , lineNumber{ lineNumber }
        {}

        const char* fileName;
        std::uint_least32_t lineNumber;
    };
}

#endif
