﻿using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CFG.Json
{
    public enum DisplayType
    {
        XY,
        ExtraByte
    }

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

        [JsonProperty(PropertyName = "AsmFile")]
        public string AsmFile { get; set; }
        [JsonProperty(PropertyName = "ActLike")]
        public byte ActLike { get; set; }
        [JsonProperty(PropertyName = "Type")]
        public byte Type { get; set; }

        [JsonProperty("Extra Property Byte 1")]
        public byte ExProp1 { get; set; }
        [JsonProperty("Extra Property Byte 2")]
        public byte ExProp2 { get; set; }

        [JsonProperty("Additional Byte Count (extra bit clear)")]
        public byte ByteCount { get; set; }
        [JsonProperty("Additional Byte Count (extra bit set)")]
        public byte ExByteCount { get; set; }

        [JsonProperty(PropertyName = "Map16")]
        public byte[] Map16 { get; set; }

        [JsonProperty(PropertyName = "Displays")]
        public List<Map16.DisplaySprite> Displays { get; set; }

        [JsonProperty(PropertyName = "Collection")]
        public List<CollectionSprite> Collection { get; set; }

        [JsonProperty(PropertyName = "GFXInfo")]
        public List<Map16.GFXInfo> GFXInfos { get; set; }

        class DisplayTypeConverter : JsonConverter
        {
            public override bool CanConvert(Type objectType)
            {
                return (objectType == typeof(string));
            }

            public override object ReadJson(JsonReader reader, Type objectType, object existingValue, JsonSerializer serializer)
            {
                var token = JToken.Load(reader);
                if (token.Type == JTokenType.String)
                {
                    return token.ToString() == "ExByte" ? DisplayType.ExtraByte : DisplayType.XY;
                }
                return null;
            }

            public override void WriteJson(JsonWriter writer, object value, JsonSerializer serializer)
            {
                serializer.Serialize(writer, (DisplayType)value == DisplayType.ExtraByte ? "ExByte" : "XY");
            }
        }

        [JsonProperty(PropertyName = "DisplayType", Required = Required.Default, Order = 0)]
        [JsonConverter(typeof(DisplayTypeConverter))]
        public DisplayType DisplayType { get; set; } = DisplayType.XY;

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
            Displays = new List<CFG.Map16.DisplaySprite>();
            DisplayType = cfgFile.DispType;
            foreach (var display in cfgFile.DisplayEntries)
            {
                var newDisplay = (CFG.Map16.DisplaySprite)display.Clone();
                bool useText = display.UseText;
                newDisplay.DisplayText = newDisplay.DisplayText.Replace("\n", @"\n");
                newDisplay.UseText = useText;
                newDisplay.disp_type = DisplayType;
                Displays.Add(newDisplay);
            }
            Collection = new List<CollectionSprite>(cfgFile.CollectionEntries);
            GFXInfos = new List<Map16.GFXInfo>(cfgFile.GFXInfos);
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
            cfgFile.DispType = DisplayType;

            cfgFile.CustomMap16Data = Map16;

            cfgFile.DisplayEntries.Clear();
            foreach (var ds in Displays)
            {
                bool useText = ds.UseText;
                ds.DisplayText = ds.DisplayText.Replace(@"\n", "\n");
                ds.UseText = useText;
                ds.disp_type = DisplayType;
                cfgFile.DisplayEntries.Add(ds);
            }

            if (DisplayType == DisplayType.ExtraByte && Displays.Count > 0)
            {
                var first_idx = Displays[0].X_or_index;
                if (!Displays.All(d => d.X_or_index == first_idx))
                {
                    throw new Exception($"The JSON file is invalid. If the sprite's display type is ExByte, all of the displays for that sprite must have the same index.");
                }
            }

            cfgFile.CollectionEntries.Clear();
            foreach (var cs in Collection)
                cfgFile.CollectionEntries.Add(cs);

            cfgFile.GFXInfos.Clear();
            if (GFXInfos != null)
            {
                foreach (var cs in GFXInfos)
                    cfgFile.GFXInfos.Add(cs);
            }
        }
    }
}
