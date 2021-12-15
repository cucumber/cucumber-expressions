using System.Linq;
using System.Text;

namespace CucumberExpressions.Ast;

public class Node : ILocated
{

    public NodeType Type { get; }
    public Node[] Nodes { get; }
    public string Token { get; }
    public int Start { get; }
    public int End { get; }

    public Node(NodeType type, int start, int end, string token) :
        this(type, start, end, null, token)
    {
    }

    public Node(NodeType type, int start, int end, Node[] nodes) :
        this(type, start, end, nodes, null)
    {
    }

    private Node(NodeType type, int start, int end, Node[] nodes, string token)
    {
        Type = type;
        Nodes = nodes;
        Token = token;
        Start = start;
        End = end;
    }


    public string Text
    {
        get
        {
            if (Nodes == null)
                return Token;

            return string.Join("", Nodes.Select(n => n.Text));
        }
    }

    public override string ToString()
    {
        return ToString(0).ToString();
    }

    private StringBuilder ToString(int depth)
    {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < depth; i++)
        {
            sb.Append("  ");
        }

        sb.Append("{")
            .Append("\"type\": \"").Append(Type)
            .Append("\", \"start\": ")
            .Append(Start)
            .Append(", \"end\": ")
            .Append(End);

        if (Token != null)
        {
            sb.Append(", \"token\": \"").Append(Token.Replace("\\\\", "\\\\\\\\")).Append("\"");
        }

        if (Nodes != null)
        {
            sb.Append(", \"nodes\": ");
            if (Nodes.Any())
            {
                StringBuilder padding = new StringBuilder();
                for (int i = 0; i < depth; i++)
                {
                    padding.Append("  ");
                }

                sb.Append(
                    "[\n" + string.Join(",\n", Nodes.Select(node => node.ToString(depth + 1)))
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
        return Type == other.Type && 
               (Equals(Nodes, other.Nodes) || 
                Nodes != null && other.Nodes != null && Nodes.SequenceEqual(other.Nodes)) && 
               Token == other.Token && 
               Start == other.Start &&
               End == other.End;
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
            var hashCode = (int)Type;
            hashCode = (hashCode * 397) ^ (Nodes != null ? Nodes.GetHashCode() : 0);
            hashCode = (hashCode * 397) ^ (Token != null ? Token.GetHashCode() : 0);
            hashCode = (hashCode * 397) ^ Start;
            hashCode = (hashCode * 397) ^ End;
            return hashCode;
        }
    }
}