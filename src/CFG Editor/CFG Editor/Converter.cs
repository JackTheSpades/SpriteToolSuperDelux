using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CFG
{
    public static class Converter
    {
        /// <summary>
        /// Takes a name and makes it "presentable" by replacing underlines with space and inserting
        /// a space before each capital letter (except the first one)
        /// </summary>
        /// <param name="name"></param>
        /// <returns></returns>
        private static string FixName(string name)
        {
            StringBuilder sb = new StringBuilder(name);
            sb.Replace('_', ' ');
            for (int i = 1; i < sb.Length; i++)
                if (Char.IsUpper(sb[i]))
                    sb.Insert(i, ' ');
            return sb.ToString();
        }


        public static void Convert(IEnumerable<string> paths)
        {
            CfgFile file = new CfgFile();
            foreach(string path in paths)
            {
                //if path is directoy apply to all cfg files with in.
                if (Directory.Exists(path))
                    Convert(Directory.GetFiles(path, "*.cfg", SearchOption.AllDirectories));

                //if there is no file, skip
                else if (!File.Exists(path))
                    continue;

                string json_path = Path.ChangeExtension(path, "json");
                //skip if json already exits
                if (File.Exists(json_path))
                    continue;

                file.FromLines(File.ReadAllText(path));
                file.CollectionEntries.Add(new CollectionSprite()
                {
                    Name = FixName(Path.GetFileNameWithoutExtension(path))
                });

                File.WriteAllText(json_path, file.ToJson());
            }
        }
    }
}
