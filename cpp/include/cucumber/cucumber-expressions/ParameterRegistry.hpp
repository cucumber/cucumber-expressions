#ifndef CUCUMBER_EXPRESSION_PARAMETERREGISTRY_HPP
#define CUCUMBER_EXPRESSION_PARAMETERREGISTRY_HPP

#include "cucumber/cucumber-expressions/SourceLocation.hpp"
#include <algorithm>
#include <any>
#include <cctype>
#include <cstddef>
#include <cstdint>
#include <cstdlib>
#include <fmt/core.h>
#include <functional>
#include <map>
#include <optional>
#include <set>
#include <sstream>
#include <stdexcept>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace cucumber::cucumber_expressions
{
    using namespace std::literals;

    struct CustomParameterEntryParams
    {
        std::string name;
        std::string regex;
        bool useForSnippets;
    };

    struct CustomParameterEntry
    {
        CustomParameterEntry(CustomParameterEntryParams params, std::size_t localId, SourceLocation location);

        CustomParameterEntryParams params;
        std::size_t localId;
        SourceLocation location;

        bool operator==(const CustomParameterEntry& other) const;
        bool operator!=(const CustomParameterEntry& other) const;
        bool operator<(const CustomParameterEntry& other) const;
        bool operator<=(const CustomParameterEntry& other) const;
        bool operator>(const CustomParameterEntry& other) const;
        bool operator>=(const CustomParameterEntry& other) const;
    };

    struct ConversionError : std::runtime_error
    {
        using std::runtime_error::runtime_error;
    };

    template<class To>
    inline To StringTo(const std::string& str)
    {
        if (str.empty())
        {
            return {};
        }

        std::istringstream stream{ str };

        To convertTo{};
        stream >> convertTo;

        if (stream.fail())
        {
            throw ConversionError{ fmt::format("Cannot convert parameter {} in to {}", str, typeid(To).name()) };
        }

        return convertTo;
    }

    template<>
    inline std::string StringTo<std::string>(const std::string& str)
    {
        return str;
    }

    template<>
    inline int32_t StringTo<std::int32_t>(const std::string& str)
    {
        return std::stoi(str);
    }

    template<>
    inline int64_t StringTo<std::int64_t>(const std::string& str)
    {
        return std::stoll(str);
    }

    template<>
    inline float StringTo<float>(const std::string& str)
    {
        return std::stof(str);
    }

    template<>
    inline double StringTo<double>(const std::string& str)
    {
        return std::stod(str);
    }

    namespace details
    {
        inline bool ichar_equals(char lhs, char rhs)
        {
            return std::tolower(static_cast<unsigned char>(lhs)) == std::tolower(static_cast<unsigned char>(rhs));
        }

        inline bool iequals(std::string_view lhs, std::string_view rhs)
        {
            return std::equal(lhs.begin(), lhs.end(), rhs.begin(), rhs.end(), ichar_equals);
        }
    }

    template<>
    inline bool StringTo<bool>(const std::string& str)
    {
        using details::iequals;

        return iequals(str, "true") || iequals(str, "1") || iequals(str, "yes") || iequals(str, "on") || iequals(str, "enabled") ||
               iequals(str, "active");
    }

    struct ParameterType
    {
        std::string name;
        std::vector<std::string> regex;
        bool isBuiltin{ false };
        bool useForSnippets{ false };
        bool preferForRegexMatch{ false };
        SourceLocation location;
    };

    using ConvertFunctionArg = std::vector<std::optional<std::string>>;

    template<class T>
    using ConverterFunction = std::function<T(const ConvertFunctionArg&)>;

    // Type-erased converter used at the host/plugin ABI boundary. The stored
    // std::function returns std::any so a single non-templated map can hold
    // converters for all return types. std::any_cast is performed at the call
    // site (host or plugin), while the underlying storage can be shared.
    using AnyConverterFunction = std::function<std::any(const ConvertFunctionArg&)>;

    using ConverterMap = std::map<std::string, AnyConverterFunction, std::less<>>;

    // Central converter registry. Each DLL has its own default map, but the
    // active pointer can be redirected to a shared (host-owned) map so
    // registrations and lookups cross DLL boundaries safely.
    struct ConverterRegistry
    {
        static ConverterMap& Instance()
        {
            return *ActivePtr();
        }

        static ConverterMap& LocalInstance()
        {
            static ConverterMap map;
            return map;
        }

        // Redirect this DLL's active converter map to an externally owned map
        // (typically the host's). Passing nullptr restores the local map.
        static void SetInstance(ConverterMap* external)
        {
            ActivePtr() = external != nullptr ? external : &LocalInstance();
        }

        static void TakeSnapshot()
        {
            Snapshot() = Instance();
        }

        static void RestoreSnapshot()
        {
            Instance() = Snapshot();
        }

    private:
        static ConverterMap*& ActivePtr()
        {
            static ConverterMap* ptr = &LocalInstance();
            return ptr;
        }

        static ConverterMap& Snapshot()
        {
            static ConverterMap snapshot;
            return snapshot;
        }
    };

    // Backwards-compatible typed accessor. Wraps/unwraps std::any so existing
    // typed callers keep working, but storage is unified in ConverterRegistry.
    template<class T>
    struct ConverterTypeMap
    {
        // Proxy allowing typed insertion/lookup against the underlying any map.
        struct Proxy
        {
            ConverterMap& map;

            void Emplace(const std::string& name, ConverterFunction<T> func)
            {
                map[name] = [func = std::move(func)](const ConvertFunctionArg& args)
                {
                    return std::any{ func(args) };
                };
            }

            struct TypedAccessor
            {
                AnyConverterFunction& func;

                T operator()(const ConvertFunctionArg& args) const
                {
                    return std::any_cast<T>(func(args));
                }
            };

            TypedAccessor At(const std::string& name)
            {
                return TypedAccessor{ map.at(name) };
            }

            struct Assigner
            {
                ConverterMap& map;
                std::string name;

                Assigner& operator=(ConverterFunction<T> func)
                {
                    map[name] = [func = std::move(func)](const ConvertFunctionArg& args)
                    {
                        return std::any{ func(args) };
                    };
                    return *this;
                }
            };

            Assigner operator[](const std::string& name)
            {
                return Assigner{ map, name };
            }
        };

        static Proxy Instance()
        {
            return Proxy{ ConverterRegistry::Instance() };
        }
    };
}

namespace cucumber::cucumber_expressions::plugin
{
    struct ParameterLoader;
}

namespace cucumber::cucumber_expressions
{
    struct ParameterRegistry
    {
        explicit ParameterRegistry(const std::set<CustomParameterEntry, std::less<>>& customParameters);
        virtual ~ParameterRegistry() = default;

        ParameterRegistry(const ParameterRegistry&) = delete;
        ParameterRegistry(ParameterRegistry&&) = delete;
        ParameterRegistry& operator=(const ParameterRegistry&) = delete;
        ParameterRegistry& operator=(ParameterRegistry&&) = delete;

        [[nodiscard]] const std::map<std::string, const ParameterType, std::less<>>& GetParameters() const;

        [[nodiscard]] const ParameterType& Lookup(const std::string& name) const;
        [[nodiscard]] const ParameterType* LookupByRegexp(const std::string& regex) const;

        template<class T>
        void AddParameter(std::string name, std::vector<std::string> regex, ConverterFunction<T> converter,
            SourceLocation location = SourceLocation::current());

    private:
        friend struct plugin::ParameterLoader;

        void AssertParameterIsUnique(const std::string& name) const;

        void AddParameter(ParameterType parameter);

        template<class T>
        void AddBuiltinParameter(std::string name, std::vector<std::string> regex, ConverterFunction<T> converter,
            bool preferForRegexMatch = false, SourceLocation location = SourceLocation::current());

        template<class T>
        void AddParameter(ParameterType parameter, ConverterFunction<T> converter);

        std::map<std::string, const ParameterType, std::less<>> parameterTypesByName;
        std::map<std::string, std::vector<const ParameterType*>, std::less<>> parameterTypesByRegex;
    };

    template<class T>
    void ParameterRegistry::AddParameter(std::string name, std::vector<std::string> regex, ConverterFunction<T> converter,
        SourceLocation location)
    {
        AddParameter(ParameterType{ .name = std::move(name),
                         .regex = std::move(regex),
                         .isBuiltin = false,
                         .useForSnippets = false,
                         .location = location },
            converter);
    }

    template<class T>
    void ParameterRegistry::AddBuiltinParameter(std::string name, std::vector<std::string> regex, ConverterFunction<T> converter,
        bool preferForRegexMatch, SourceLocation location)
    {
        AddParameter(ParameterType{ .name = std::move(name),
                         .regex = std::move(regex),
                         .isBuiltin = true,
                         .useForSnippets = false,
                         .preferForRegexMatch = preferForRegexMatch,
                         .location = location },
            converter);
    }

    template<class T>
    void ParameterRegistry::AddParameter(ParameterType parameter, ConverterFunction<T> converter)
    {
        AssertParameterIsUnique(parameter.name);

        AddParameter(parameter);

        ConverterTypeMap<T>::Instance().Emplace(parameter.name, converter);
    }
}

#endif
