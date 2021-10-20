using System.IO;
using System.Linq;
using YamlDotNet.Serialization;
using YamlDotNet.Serialization.NamingConventions;

namespace CucumberExpressions.Tests;

public abstract class TestBase
{
    protected static string GetTestDataFilePath(string fileName, params string[] sections)
    {
        var testDataFolder = GetTestDataFolder(sections);
        var filePath = Path.Combine(testDataFolder, fileName);
        return filePath;
    }

    protected static string[] GetTestDataFiles(params string[] sections)
    {
        var testDataFolder = GetTestDataFolder(sections);
        return Directory.GetFiles(testDataFolder).OrderBy(f => f).ToArray();
    }

    protected static string GetTestDataFolder(params string[] sections)
    {
        var testAssemblyFolder = Path.GetDirectoryName(typeof(TestBase).Assembly.Location);
        var testDataFolder = Path.Combine(testAssemblyFolder!, "..", "..", "..", "..", "..", "testdata");
        if (sections != null && sections.Length > 0)
            testDataFolder = Path.Combine(new[] { testDataFolder }.Concat(sections).ToArray());
        return testDataFolder;
    }

    protected static T ParseYaml<T>(string filePath)
    {
        var fileContent = File.ReadAllText(filePath);

        var deserializer = new DeserializerBuilder()
            .WithNamingConvention(UnderscoredNamingConvention.Instance)
            .Build();

        return deserializer.Deserialize<T>(fileContent);
    }

    protected static string ToYaml(object obj)
    {
        var serializer = new SerializerBuilder()
            .WithNamingConvention(UnderscoredNamingConvention.Instance)
            .Build();
        return serializer.Serialize(obj);
    }
}