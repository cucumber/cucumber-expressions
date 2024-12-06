from cucumber_expressions.group import Group


class GroupBuilder:
    def __init__(self):
        self.group_builders: list[GroupBuilder] = []
        self.capturing: bool = True
        self.source: str | None = None
        self.end_index: int | None = None

    def add(self, group_builder: "GroupBuilder"):
        self.group_builders.append(group_builder)

    def build(self, match, group_indices, group_name_map: dict) -> Group:
        group_index = next(group_indices)
        group_name = group_name_map.get(group_index, None)

        children = [
            gb.build(match, group_indices, group_name_map) for gb in self.group_builders
        ]
        return Group(
            name=group_name,
            value=match.group(group_index),
            start=match.regs[group_index][0],
            end=match.regs[group_index][1],
            children=children,
        )

    def move_children_to(self, group_builder: "GroupBuilder") -> None:
        for child in self.group_builders:
            group_builder.add(child)

    @property
    def children(self) -> list["GroupBuilder"]:
        return self.group_builders
