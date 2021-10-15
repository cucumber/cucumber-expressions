package cucumberexpressions

import (
	"fmt"
	"github.com/stretchr/testify/require"
	"gopkg.in/yaml.v3"
	"io/ioutil"
	"testing"
)

type TransformationExpectation struct {
	Expression    string `yaml:"expression"`
	ExpectedRegex string `yaml:"expected_regex"`
}

func TestCucumberExpressionTransformation(t *testing.T) {

	t.Run("acceptance tests pass", func(t *testing.T) {
		assertRegex := func(t *testing.T, expected string, expr string) {
			parameterTypeRegistry := NewParameterTypeRegistry()
			expression, err := NewCucumberExpression(expr, parameterTypeRegistry)
			require.NoError(t, err)
			require.Equal(t, expected, expression.Regexp().String())
		}

		directory := "../testdata/cucumber-expression/transformation/"
		files, err := ioutil.ReadDir(directory)
		require.NoError(t, err)

		for _, file := range files {
			contents, err := ioutil.ReadFile(directory + file.Name())
			require.NoError(t, err)
			t.Run(fmt.Sprintf("%s", file.Name()), func(t *testing.T) {
				var expectation TransformationExpectation
				err = yaml.Unmarshal(contents, &expectation)
				require.NoError(t, err)
				assertRegex(t, expectation.ExpectedRegex, expectation.Expression)
			})
		}
	})
}
