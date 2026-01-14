export default class Group {
  constructor(
    public readonly value: string,
    public readonly start: number | undefined,
    public readonly end: number | undefined,
    public readonly children: readonly Group[] | undefined
  ) {}

  get values(): string[] | null {
    return (this.children === undefined ? [this] : this.children).map((g) => g.value)
  }
}
