using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;

namespace CucumberExpressions;

public interface Expression {
    //List<Argument<?>> match(String text, Type... typeHints);

    Regex getRegexp();

    String getSource();
}
