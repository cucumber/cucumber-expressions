using System;
using System.Text.RegularExpressions;

namespace CucumberExpressions;

public class RegularExpression : Expression {
    private readonly Regex expressionRegexp;
    private readonly IParameterTypeRegistry parameterTypeRegistry;
    private readonly TreeRegexp treeRegexp;

    /**
     * Creates a new instance. Use this when the transform types are not known in advance,
     * and should be determined by the regular expression's capture groups. Use this with
     * dynamically typed languages.
     *
     * @param expressionRegexp      the regular expression to use
     * @param parameterTypeRegistry used to look up parameter types
     */
    RegularExpression(Regex expressionRegexp, IParameterTypeRegistry parameterTypeRegistry) {
        this.expressionRegexp = expressionRegexp;
        this.parameterTypeRegistry = parameterTypeRegistry;
        this.treeRegexp = new TreeRegexp(expressionRegexp);
    }

/*    @Override
    public List<Argument<?>> match(String text, Type... typeHints) {
        final Group group = treeRegexp.match(text);
        if (group == null) {
            return null;
        }

        final ParameterByTypeTransformer defaultTransformer = parameterTypeRegistry.getDefaultParameterTransformer();
        final List<ParameterType<?>> parameterTypes = new ArrayList<>();
        int typeHintIndex = 0;
        for (GroupBuilder groupBuilder : treeRegexp.getGroupBuilder().getChildren()) {
            final String parameterTypeRegexp = groupBuilder.getSource();
            boolean hasTypeHint = typeHintIndex < typeHints.length;
            final Type typeHint = hasTypeHint ? typeHints[typeHintIndex++] : String.class;

            ParameterType<?> parameterType = parameterTypeRegistry.lookupByRegexp(parameterTypeRegexp, expressionRegexp, text);

            // When there is a conflict between the type hint from the regular expression and the method
            // prefer the the parameter type associated with the regular expression. This ensures we will
            // use the internal/user registered parameter transformer rather then the default.
            //
            // Unless the parameter type indicates it is the stronger type hint.
            if (parameterType != null && hasTypeHint && !parameterType.useRegexpMatchAsStrongTypeHint()) {
                if (!parameterType.getType().equals(typeHint)) {
                    parameterType = null;
                }
            }

            if (parameterType == null) {
                parameterType = createAnonymousParameterType(parameterTypeRegexp);
            }

            // Either from createAnonymousParameterType or lookupByRegexp
            if (parameterType.isAnonymous()) {
                parameterType = parameterType.deAnonymize(typeHint, arg -> defaultTransformer.transform(arg, typeHint));
            }

            parameterTypes.add(parameterType);
        }

        return Argument.build(group, parameterTypes);
    }*/

    public Regex getRegexp() {
        return expressionRegexp;
    }

    public String getSource() {
        return expressionRegexp.ToString();
    }
}
