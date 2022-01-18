class GeneratedExpression:
    def __init__(self, expression_template: str, parameter_types):
        self.expression_template = expression_template
        self.parameter_types = parameter_types

    @property
    def source(self):
        return self.expression_template % tuple([p.name for p in self.parameter_types])

    @property
    def parameter_names(self):
        usage_by_type_name = {}
        return [
            self.get_parameter_name(t.name, usage_by_type_name)
            for t in self.parameter_types
        ]

    @staticmethod
    def get_parameter_name(type_name, usage_by_type_name):
        count = usage_by_type_name.get(type_name) or 0
        count = count + 1
        usage_by_type_name[type_name] = count
        return type_name if count == 1 else f"{type_name}{count}"
