package cucumberexpressions

import (
	"fmt"
	"reflect"
	"regexp"
	"sort"
	"strings"
)

var INTEGER_REGEXPS = []*regexp.Regexp{
	regexp.MustCompile(`-?\d+`),
	regexp.MustCompile(`\d+`),
}
var FLOAT_REGEXPS = []*regexp.Regexp{
	regexp.MustCompile(`[-+]?\d*\.?\d+`),
}
var WORD_REGEXPS = []*regexp.Regexp{
	regexp.MustCompile(`[^\s]+`),
}
var STRING_REGEXPS = []*regexp.Regexp{
	regexp.MustCompile(`"([^"\\]*(\\.[^"\\]*)*)"|'([^'\\]*(\\.[^'\\]*)*)'`),
}
var ANONYMOUS_REGEXPS = `.*`

type ParameterTypeRegistry struct {
	parameterTypeByName    map[string]*ParameterType
	parameterTypesByRegexp map[string][]*ParameterType
	defaultTransformer     ParameterByTypeTransformer
}

func NewParameterTypeRegistry() *ParameterTypeRegistry {
	transformer := BuiltInParameterTransformer{}

	result := &ParameterTypeRegistry{
		parameterTypeByName:    map[string]*ParameterType{},
		parameterTypesByRegexp: map[string][]*ParameterType{},
		defaultTransformer:     transformer,
	}

	intParameterType, err := NewParameterType(
		"int",
		INTEGER_REGEXPS,
		"int",
		func(args ...*string) interface{} {
			i, err := transformer.Transform(*args[0], reflect.Int)
			if err != nil {
				panic(err)
			}
			return i
		},
		true,
		true,
		false,
	)
	if err != nil {
		panic(err)
	}
	err = result.DefineParameterType(intParameterType)
	if err != nil {
		panic(err)
	}

	bigintParameterType, err := NewParameterType(
		"biginteger",
		INTEGER_REGEXPS,
		"int",
		func(args ...*string) interface{} {
			i, err := transformer.Transform(*args[0], BigIntKind)
			if err != nil {
				panic(err)
			}
			return i
		},
		false,
		false,
		false,
	)
	if err != nil {
		panic(err)
	}
	err = result.DefineParameterType(bigintParameterType)
	if err != nil {
		panic(err)
	}

	floatParameterType, err := NewParameterType(
		"float",
		FLOAT_REGEXPS,
		"float32",
		func(args ...*string) interface{} {
			f, err := transformer.Transform(*args[0], reflect.Float32)
			if err != nil {
				panic(err)
			}
			return f
		},
		true,
		false,
		false,
	)
	if err != nil {
		panic(err)
	}
	err = result.DefineParameterType(floatParameterType)
	if err != nil {
		panic(err)
	}

	doubleParameterType, err := NewParameterType(
		"double",
		FLOAT_REGEXPS,
		"float64",
		func(args ...*string) interface{} {
			f, err := transformer.Transform(*args[0], reflect.Float64)
			if err != nil {
				panic(err)
			}
			return f
		},
		false,
		false,
		false,
	)
	if err != nil {
		panic(err)
	}
	err = result.DefineParameterType(doubleParameterType)
	if err != nil {
		panic(err)
	}

	byteParameterType, err := NewParameterType(
		"byte",
		FLOAT_REGEXPS,
		"int8",
		func(args ...*string) interface{} {
			f, err := transformer.Transform(*args[0], reflect.Int8)
			if err != nil {
				panic(err)
			}
			return f
		},
		false,
		false,
		false,
	)
	if err != nil {
		panic(err)
	}
	err = result.DefineParameterType(byteParameterType)
	if err != nil {
		panic(err)
	}

	shortParameterType, err := NewParameterType(
		"short",
		FLOAT_REGEXPS,
		"int16",
		func(args ...*string) interface{} {
			f, err := transformer.Transform(*args[0], reflect.Int16)
			if err != nil {
				panic(err)
			}
			return f
		},
		false,
		false,
		false,
	)
	if err != nil {
		panic(err)
	}
	err = result.DefineParameterType(shortParameterType)
	if err != nil {
		panic(err)
	}

	longParameterType, err := NewParameterType(
		"long",
		FLOAT_REGEXPS,
		"int32",
		func(args ...*string) interface{} {
			f, err := transformer.Transform(*args[0], reflect.Int64)
			if err != nil {
				panic(err)
			}
			return f
		},
		false,
		false,
		false,
	)
	if err != nil {
		panic(err)
	}
	err = result.DefineParameterType(longParameterType)
	if err != nil {
		panic(err)
	}

	bigdecimalParameterType, err := NewParameterType(
		"bigdecimal",
		FLOAT_REGEXPS,
		"BigFloat",
		func(args ...*string) interface{} {
			f, err := transformer.Transform(*args[0], BigFloatKind)
			if err != nil {
				panic(err)
			}
			return f
		},
		false,
		false,
		false,
	)
	if err != nil {
		panic(err)
	}
	err = result.DefineParameterType(bigdecimalParameterType)
	if err != nil {
		panic(err)
	}

	wordParameterType, err := NewParameterType(
		"word",
		WORD_REGEXPS,
		"string",
		func(args ...*string) interface{} {
			i, err := transformer.Transform(*args[0], reflect.String)
			if err != nil {
				panic(err)
			}
			return i
		},
		false,
		false,
		false,
	)
	if err != nil {
		panic(err)
	}
	err = result.DefineParameterType(wordParameterType)
	if err != nil {
		panic(err)
	}

	stringParameterType, err := NewParameterType(
		"string",
		STRING_REGEXPS,
		"string",
		func(args ...*string) interface{} {
			matched := func(args []*string) string {
				var value string
				if args[0] == nil && args[1] != nil {
					value = *args[1]
				} else {
					value = *args[0]
				}
				return value
			}
			value := matched(args)
			value = strings.ReplaceAll(value, "\\\"", "\"")
			value = strings.ReplaceAll(value, "\\'", "'")
			i, err := transformer.Transform(value, reflect.String)
			if err != nil {
				panic(err)
			}
			return i
		},
		true,
		false,
		false,
	)
	if err != nil {
		panic(err)
	}
	err = result.DefineParameterType(stringParameterType)
	if err != nil {
		panic(err)
	}

	anonymousParameterType, err := createAnonymousParameterType(ANONYMOUS_REGEXPS)
	if err != nil {
		panic(err)
	}
	err = result.DefineParameterType(anonymousParameterType)
	if err != nil {
		panic(err)
	}

	return result
}

func (p *ParameterTypeRegistry) ParameterTypes() []*ParameterType {
	result := make([]*ParameterType, len(p.parameterTypeByName))
	index := 0
	for _, parameterType := range p.parameterTypeByName {
		result[index] = parameterType
		index++
	}
	return result
}

func (p *ParameterTypeRegistry) LookupByTypeName(name string) *ParameterType {
	return p.parameterTypeByName[name]
}

func (p *ParameterTypeRegistry) LookupByRegexp(parameterTypeRegexp string, expressionRegexp string, text string) (*ParameterType, error) {
	parameterTypes, ok := p.parameterTypesByRegexp[parameterTypeRegexp]
	if !ok {
		return nil, nil
	}
	if len(parameterTypes) > 1 && !parameterTypes[0].PreferForRegexpMatch() {
		generatedExpressions := NewCucumberExpressionGenerator(p).GenerateExpressions(text)
		return nil, NewAmbiguousParameterTypeError(parameterTypeRegexp, expressionRegexp, parameterTypes, generatedExpressions)
	}
	return parameterTypes[0], nil
}

func (p *ParameterTypeRegistry) DefineParameterType(parameterType *ParameterType) error {
	if _, ok := p.parameterTypeByName[parameterType.Name()]; ok {
		if len(parameterType.Name()) == 0 {
			return fmt.Errorf("The anonymous parameter type has already been defined")
		}
		return fmt.Errorf("There is already a parameter type with name %s", parameterType.Name())
	}
	p.parameterTypeByName[parameterType.Name()] = parameterType
	for _, parameterTypeRegexp := range parameterType.Regexps() {
		if _, ok := p.parameterTypesByRegexp[parameterTypeRegexp.String()]; !ok {
			p.parameterTypesByRegexp[parameterTypeRegexp.String()] = []*ParameterType{}
		}
		parameterTypes := p.parameterTypesByRegexp[parameterTypeRegexp.String()]
		if len(parameterTypes) > 0 && parameterTypes[0].PreferForRegexpMatch() && parameterType.PreferForRegexpMatch() {
			return fmt.Errorf("There can only be one preferential parameter type per regexp. The regexp /%s/ is used for two preferential parameter types, {%s} and {%s}", parameterTypeRegexp.String(), parameterTypes[0].Name(), parameterType.Name())
		}
		parameterTypes = append(parameterTypes, parameterType)
		sort.Slice(parameterTypes, func(i int, j int) bool {
			return CompareParameterTypes(parameterTypes[i], parameterTypes[j]) <= 0
		})
		p.parameterTypesByRegexp[parameterTypeRegexp.String()] = parameterTypes
	}
	return nil
}
