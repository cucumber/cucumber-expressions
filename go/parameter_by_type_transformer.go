package cucumberexpressions

import (
	"fmt"
	"math/big"
	"reflect"
	"strconv"
)

// can be imported from "math/bits". Not yet supported in go 1.8
const uintSize = 32 << (^uint(0) >> 32 & 1) // 32 or 64

const BigFloatKind = reflect.Invalid + 1000
const BigIntKind = reflect.Invalid + 1001

type ParameterByTypeTransformer interface {
	// toValueType accepts either reflect.Type or reflect.Kind
	Transform(fromValue string, toValueType interface{}) (interface{}, error)
}

type BuiltInParameterTransformer struct {
}

func (s BuiltInParameterTransformer) Transform(fromValue string, toValueType interface{}) (interface{}, error) {
	if toValueKind, ok := toValueType.(reflect.Kind); ok {
		return transformKind(fromValue, toValueKind)
	}

	if toValueTypeType, ok := toValueType.(reflect.Type); ok {
		return transformKind(fromValue, toValueTypeType.Kind())
	}

	return nil, createError(fromValue, toValueType)
}

func transformKind(fromValue string, toValueKind interface{ String() string }) (interface{}, error) {
	switch toValueKind {
	case reflect.String:
		return fromValue, nil
	case reflect.Bool:
		return strconv.ParseBool(fromValue)
	case reflect.Int:
		return strconv.Atoi(fromValue)
	case reflect.Int8:
		i, err := strconv.ParseInt(fromValue, 10, 8)
		if err == nil {
			return int8(i), nil
		}
		return nil, err
	case reflect.Int16:
		i, err := strconv.ParseInt(fromValue, 10, 16)
		if err == nil {
			return int16(i), nil
		}
		return nil, err
	case reflect.Int32:
		i, err := strconv.ParseInt(fromValue, 10, 32)
		if err == nil {
			return int32(i), nil
		}
		return nil, err
	case reflect.Int64:
		i, err := strconv.ParseInt(fromValue, 10, 64)
		if err == nil {
			return int64(i), nil
		}
		return nil, err
	case reflect.Uint:
		i, err := strconv.ParseUint(fromValue, 10, uintSize)
		if err == nil {
			return uint(i), nil
		}
		return nil, err
	case reflect.Uint8:
		i, err := strconv.ParseUint(fromValue, 10, 8)
		if err == nil {
			return uint8(i), nil
		}
		return nil, err
	case reflect.Uint16:
		i, err := strconv.ParseUint(fromValue, 10, 16)
		if err == nil {
			return uint16(i), nil
		}
		return nil, err
	case reflect.Uint32:
		i, err := strconv.ParseUint(fromValue, 10, 32)
		if err == nil {
			return uint32(i), nil
		}
		return nil, err
	case reflect.Uint64:
		i, err := strconv.ParseUint(fromValue, 10, 64)
		if err == nil {
			return uint64(i), nil
		}
		return nil, err
	case reflect.Float32:
		f, err := strconv.ParseFloat(fromValue, 32)
		if err == nil {
			return float32(f), nil
		}
		return nil, err
	case reflect.Float64:
		return strconv.ParseFloat(fromValue, 64)
	case BigFloatKind:
		floatVal, _, err := big.ParseFloat(fromValue, 10, 1024, big.ToNearestEven)
		return floatVal, err
	case BigIntKind:
		floatVal, success := new(big.Int).SetString(fromValue, 10)
		if !success {
			return nil, fmt.Errorf("Could not parse bigint: %s", fromValue)
		}
		return floatVal, nil
	default:
		return nil, createError(fromValue, toValueKind.String())
	}
}

func createError(fromValue string, toValueType interface{}) error {
	return fmt.Errorf("Can't transform '%s' to %s. "+
		"BuiltInParameterTransformer only supports a limited number of types. "+
		"Consider using a different object mapper or register a parameter type for %s",
		fromValue, toValueType, toValueType)
}
