package cucumberexpressions

import (
	"fmt"
	"github.com/stretchr/testify/require"
	"gopkg.in/yaml.v3"
	"io/ioutil"
	"testing"
)

type AstExpectation struct {
	Expression  string `yaml:"expression"`
	ExpectedAst node   `yaml:"expected_ast"`
	Exception   string `yaml:"exception"`
}

func TestCucumberExpressionParser(t *testing.T) {
	var assertAst = func(t *testing.T, expected node, expression string) {
		ast, err := parse(expression)
		require.NoError(t, err)
		require.Equal(t, expected, ast)
	}
	var assertThrows = func(t *testing.T, expected string, expression string) {
		_, err := parse(expression)
		require.Error(t, err)
		require.Equal(t, expected, err.Error())
	}

	directory := "../testdata/ast/"
	files, err := ioutil.ReadDir(directory)
	require.NoError(t, err)

	for _, file := range files {
		contents, err := ioutil.ReadFile(directory + file.Name())
		require.NoError(t, err)
		t.Run(fmt.Sprintf("%s", file.Name()), func(t *testing.T) {
			var expectation AstExpectation
			err = yaml.Unmarshal(contents, &expectation)
			require.NoError(t, err)

			if expectation.Exception == "" {
				assertAst(t, expectation.ExpectedAst, expectation.Expression)
			} else {
				assertThrows(t, expectation.Exception, expectation.Expression)
			}
		})
	}

}
