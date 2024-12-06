class Group:
    def __init__(
        self,
        value: str,
        start: int,
        end: int,
        children: list["Group"],
        name: str | None = None,
    ):
        self.children = children
        self.name = name
        self.value = value
        self.start = start
        self.end = end

    @property
    def values(self):
        return [v.value for v in self.children or [self]]
