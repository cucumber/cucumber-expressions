import { RegExpExecArray } from 'regexp-match-indices'

import Group from './Group.js'

export default class GroupBuilder {
  public source: string
  public capturing = true
  private readonly groupBuilders: GroupBuilder[] = []

  public add(groupBuilder: GroupBuilder) {
    this.groupBuilders.push(groupBuilder)
  }

  public build(match: RegExpExecArray, nextGroupIndex: () => number): Group | null {
    const groupIndex = nextGroupIndex()
    const children = this.groupBuilders.map((gb) => gb.build(match, nextGroupIndex))
    const value = match[groupIndex]
    if (value === undefined) return null
    const index = match.indices[groupIndex]
    const start = index[0]
    const end = index[1]
    return new Group(value, start, end, children)
  }

  public setNonCapturing() {
    this.capturing = false
  }

  get children() {
    return this.groupBuilders
  }

  public moveChildrenTo(groupBuilder: GroupBuilder) {
    this.groupBuilders.forEach((child) => groupBuilder.add(child))
  }
}
