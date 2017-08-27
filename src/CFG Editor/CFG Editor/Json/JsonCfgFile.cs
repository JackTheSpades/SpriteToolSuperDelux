using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CFG.Json
{
    public class JsonCfgFile
    {
        [JsonProperty(PropertyName = "$1656")]
        public Value1656 Val1656 { get; set; } = new Value1656();
        [JsonProperty(PropertyName = "$1662")]
        public Value1662 Val1662 { get; set; } = new Value1662();
        [JsonProperty(PropertyName = "$166E")]
        public Value166E Val166E { get; set; } = new Value166E();
        [JsonProperty(PropertyName = "$167A")]
        public Value167A Val167A { get; set; } = new Value167A();
        [JsonProperty(PropertyName = "$1686")]
        public Value1686 Val1686 { get; set; } = new Value1686();
        [JsonProperty(PropertyName = "$190F")]
        public Value190F Val190F { get; set; } = new Value190F();
        
        public string AsmFile { get; set; }
        public byte ActLike { get; set; }
        public byte Type { get; set; }

        [JsonProperty("Extra Property Byte 1")]
        public byte ExProp1 { get; set; }
        [JsonProperty("Extra Property Byte 2")]
        public byte ExProp2 { get; set; }
        
        [JsonProperty("Additional Byte Count (extra bit clear)")]
        public byte ByteCount { get; set; }
        [JsonProperty("Additional Byte Count (extra bit set)")]
        public byte ExByteCount { get; set; }

        public byte[] Map16 { get; set; }
        public List<Map16.DisplaySprite> Displays { get; set; }
        public List<CollectionSprite> Collection { get; set; }

        public JsonCfgFile() { }
        public JsonCfgFile(CfgFile cfgFile)
        {
            Val1656.FromByte(cfgFile.Addr1656);
            Val1662.FromByte(cfgFile.Addr1662);
            Val166E.FromByte(cfgFile.Addr166E);
            Val167A.FromByte(cfgFile.Addr167A);
            Val1686.FromByte(cfgFile.Addr1686);
            Val190F.FromByte(cfgFile.Addr190F);

            AsmFile = cfgFile.AsmFile;
            ActLike = cfgFile.ActLike;
            Type = cfgFile.Type;

            ExProp1 = cfgFile.ExProp1;
            ExProp2 = cfgFile.ExProp2;

            ByteCount = cfgFile.ByteCount;
            ExByteCount = cfgFile.ExByteCount;

            Map16 = cfgFile.CustomMap16Data;
            Displays = new List<CFG.Map16.DisplaySprite>(cfgFile.DisplayEntries);
            Collection = new List<CollectionSprite>(cfgFile.CollectionEntries);
        }

        public void FillData(CfgFile cfgFile)
        {
            cfgFile.Addr1656 = Val1656.ToByte();
            cfgFile.Addr1662 = Val1662.ToByte();
            cfgFile.Addr166E = Val166E.ToByte();
            cfgFile.Addr167A = Val167A.ToByte();
            cfgFile.Addr1686 = Val1686.ToByte();
            cfgFile.Addr190F = Val190F.ToByte();

            cfgFile.AsmFile = AsmFile;
            cfgFile.ActLike = ActLike;
            cfgFile.Type = Type;

            cfgFile.ExProp1 = ExProp1;
            cfgFile.ExProp2 = ExProp2;

            cfgFile.ByteCount = ByteCount;
            cfgFile.ExByteCount = ExByteCount;

            cfgFile.CustomMap16Data = Map16;
            cfgFile.DisplayEntries = new System.ComponentModel.BindingList<CFG.Map16.DisplaySprite>(Displays);
            cfgFile.CollectionEntries = new System.ComponentModel.BindingList<CollectionSprite>(Collection);
        }
    }
}
