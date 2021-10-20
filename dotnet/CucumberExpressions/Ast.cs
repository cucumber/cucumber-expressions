using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace CucumberExpressions;

public class Ast
{

	public const char escapeCharacter = '\\';
	public const char alternationCharacter = '/';
	public const char beginParameterCharacter = '{';
	public const char endParameterCharacter = '}';
	public const char beginOptionalCharacter = '(';
	public const char endOptionalCharacter = ')';

	public interface Located
	{
		int start { get; }

		int end { get; }
	}

	public class Node : Located
	{

		public Type type { get; }
		public List<Node> nodes { get; }
		public string token { get; }
		public int start { get; }
		public int end { get; }

		public Node(Type type, int start, int end, string token) :
			this(type, start, end, null, token)
		{
		}

		public Node(Type type, int start, int end, List<Node> nodes) :
			this(type, start, end, nodes, null)
		{
		}

		private Node(Type type, int start, int end, List<Node> nodes, string token)
		{
			this.type = type;
			this.nodes = nodes;
			this.token = token;
			this.start = start;
			this.end = end;
		}

		public enum Type
		{
			TEXT_NODE,
			OPTIONAL_NODE,
			ALTERNATION_NODE,
			ALTERNATIVE_NODE,
			PARAMETER_NODE,
			EXPRESSION_NODE
		}


		public string text
		{
			get
			{
				if (nodes == null)
					return token;

				return string.Join("", nodes.Select(n => n.text));
			}
		}

		public override string ToString()
		{
			return toString(0).ToString();
		}

		private StringBuilder toString(int depth)
		{
			StringBuilder sb = new StringBuilder();
			for (int i = 0; i < depth; i++)
			{
				sb.Append("  ");
			}

			sb.Append("{")
				.Append("\"type\": \"").Append(type)
				.Append("\", \"start\": ")
				.Append(start)
				.Append(", \"end\": ")
				.Append(end);

			if (token != null)
			{
				sb.Append(", \"token\": \"").Append(token.Replace("\\\\", "\\\\\\\\")).Append("\"");
			}

			if (nodes != null)
			{
				sb.Append(", \"nodes\": ");
				if (nodes.Any())
				{
					StringBuilder padding = new StringBuilder();
					for (int i = 0; i < depth; i++)
					{
						padding.Append("  ");
					}

					sb.Append(
						"[\n" + string.Join(",\n", nodes.Select(node => node.toString(depth + 1)))
							  + "\n" + padding + "]");
				}
				else
				{
					sb.Append("[]");
				}
			}

			sb.Append("}");
			return sb;
		}

		private bool Equals(Node other)
		{
			return type == other.type && 
                   (Equals(nodes, other.nodes) || 
					nodes != null && other.nodes != null && nodes.SequenceEqual(other.nodes)) && 
                   token == other.token && 
                   start == other.start &&
				   end == other.end;
		}

		public override bool Equals(object obj)
		{
			if (ReferenceEquals(null, obj)) return false;
			if (ReferenceEquals(this, obj)) return true;
			if (obj.GetType() != this.GetType()) return false;
			return Equals((Node)obj);
		}

		public override int GetHashCode()
		{
			unchecked
			{
				var hashCode = (int)type;
				hashCode = (hashCode * 397) ^ (nodes != null ? nodes.GetHashCode() : 0);
				hashCode = (hashCode * 397) ^ (token != null ? token.GetHashCode() : 0);
				hashCode = (hashCode * 397) ^ start;
				hashCode = (hashCode * 397) ^ end;
				return hashCode;
			}
		}
	}

	public class Token : Located
	{

		public string text { get; }
		public Token.Type type { get; }
		public int start { get; }
		public int end { get; }

		public Token(string text, Token.Type type, int start, int end)
		{
			this.text = text ?? throw new ArgumentNullException(nameof(text));
			this.type = type;
			this.start = start;
			this.end = end;
		}

		public static bool canEscape(char token)
		{
			if (char.IsWhiteSpace(token))
			{
				return true;
			}

			switch (token)
			{
				case escapeCharacter:
				case alternationCharacter:
				case beginParameterCharacter:
				case endParameterCharacter:
				case beginOptionalCharacter:
				case endOptionalCharacter:
					return true;
			}

			return false;
		}

		public static Type typeOf(char token)
		{
			if (char.IsWhiteSpace(token))
			{
				return Type.WHITE_SPACE;
			}

			switch (token)
			{
				case alternationCharacter:
					return Type.ALTERNATION;
				case beginParameterCharacter:
					return Type.BEGIN_PARAMETER;
				case endParameterCharacter:
					return Type.END_PARAMETER;
				case beginOptionalCharacter:
					return Type.BEGIN_OPTIONAL;
				case endOptionalCharacter:
					return Type.END_OPTIONAL;
			}

			return Type.TEXT;
		}

		public static bool isEscapeCharacter(int token)
		{
			return token == escapeCharacter;
		}

		public override string ToString()
		{
			return $"{{\"type\": \"{type}\", \"start\": \"{start}\", \"end\": \"{end}\", \"text\": \"{text}\"}}";
		}

		#region Equality

		protected bool Equals(Token other)
		{
			return text == other.text && type == other.type && start == other.start && end == other.end;
		}

		public override bool Equals(object obj)
		{
			if (ReferenceEquals(null, obj)) return false;
			if (ReferenceEquals(this, obj)) return true;
			if (obj.GetType() != this.GetType()) return false;
			return Equals((Token)obj);
		}

		public override int GetHashCode()
		{
			unchecked
			{
				var hashCode = (text != null ? text.GetHashCode() : 0);
				hashCode = (hashCode * 397) ^ (int)type;
				hashCode = (hashCode * 397) ^ start;
				hashCode = (hashCode * 397) ^ end;
				return hashCode;
			}
		}

		#endregion

		public enum Type
		{
			Unknown,
			START_OF_LINE,
			END_OF_LINE,
			WHITE_SPACE,
			BEGIN_OPTIONAL,
			END_OPTIONAL,
			BEGIN_PARAMETER,
			END_PARAMETER,
			ALTERNATION,
			TEXT
		}
	}
}

public static class AstExtensions
{
    public static string symbol(this Ast.Token.Type tokenType)
    {
        switch (tokenType)
        {
            case Ast.Token.Type.BEGIN_OPTIONAL:
                return Ast.beginOptionalCharacter.ToString();
            case Ast.Token.Type.END_OPTIONAL:
                return Ast.endOptionalCharacter.ToString();
            case Ast.Token.Type.BEGIN_PARAMETER:
                return Ast.beginParameterCharacter.ToString();
            case Ast.Token.Type.END_PARAMETER:
                return Ast.endParameterCharacter.ToString();
            case Ast.Token.Type.ALTERNATION:
                return Ast.alternationCharacter.ToString();
        }

        return null;
    }

    public static string purpose(this Ast.Token.Type tokenType)
	{
		switch (tokenType)
		{
			case Ast.Token.Type.BEGIN_OPTIONAL:
            case Ast.Token.Type.END_OPTIONAL:
				return "optional text";
			case Ast.Token.Type.BEGIN_PARAMETER:
            case Ast.Token.Type.END_PARAMETER:
				return "a parameter";
			case Ast.Token.Type.ALTERNATION:
				return "alternation";
		}

		return null;
	}
}
