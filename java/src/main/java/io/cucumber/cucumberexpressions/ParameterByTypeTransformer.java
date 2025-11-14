package io.cucumber.cucumberexpressions;

import org.apiguardian.api.API;
import org.jspecify.annotations.Nullable;

import java.lang.reflect.Type;

/**
 * The {@link ParameterTypeRegistry} uses the default transformer
 * to execute all transforms for built-in parameter types and all
 * anonymous types.
 */
@API(status = API.Status.STABLE)
@FunctionalInterface
public interface ParameterByTypeTransformer {

    @Nullable
    Object transform(@Nullable String fromValue, Type toValueType) throws Throwable;
}
