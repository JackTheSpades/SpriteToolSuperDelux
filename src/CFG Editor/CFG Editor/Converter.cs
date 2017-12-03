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
        public static string FixName(string name)
        {
            StringBuilder sb = new StringBuilder(name);

            //capitalize first letter.
            sb[0] = Char.ToUpper(sb[0]);

            for (int i = 1; i < sb.Length; i++)
            {
                //if char is underline, replace it with space and make the next char uppercase.
                if(sb[i] == '_')
                {
                    sb[i] = ' ';
                    if (sb.Length - 1 > i + 1)
                        sb[i + 1] = Char.ToUpper(sb[i + 1]);
                }
                //insert space before every upper character if there isn't one already
                if (Char.IsUpper(sb[i]) && sb[i - 1] != ' ')
                    sb.Insert(i, ' ');
            }
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
