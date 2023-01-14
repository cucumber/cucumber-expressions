package io.cucumber.cucumberexpressions;

class RegexpUtils {
    /**
     * List of characters to be escaped.
     * The last char is '}' with index 125, so we need only 126 characters.
     */
    private static final boolean[] CHAR_TO_ESCAPE = new boolean[126];
    static {
        CHAR_TO_ESCAPE['^'] = true;
        CHAR_TO_ESCAPE['$'] = true;
        CHAR_TO_ESCAPE['['] = true;
        CHAR_TO_ESCAPE[']'] = true;
        CHAR_TO_ESCAPE['('] = true;
        CHAR_TO_ESCAPE[')'] = true;
        CHAR_TO_ESCAPE['{'] = true;
        CHAR_TO_ESCAPE['}'] = true;
        CHAR_TO_ESCAPE['.'] = true;
        CHAR_TO_ESCAPE['|'] = true;
        CHAR_TO_ESCAPE['?'] = true;
        CHAR_TO_ESCAPE['*'] = true;
        CHAR_TO_ESCAPE['+'] = true;
        CHAR_TO_ESCAPE['\\'] = true;
    }

    /**
     * Escapes the regexp characters (the ones from "^$(){}[].+*?\")
     * from the given text, so that they are not considered as regexp
     * characters.
     * @param text the non-null input text
     * @return the input text with escaped regexp characters
     */
    public static String escapeRegex(String text) {
        /*
        Note on performance: this code has been benchmarked for
        escaping frequencies of 100%, 50%, 20%, 10%, 1%, 0.1%.
        Amongst 4 other variants (including Pattern matching),
        this variant is the faster on all escaping frequencies.
        */
        int length = text.length();
        StringBuilder sb = null; // lazy initialization
        int blocStart=0;
        int maxChar = CHAR_TO_ESCAPE.length;
        for (int i = 0; i < length; i++) {
            char currentChar = text.charAt(i);
            if (currentChar < maxChar && CHAR_TO_ESCAPE[currentChar]) {
                if (sb == null) {
                    sb = new StringBuilder(length * 2);
                }
                if (i > blocStart) {
                    // flush previous block
                    sb.append(text, blocStart, i);
                }
                sb.append('\\');
                sb.append(currentChar);
                blocStart=i+1;
            }
        }
        if (sb != null) {
            // finalizing character escaping
            if (length > blocStart) {
                // flush remaining characters
                sb.append(text, blocStart, length);
            }
            return sb.toString();
        }
        return text;
    }

}
