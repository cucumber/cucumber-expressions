#ifndef CUCUMBER_EXPRESSION_ARGUMENT_HPP
#define CUCUMBER_EXPRESSION_ARGUMENT_HPP

#include "cucumber/cucumber-expressions/Group.hpp"
#include "cucumber/cucumber-expressions/ParameterRegistry.hpp"
#include <optional>
#include <string>
#include <vector>

namespace cucumber::cucumber_expressions
{
    template<class T>
    T TransformArg([[maybe_unused]] const T& _val, const std::string& name, const ConvertFunctionArg& match)
    {
        return ConverterTypeMap<std::optional<T>>::Instance().At(name)(match).value();
    }

    template<class T>
    std::optional<T> TransformArg([[maybe_unused]] const std::optional<T>& _opt, const std::string& name, const ConvertFunctionArg& match)
    {
        return ConverterTypeMap<std::optional<T>>::Instance().At(name)(match);
    }

    struct Argument
    {
    private:
        Argument(ArgumentGroup group, const ParameterType& parameter);

    public:
        static std::vector<Argument> BuildArguments(const ArgumentGroup& group, const std::vector<ParameterType>& parameters);

        template<class T>
        T GetValue() const
        {
            return TransformArg(T{}, Name(), group.Values());
        }

        [[nodiscard]] ArgumentGroup Group() const;
        [[nodiscard]] std::string Name() const;

    private:
        ArgumentGroup group;
        const ParameterType* parameter;
    };
}

#endif
