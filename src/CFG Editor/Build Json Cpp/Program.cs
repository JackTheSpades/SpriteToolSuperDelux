using System;
using System.Reflection;

namespace Build_Json_Cpp
{
    class Program
    {
        static void Main(string[] args)
        {
            System.Text.StringBuilder sb = new System.Text.StringBuilder();
            sb.AppendLine("// Tool generated code. See CFG Editor Solution (Build Json Cpp)");

            Type[] types = new[]
            {
                    typeof(CFG.Json.Value1656),
                    typeof(CFG.Json.Value1662),
                    typeof(CFG.Json.Value166E),
                    typeof(CFG.Json.Value167A),
                    typeof(CFG.Json.Value1686),
                    typeof(CFG.Json.Value190F),
                };
            foreach (Type type in types)
            {
                System.Text.StringBuilder sb_sub = new System.Text.StringBuilder();

                string addr = type.Name.Substring(type.Name.Length - 4);
                var props = type.GetProperties();

                sb_sub.AppendFormat("#define J{0}(c, j) {{\\\r\n", addr);

                foreach (var prop in props)
                {
                    var attr = prop.GetCustomAttribute<Newtonsoft.Json.JsonPropertyAttribute>();
                    if (attr == null)
                        continue;

                    int bit = attr.Order;
                    string define = string.Format("J{0}_{1}", addr, bit);
                    sb.AppendFormat("#define {0}\t\"${1}\"][\"{2}\"\r\n", define, addr, attr.PropertyName);

                    if (prop.PropertyType == typeof(bool))
                        sb_sub.AppendFormat("\tc |= (j[{0}] ? 0x{1:X2} : 0);\\\r\n", define, 1 << bit);
                    else if(prop.PropertyType == typeof(int))
                    {
                        var iAttr = prop.GetCustomAttribute<CFG.Json.JsonIntPropertyAttribute>();
                        if (iAttr == null)
                            continue;
                        int and = (int)Math.Pow(2, iAttr.Size) - 1;
                        sb_sub.AppendFormat("\tc |= (((int)j[{0}] & 0x{1:X2}) << {2});\\\r\n", define, and, bit);
                    }
                }
                sb_sub.AppendLine("\t}");
                sb.AppendLine(sb_sub.ToString());
                sb.AppendLine();
            }

            System.IO.File.WriteAllText("json_const.h", sb.ToString());

            string target = @"..\..\..\..\json_const.h";
            if (System.IO.File.Exists(target))
                System.IO.File.Copy("json_const.h", target, true);
        }
    }
    
}
