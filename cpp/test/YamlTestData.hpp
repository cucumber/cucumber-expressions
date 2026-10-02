#ifndef CUCUMBER_EXPRESSIONS_TEST_YAML_TEST_DATA_HPP
#define CUCUMBER_EXPRESSIONS_TEST_YAML_TEST_DATA_HPP

#include "yaml-cpp/node/node.h"
#include "yaml-cpp/node/parse.h"
#include "yaml-cpp/yaml.h"
#include <algorithm>
#include <cctype>
#include <filesystem>
#include <fstream>
#include <gtest/gtest.h>
#include <iterator>
#include <ostream>
#include <string>
#include <string_view>
#include <vector>

namespace cucumber::cucumber_expressions
{
    // One test case sourced from a single YAML file; the file stem is used as the parameterized-test name.
    struct YamlTestCase
    {
        std::string name;
        std::string content;
    };

    inline void PrintTo(const YamlTestCase& param, std::ostream* stream)
    {
        *stream << param.name;
    }

    inline std::string Sanitize(std::string_view text)
    {
        std::string result;
        for (const char chr : text)
        {
            result += (std::isalnum(static_cast<unsigned char>(chr)) != 0) ? chr : '_';
        }
        return result.empty() ? std::string{ "empty" } : result;
    }

    inline std::vector<YamlTestCase> LoadYamlTestCases(const std::filesystem::path& directory)
    {
        std::vector<YamlTestCase> params;

        for (const auto& file : std::filesystem::directory_iterator(directory))
        {
            if (file.is_regular_file() && file.path().extension() == ".yaml")
            {
                std::ifstream file_stream(file.path());
                std::string content((std::istreambuf_iterator<char>(file_stream)), std::istreambuf_iterator<char>());
                params.push_back(YamlTestCase{ file.path().stem().string(), content });
            }
        }

        std::sort(params.begin(), params.end(),
            [](const auto& lhs, const auto& rhs)
            {
                return lhs.name < rhs.name;
            });

        return params;
    }

    inline std::string YamlTestCaseName(const testing::TestParamInfo<YamlTestCase>& info)
    {
        return Sanitize(info.param.name) + "_" + std::to_string(info.index);
    }
}

#endif
