package cucumberexpressions

import (
	"fmt"
	"github.com/stretchr/testify/require"
	"gopkg.in/yaml.v3"
	"io/ioutil"
	"math/big"
	"reflect"
	"regexp"
	"testing"
)

type CucumberExpressionMatchingExpectation struct {
	Expression   string        `yaml:"expression"`
	Text         string        `yaml:"text"`
	ExpectedArgs []interface{} `yaml:"expected_args"`
	Exception    string        `yaml:"exception"`
}

func TestCucumberExpression(t *testing.T) {

	t.Run("acceptance tests pass", func(t *testing.T) {

		assertMatches := func(t *testing.T, expectedArgs []interface{}, expr string, text string) {
			parameterTypeRegistry := NewParameterTypeRegistry()
			expression, err := NewCucumberExpression(expr, parameterTypeRegistry)
			require.NoError(t, err)
			args, err := expression.Match(text)
			require.NoError(t, err)
			require.Equal(t, expectedArgs, argumentValues(args))
		}

		assertThrows := func(t *testing.T, expected string, expr string, text string) {
			parameterTypeRegistry := NewParameterTypeRegistry()
			expression, err := NewCucumberExpression(expr, parameterTypeRegistry)

			if err != nil {
				require.Error(t, err)
				require.Equal(t, expected, err.Error())
			} else {
				_, err = expression.Match(text)
				require.Error(t, err)
				require.Equal(t, expected, err.Error())
			}
		}

		directory := "../testdata/cucumber-expression/matching/"
		files, err := ioutil.ReadDir(directory)
		require.NoError(t, err)

		for _, file := range files {
			contents, err := ioutil.ReadFile(directory + file.Name())
			require.NoError(t, err)
			t.Run(fmt.Sprintf("%s", file.Name()), func(t *testing.T) {
				var expectation CucumberExpressionMatchingExpectation
				err = yaml.Unmarshal(contents, &expectation)
				require.NoError(t, err)
				if expectation.Exception == "" {
					assertMatches(t, expectation.ExpectedArgs, expectation.Expression, expectation.Text)
				} else {
					assertThrows(t, expectation.Exception, expectation.Expression, expectation.Text)
				}
			})
		}
	})

	t.Run("documents expression generation", func(t *testing.T) {
		parameterTypeRegistry := NewParameterTypeRegistry()

		expr := "I have {int} cuke(s)"
		expression, err := NewCucumberExpression(expr, parameterTypeRegistry)
		require.NoError(t, err)
		args, err := expression.Match("I have 7 cukes")
		require.NoError(t, err)
		require.Equal(t, args[0].GetValue(), 7)
	})

	t.Run("matches float", func(t *testing.T) {
		require.Equal(t, MatchCucumberExpression(t, "{float}", ""), []interface{}(nil))
		require.Equal(t, MatchCucumberExpression(t, "{float}", "."), []interface{}(nil))
		require.Equal(t, MatchCucumberExpression(t, "{float}", ","), []interface{}(nil))
		require.Equal(t, MatchCucumberExpression(t, "{float}", "-"), []interface{}(nil))
		require.Equal(t, MatchCucumberExpression(t, "{float}", "E"), []interface{}(nil))
		require.Equal(t, MatchCucumberExpression(t, "{float}", "1,"), []interface{}(nil))
		require.Equal(t, MatchCucumberExpression(t, "{float}", ",1"), []interface{}(nil))
		require.Equal(t, MatchCucumberExpression(t, "{float}", "1."), []interface{}(nil))

		require.Equal(t, MatchCucumberExpression(t, "{float}", "1"), []interface{}{1.0})
		require.Equal(t, MatchCucumberExpression(t, "{float}", "-1"), []interface{}{-1.0})
		require.Equal(t, MatchCucumberExpression(t, "{float}", "1.1"), []interface{}{1.1})
		require.Equal(t, MatchCucumberExpression(t, "{float}", "1,000"), []interface{}(nil))
		require.Equal(t, MatchCucumberExpression(t, "{float}", "1,000,0"), []interface{}(nil))
		require.Equal(t, MatchCucumberExpression(t, "{float}", "1,000.1"), []interface{}(nil))
		require.Equal(t, MatchCucumberExpression(t, "{float}", "1,000,10"), []interface{}(nil))
		require.Equal(t, MatchCucumberExpression(t, "{float}", "1,0.1"), []interface{}(nil))
		require.Equal(t, MatchCucumberExpression(t, "{float}", "1,000,000.1"), []interface{}(nil))
		require.Equal(t, MatchCucumberExpression(t, "{float}", "-1.1"), []interface{}{-1.1})

		require.Equal(t, MatchCucumberExpression(t, "{float}", ".1"), []interface{}{0.1})
		require.Equal(t, MatchCucumberExpression(t, "{float}", "-.1"), []interface{}{-0.1})
		require.Equal(t, MatchCucumberExpression(t, "{float}", "-.10000001"), []interface{}{-0.10000001})
		require.Equal(t, MatchCucumberExpression(t, "{float}", "1e1"), []interface{}(nil))
		require.Equal(t, MatchCucumberExpression(t, "{float}", ".1E1"), []interface{}(nil))
		require.Equal(t, MatchCucumberExpression(t, "{float}", "E1"), []interface{}(nil))
		require.Equal(t, MatchCucumberExpression(t, "{float}", "-.1E-1"), []interface{}(nil))
		require.Equal(t, MatchCucumberExpression(t, "{float}", "-.1E-2"), []interface{}(nil))
		require.Equal(t, MatchCucumberExpression(t, "{float}", "-.1E+1"), []interface{}(nil))
		require.Equal(t, MatchCucumberExpression(t, "{float}", "-.1E+2"), []interface{}(nil))
		require.Equal(t, MatchCucumberExpression(t, "{float}", "-.1E1"), []interface{}(nil))
		require.Equal(t, MatchCucumberExpression(t, "{float}", "-.10E2"), []interface{}(nil))
	})

	t.Run("matches float with zero", func(t *testing.T) {
		require.Equal(
			t,
			MatchCucumberExpression(t, "{float}", "0"),
			[]interface{}{0.0},
		)
		require.Equal(
			t,
			MatchCucumberExpression(t, "{float}", "-1"),
			[]interface{}{-1.0},
		)
	})

	t.Run("matches anonymous", func(t *testing.T) {
		require.Equal(
			t,
			MatchCucumberExpression(t, "{}", ".22", reflect.TypeOf(float64(0))),
			[]interface{}{float64(0.22)},
		)
		require.Equal(
			t,
			MatchCucumberExpression(t, "{}", "0.22", reflect.TypeOf(float64(0))),
			[]interface{}{float64(0.22)},
		)
	})

	t.Run("exposes source", func(t *testing.T) {
		expr := "I have {int} cuke(s)"
		parameterTypeRegistry := NewParameterTypeRegistry()
		expression, err := NewCucumberExpression(expr, parameterTypeRegistry)
		require.NoError(t, err)
		require.Equal(t, expression.Source(), expr)
	})

	t.Run("unmatched optional groups have nil values", func(t *testing.T) {
		parameterTypeRegistry := NewParameterTypeRegistry()
		colorParameterType, err := NewParameterType(
			"textAndOrNumber",
			[]*regexp.Regexp{
				regexp.MustCompile("([A-Z]+)?(?: )?([0-9]+)?"),
			},
			"color",
			func(args ...*string) interface{} { return args },
			false,
			true,
			false,
		)
		require.NoError(t, err)
		err = parameterTypeRegistry.DefineParameterType(colorParameterType)

		expr := "{textAndOrNumber}"
		expression, err := NewCucumberExpression(expr, parameterTypeRegistry)
		require.NoError(t, err)
		tla := "TLA"
		tlaArgs, err := expression.Match(tla)
		require.NoError(t, err)
		require.Equal(t, tlaArgs[0].GetValue(), []*string{&tla, nil})
		num := "123"
		numArgs, err := expression.Match(num)
		require.NoError(t, err)
		require.Equal(t, numArgs[0].GetValue(), []*string{nil, &num})
	})
}

func MatchCucumberExpression(t *testing.T, expr string, text string, typeHints ...reflect.Type) []interface{} {
	parameterTypeRegistry := NewParameterTypeRegistry()
	expression, err := NewCucumberExpression(expr, parameterTypeRegistry)
	require.NoError(t, err)
	args, err := expression.Match(text, typeHints...)
	require.NoError(t, err)
	return argumentValues(args)
}

func argumentValues(args []*Argument) []interface{} {
	if args == nil {
		return nil
	}
	result := make([]interface{}, len(args))
	for i, arg := range args {
		value := arg.GetValue()
		switch v := value.(type) {
		case *big.Float:
			result[i] = fmt.Sprintf("%v", v)
		case *big.Int:
			result[i] = fmt.Sprintf("%v", v)
		default:
			result[i] = value
		}
	}
	return result
}
