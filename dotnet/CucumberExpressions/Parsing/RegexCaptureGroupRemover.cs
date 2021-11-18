using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace CucumberExpressions.Parsing
{
    internal static class RegexCaptureGroupRemover
    {
        public static string RemoveCaptureGroups(string regex)
        {
            return RemoveCaptureGroupsInternal(regex, 0);
        }
        public static string RemoveInnerCaptureGroups(string regex)
        {
            return RemoveCaptureGroupsInternal(regex, 1);
        }

        private static string RemoveCaptureGroupsInternal(string regex, int skipLevels)
        {
            if (!regex.Contains("("))
                return regex; // surely no groups
            var treeRegexp = new TreeRegexp(regex);
            var rootGroupBuilder = treeRegexp.GroupBuilder;
            if (!rootGroupBuilder.Children.Any())
                return regex;

            var result = new StringBuilder(regex);
            var groupStarts = GetGroupStarts(rootGroupBuilder, skipLevels, 0)
                .OrderByDescending(i => i);
            foreach (var groupStart in groupStarts)
            {
                result.Insert(groupStart + 1, "?:");
            }

            return result.ToString();
        }

        private static IEnumerable<int> GetGroupStarts(GroupBuilder groupBuilder, int skipLevels, int level)
        {
            foreach (var innerBuilder in groupBuilder.Children)
            {
                if (level >= skipLevels)
                    yield return innerBuilder.StartIndex;
                foreach (var groupStart in GetGroupStarts(innerBuilder, skipLevels, level + 1))
                    yield return groupStart;
            }
        }
    }
}
