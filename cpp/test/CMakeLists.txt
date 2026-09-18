add_executable(cucumber_cucumber_expressions_lib.test)

target_include_directories(cucumber_cucumber_expressions_lib.test PRIVATE
    ${PROJECT_SOURCE_DIR}/src/
)

target_link_libraries(cucumber_cucumber_expressions_lib.test PUBLIC
    cucumber::cucumber_expressions
    GTest::gmock_main
    yaml-cpp::yaml-cpp
)

target_sources(cucumber_cucumber_expressions_lib.test PRIVATE
    TestExpression.cpp
    TestExpressionParser.cpp
    TestExpressionTokenizer.cpp
    TestRegexStrategy.cpp
    TestRegexStrategyFactory.cpp
    TestRegularExpression.cpp
    TestTransformation.cpp
    TestTreeRegexp.cpp
    YamlTestData.hpp
)

target_compile_definitions(cucumber_cucumber_expressions_lib.test
    PRIVATE
        TESTDATA_SRC="${PROJECT_SOURCE_DIR}/../testdata/"
)

if (TARGET re2::re2)
    target_compile_definitions(cucumber_cucumber_expressions_lib.test
        PRIVATE
            CCR_HAS_RE2
    )
endif()

include(GoogleTest)
gtest_discover_tests(cucumber_cucumber_expressions_lib.test)
