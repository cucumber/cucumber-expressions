package io.cucumber.cucumberexpressions;

import java.lang.reflect.Type;
import java.util.Locale;
import org.apiguardian.api.API;

/**
 * This extension of {@link ParameterByTypeTransformer} provides an additional
 * transform method that consumes a {@link Locale locale}. Intentionally, this
 * will be the locale information specified within the feature file containing
 * the currently processed scenario.
 *
 * @see KeyboardFriendlyDecimalFormatSymbols
 */
@API(status = API.Status.EXPERIMENTAL)
@FunctionalInterface
public interface LocaleParameterByTypeTransformer extends ParameterByTypeTransformer {

  /**
   * Similar to {@link #transform(String, Type)} but, in addition, consumes a
   * {@link Locale locale}. This locale information can be ignored, or can be
   * considered in case the transformation is aware of localized values. For
   * example, numbers {@linkplain KeyboardFriendlyDecimalFormatSymbols may use
   * localized decimal symbols}.
   *
   * @implNote The default implementation ignores the {@code locale} and
   *           delegates to {@link #transform(String, Type)}
   */
  default Object transform(final String fromValue, final Type toValueType, final Locale locale) throws Throwable {
    return this.transform(fromValue, toValueType);
  }

}
