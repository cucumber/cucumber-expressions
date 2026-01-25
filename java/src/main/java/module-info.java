module io.cucumber.cucumberexpressions {
    requires org.jspecify;
    requires transitive org.apiguardian.api;

    exports io.cucumber.cucumberexpressions;
    
    uses io.cucumber.cucumberexpressions.PatternCompiler;
}
