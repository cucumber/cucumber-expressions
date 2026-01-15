module io.cucumber.messages {
    requires org.jspecify;
    requires org.apiguardian.api;

    exports io.cucumber.cucumberexpressions;
    
    uses io.cucumber.cucumberexpressions.PatternCompiler;
}
