#include "cucumber/cucumber-expressions/ParameterRegistry.hpp"
#include "cucumber/cucumber-expressions/Errors.hpp"
#include "cucumber/cucumber-expressions/SourceLocation.hpp"
#include <algorithm>
#include <cctype>
#include <cstdint>
#include <cstdlib>
#include <functional>
#include <map>
#include <optional>
#include <regex>
#include <set>
#include <string>
#include <tuple>
#include <utility>
#include <vector>

namespace cucumber::cucumber_expressions
{
    namespace
    {
        template<class T>
        std::function<std::optional<T>(const ConvertFunctionArg&)> CreateStreamConverter()
        {
            return [](const ConvertFunctionArg& matches) -> std::optional<T>
            {
                if (matches[0].has_value())
                {
                    return StringTo<T>(matches[0].value());
                }

                return std::nullopt;
            };
        };

        std::function<std::optional<std::string>(const ConvertFunctionArg&)> CreateStringConverter()
        {
            return [](const ConvertFunctionArg& matches) -> std::optional<std::string>
            {
                std::string str = matches[0].has_value() ? matches[0].value() : matches[1].value();

                str = std::regex_replace(str, std::regex(R"__(\\")__"), "\"");
                str = std::regex_replace(str, std::regex(R"__(\\')__"), "'");

                return str;
            };
        }

        std::function<std::optional<std::int8_t>(const ConvertFunctionArg&)> CreateByteConverter()
        {
            return [](const ConvertFunctionArg& matches) -> std::optional<std::int8_t>
            {
                if (matches[0].has_value())
                {
                    return static_cast<std::int8_t>(StringTo<std::int32_t>(matches[0].value()));
                }

                return std::nullopt;
            };
        }

        bool SortMappedByRegex(const ParameterType* lhs, const ParameterType* rhs)
        {
            if (lhs->preferForRegexMatch && !rhs->preferForRegexMatch)
            {
                return true;
            }

            if (!lhs->preferForRegexMatch && rhs->preferForRegexMatch)
            {
                return false;
            }

            return lhs->name < rhs->name;
        }

        std::string Join(const std::vector<std::string>& values, const std::string& separator)
        {
            std::string result;
            for (std::size_t index = 0; index < values.size(); ++index)
            {
                if (index > 0)
                {
                    result += separator;
                }
                result += values[index];
            }
            return result;
        }
    }

    CustomParameterEntry::CustomParameterEntry(CustomParameterEntryParams params, std::size_t localId, SourceLocation location)
        : params{ std::move(params) }
        , localId{ localId }
        , location{ location }
    {}

    bool CustomParameterEntry::operator==(const CustomParameterEntry& other) const
    {
        return std::tie(params.name, params.regex) == std::tie(other.params.name, other.params.regex);
    }

    bool CustomParameterEntry::operator!=(const CustomParameterEntry& other) const
    {
        return !(*this == other);
    }

    bool CustomParameterEntry::operator<(const CustomParameterEntry& other) const
    {
        return std::tie(params.name, params.regex) < std::tie(other.params.name, other.params.regex);
    }

    bool CustomParameterEntry::operator<=(const CustomParameterEntry& other) const
    {
        return !(other < *this);
    }

    bool CustomParameterEntry::operator>(const CustomParameterEntry& other) const
    {
        return other < *this;
    }

    bool CustomParameterEntry::operator>=(const CustomParameterEntry& other) const
    {
        return !(*this < other);
    }

    ParameterRegistry::ParameterRegistry(const std::set<CustomParameterEntry, std::less<>>& customParameters)
    {
        const static std::string integerNegativeRegex{ R"__(-?\d+)__" };
        const static std::string integerPositiveRegex{ R"__(\d+)__" };
        const static std::string floatRegex{ R"__([-+]?(?:\d+(?:\.\d+)?|\.\d+)(?:[Ee][+-]?\d+)?)__" };
        const static std::string stringRegex{ R"__("([^"\\]*(\\.[^"\\]*)*)"|'([^'\\]*(\\.[^'\\]*)*)')__" };
        const static std::string wordRegex{ R"__([^\s]+)__" };
        const static std::string anonymousRegex{ R"__(.*)__" };

        AddBuiltinParameter("int", { integerNegativeRegex, integerPositiveRegex }, CreateStreamConverter<std::int32_t>(), true);
        AddBuiltinParameter("float", { floatRegex }, CreateStreamConverter<float>());
        AddBuiltinParameter("word", { wordRegex }, CreateStreamConverter<std::string>());
        AddBuiltinParameter("string", { stringRegex }, CreateStringConverter());
        AddBuiltinParameter("", { anonymousRegex }, CreateStreamConverter<std::string>());
        AddBuiltinParameter("bigdecimal", { floatRegex }, CreateStreamConverter<double>());
        AddBuiltinParameter("biginteger", { { integerNegativeRegex, integerPositiveRegex } }, CreateStreamConverter<std::int64_t>());
        AddBuiltinParameter("byte", { { integerNegativeRegex, integerPositiveRegex } }, CreateByteConverter());
        AddBuiltinParameter("short", { { integerNegativeRegex, integerPositiveRegex } }, CreateStreamConverter<std::int16_t>());
        AddBuiltinParameter("long", { { integerNegativeRegex, integerPositiveRegex } }, CreateStreamConverter<std::int64_t>());
        AddBuiltinParameter("double", { floatRegex }, CreateStreamConverter<double>());

        // extension
        AddBuiltinParameter("bool", { wordRegex }, CreateStreamConverter<bool>());

        for (const auto& parameter : customParameters)
        {
            AddParameter(ParameterType{ parameter.params.name, { std::string(parameter.params.regex) }, false,
                parameter.params.useForSnippets, false, parameter.location });
        }
    }

    const std::map<std::string, const ParameterType, std::less<>>& ParameterRegistry::GetParameters() const
    {
        return parameterTypesByName;
    }

    const ParameterType& ParameterRegistry::Lookup(const std::string& name) const
    {
        return parameterTypesByName.at(name);
    }

    const ParameterType* ParameterRegistry::LookupByRegexp(const std::string& regex) const
    {
        if (parameterTypesByRegex.find(regex) == parameterTypesByRegex.end())
        {
            return nullptr;
        }

        const auto& parameters = parameterTypesByRegex.at(regex);

        if (parameters.size() == 0)
        {
            return nullptr;
        }

        if (parameters.size() > 1 && !parameters[0]->preferForRegexMatch)
        {
            std::vector<std::string> parameterNames;
            parameterNames.reserve(parameters.size());
            for (const auto* parameter : parameters)
            {
                parameterNames.push_back(parameter->name);
            }

            throw CucumberExpressionError{ "There are multiple parameter types but none are prefered for the regexp \"" + regex +
                                           "\": " + Join(parameterNames, ", ") };
        }

        return parameters[0];
    }

    void ParameterRegistry::AssertParameterIsUnique(const std::string& name) const
    {
        if (parameterTypesByName.find(name) != parameterTypesByName.end())
        {
            if (name.empty())
            {
                throw CucumberExpressionError{ "The anonymous parameter type has already been defined" };
            }
            else
            {
                throw CucumberExpressionError{ "There is already a parameter with name " + name };
            }
        }
    }

    void ParameterRegistry::AddParameter(ParameterType parameter)
    {
        AssertParameterIsUnique(parameter.name);

        const auto& [iter, _temp] = parameterTypesByName.try_emplace(parameter.name, parameter);
        const auto& [key, value] = *iter;

        for (const auto& regex : parameter.regex)
        {
            auto& existingParametersByRegex = parameterTypesByRegex[regex];
            if (existingParametersByRegex.size() > 0 && existingParametersByRegex[0]->preferForRegexMatch && parameter.preferForRegexMatch)
            {
                throw CucumberExpressionError{ "There can only be one preferential parameter type per regexp.\nThe regexp \"" + regex +
                                               "\" is used for two preferential parameter types, " + existingParametersByRegex[0]->name +
                                               " and " + parameter.name };
            }

            existingParametersByRegex.push_back(&value);
            std::sort(existingParametersByRegex.begin(), existingParametersByRegex.end(), SortMappedByRegex);
        }
    }
}
