export default class Group {
  constructor(
    public readonly value: string,
    public readonly start: number,
    public readonly end: number,
    public readonly children: readonly (Group | null)[]
  ) {}

  get values(): (string | null)[] {
    return (this.children.length === 0 ? [this] : this.children).map((g) => (g ? g.value : null))
  }
}
