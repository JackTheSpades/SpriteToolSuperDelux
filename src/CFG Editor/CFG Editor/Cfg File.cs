using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Linq.Expressions;
using System.Reflection;
using System.Runtime.CompilerServices;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace CFG
{
	public class CfgFile : INotifyPropertyChanged
	{
		public event PropertyChangedEventHandler PropertyChanged;

        #region Properties

        private string _AsmFile;
		public string AsmFile
		{
			get { return _AsmFile; }
			set { SetPropertyValue(ref _AsmFile, value); }
        }
        
        private byte _ActLike;
        public byte ActLike
        {
            get { return _ActLike; }
            set { SetPropertyValue(ref _ActLike, value); }
        }
        private byte _Type;
        public byte Type
        {
            get { return _Type; }
            set { SetPropertyValue(ref _Type, value); }
        }


        private byte _Addr1656;
		public byte Addr1656
		{
			get { return _Addr1656; }
			set { SetPropertyValue(ref _Addr1656, value); }
		}

		private byte _Addr1662;
		public byte Addr1662
		{
			get { return _Addr1662; }
			set { SetPropertyValue(ref _Addr1662, value); }
		}

		private byte _Addr166E;
		public byte Addr166E
		{
			get { return _Addr166E; }
			set { SetPropertyValue(ref _Addr166E, value); }
		}

		private byte _Addr167A;
		public byte Addr167A
		{
			get { return _Addr167A; }
			set { SetPropertyValue(ref _Addr167A, value); }
		}

		private byte _Addr1686;
		public byte Addr1686
		{
			get { return _Addr1686; }
			set { SetPropertyValue(ref _Addr1686, value); }
		}

		private byte _Addr190F;
		public byte Addr190F
		{
			get { return _Addr190F; }
			set { SetPropertyValue(ref _Addr190F, value); }
		}


        private byte _ExProp1;
		public byte ExProp1
		{
			get { return _ExProp1; }
			set { SetPropertyValue(ref _ExProp1, value); }
		}
		private byte _ExProp2;
		public byte ExProp2
		{
			get { return _ExProp2; }
			set { SetPropertyValue(ref _ExProp2, value); }
		}

		private byte _byteCount;
		public byte ByteCount
		{
			get { return _byteCount; }
			set { SetPropertyValue(ref _byteCount, value); }
		}
		private byte _exbyteCount;
		public byte ExByteCount
		{
			get { return _exbyteCount; }
			set { SetPropertyValue(ref _exbyteCount, value); }
		}

        public BindingList<CollectionSprite> CollectionEntries { get; set; } = new BindingList<CollectionSprite>();
        public BindingList<Map16.DisplaySprite> DisplayEntries { get; set; } = new BindingList<Map16.DisplaySprite>();
        public byte[] CustomMap16Data { get; set; } = new byte[0];
        #endregion

        #region ROM Data

        const int rom_1656 = 0x3F46C - 0x200;
        const int rom_1662 = rom_1656 + 201 * 1;
        const int rom_166E = rom_1656 + 201 * 2;
        const int rom_167A = rom_1656 + 201 * 3;
        const int rom_1686 = rom_1656 + 201 * 4;
        const int rom_190F = rom_1656 + 201 * 5;

        public void FromRomBytes(byte[] rom, int spriteNumber)
        {
            if (spriteNumber > 201)
                throw new ArgumentException("Numbers bigger than 201 (0xC9) are not possible", nameof(spriteNumber));

            int header = rom.Length % 0x400;

            Clear();
            Addr1656 = rom[rom_1656 + spriteNumber + header];
            Addr1662 = rom[rom_1662 + spriteNumber + header];
            Addr166E = rom[rom_166E + spriteNumber + header];
            Addr167A = rom[rom_167A + spriteNumber + header];
            Addr1686 = rom[rom_1686 + spriteNumber + header];
            Addr190F = rom[rom_190F + spriteNumber + header];
        }
        public void ToRomBytes(byte[] rom, int spriteNumber)
        {
            if (spriteNumber > 201)
                throw new ArgumentException("Numbers bigger than 201 (0xC9) are not possible", nameof(spriteNumber));

            int header = rom.Length % 0x400;

            rom[rom_1656 + spriteNumber + header] = Addr1656;
            rom[rom_1662 + spriteNumber + header] = Addr1662;
            rom[rom_166E + spriteNumber + header] = Addr166E;
            rom[rom_167A + spriteNumber + header] = Addr167A;
            rom[rom_1686 + spriteNumber + header] = Addr1686;
            rom[rom_190F + spriteNumber + header] = Addr190F;
        }

        #endregion

        public void FromLines(string text)
        {
            Clear();

            int currentLine = 0;

            string[] lines = text.Split("\r\n".ToCharArray(), StringSplitOptions.RemoveEmptyEntries);

            //line 1,2 (type, actlike)
            Type = BytesFromStringLine(lines[currentLine++])[0];
            ActLike = BytesFromStringLine(lines[currentLine++])[0];

            //line 3 (tweak)
            byte[] tweaker = BytesFromStringLine(lines[currentLine++]);
            Addr1656 = tweaker[0];
            Addr1662 = tweaker[1];
            Addr166E = tweaker[2];
            Addr167A = tweaker[3];
            Addr1686 = tweaker[4];
            Addr190F = tweaker[5];
            
            //line 4 (ex prop)
            TrySet(lines, currentLine++, str =>
            {
                byte[] extraporp = BytesFromStringLine(str);
                ExProp1 = extraporp[0];
                ExProp2 = extraporp[1];
            }, () => { ExProp1 = ExProp2 = 0; });

            //line 5 (asm)
            TrySet(lines, currentLine++, str => AsmFile = str, () => AsmFile = "");
            //line 6 (extra byte count)
            TrySet(lines, currentLine++, str =>
            {
                byte[] count = BytesFromStringLine(lines[5], ':');
                ByteCount = Math.Min(count[0], (byte)4);
                ExByteCount = Math.Min(count[1], (byte)4);
            }, () => { ByteCount = ExByteCount = 0; });

            ////line 7 (map16)
            //TrySet(lines, currentLine++, str => CustomMap16Data = BytesFromStringLine(str), () => CustomMap16Data = new byte[0]);

            ////line 8 (display cound)
            //int displayCount = 0;
            //TrySet(lines, currentLine++, str => displayCount = Convert.ToInt32(str), () => displayCount = 0);

            ////line 9+ (display info)
            //Map16.DisplaySprite ds = null;
            //bool brk = false;
            //for (int i = 0; i < displayCount && !brk; i++)
            //{
            //    ds = new Map16.DisplaySprite();
            //    TrySet(lines, currentLine++, str =>
            //    {
            //        Map16.DisplaySprite.FillData(ds, str);
            //    }, () => brk = true);
            //    TrySet(lines, currentLine++, str =>
            //    {
            //        ds.Description = str;
            //    }, () => brk = true);

            //    if (brk) break;
            //    DisplayEntries.Add(ds);
            //}

            ////line 10+ (collection count)
            //int collectionCount = 0;
            //TrySet(lines, currentLine++, str => collectionCount = Convert.ToInt32(str), () => collectionCount = 0);

            ////line 11+ (collection info)
            //brk = false;
            //for (int i = 0; i < collectionCount && !brk; i++)
            //    TrySet(lines, currentLine++, str => CollectionEntries.Add(new CollectionSprite(str)), () => brk = true);
        }

        /// <summary>
        /// Takes a string, splits it at the given character and converts the values as hex to an array of byte
        /// </summary>
        /// <param name="line">The string to be split and converted</param>
        /// <param name="split">The split character</param>
        /// <returns></returns>
        private byte[] BytesFromStringLine(string line, char split = ' ')
        {
            string[] vals = line.Split(new[] { split }, StringSplitOptions.RemoveEmptyEntries);
            return vals.Select(str => Convert.ToByte(str, 16)).ToArray();
        }
        private void TrySet(string[] lines, int index, Action<string> ifAction, Action elseAction)
        {
            try
            {
                if (index < lines.Length)
                    ifAction?.Invoke(lines[index]);
                else
                    elseAction?.Invoke();
            }
            catch
            {
                elseAction?.Invoke();
            }
        }

        public string ToLines()
        {
            StringBuilder sb = new StringBuilder();
            sb.AppendLine(string.Format("{0:X2}", Type));
            sb.AppendLine(string.Format("{0:X2}", ActLike));
            sb.AppendLine(string.Format("{0:X2} {1:X2} {2:X2} {3:X2} {4:X2} {5:X2}",
                Addr1656, Addr1662, Addr166E, Addr167A, Addr1686, Addr190F));

            if (Type == 0)
                return sb.ToString().TrimEnd('\r', '\n');

            sb.AppendLine(string.Format("{0:X2} {1:X2}", ExProp1, ExProp2));
            sb.AppendLine(AsmFile);

            //v1.1
            sb.AppendLine(string.Format("{0:X2}:{1:X2}", ByteCount, ExByteCount));

            ////v1.2
            //sb.AppendLine(string.Join(" ", CustomMap16Data.Select(b => b.ToString("X2"))));

            //sb.AppendLine(DisplayEntries.Count.ToString());
            //foreach (var dis in DisplayEntries)
            //{
            //    sb.AppendLine(dis.GetTileLine());
            //    sb.AppendLine(dis.Description);
            //}

            //sb.AppendLine(CollectionEntries.Count.ToString());
            //foreach (var col in CollectionEntries)
            //    sb.AppendLine(col.ToString());


            return sb.ToString().TrimEnd('\r', '\n');
        }

        /// <summary>
        /// Read the data from a json string.
        /// </summary>
        /// <param name="json">The json string</param>
        public void FromJson(string json)
        {
            var cfgJson = Newtonsoft.Json.JsonConvert.DeserializeObject<CFG.Json.JsonCfgFile>(json);
            cfgJson.FillData(this);
        }
        /// <summary>
        /// Converts the data into an indented json string
        /// </summary>
        /// <returns></returns>
        public string ToJson()
        {
            return Newtonsoft.Json.JsonConvert.SerializeObject(new Json.JsonCfgFile(this), Newtonsoft.Json.Formatting.Indented);
        }

        /// <summary>
        /// Clears all properties and resets them to their default value.
        /// </summary>
        public void Clear()
        {
            //loops over all properties within this class and sets them to their default value.
            var props = GetType().GetProperties();
            foreach(var prop in props)
            {
                //set value types to their default.
                if (prop.PropertyType.IsValueType)
                    prop.SetValue(this, Activator.CreateInstance(prop.PropertyType));
                //set strings to empty (not null)
                else if(prop.PropertyType.Equals(typeof(string)))
                    prop.SetValue(this, "");
            }

            CollectionEntries.Clear();
            DisplayEntries.Clear();
            CustomMap16Data = new byte[0];
        }


        
		protected bool SetPropertyValue<T>(ref T priv, T val, [CallerMemberName] string caller = "")
		{
			bool pn = ReferenceEquals(priv, null);
			bool vn = ReferenceEquals(val, null);

			if (pn && vn)
				return false;
			if ((pn && !vn) || !priv.Equals(val))
			{
				priv = val;
                PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(caller));
                return true;
            }
            return false;
		}

	}



}
