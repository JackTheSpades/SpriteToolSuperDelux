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
	public class CFGFile : INotifyPropertyChanged
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

        #endregion
        
        public const byte Version = 0;
        public byte[] ToByteArray()
        {
            List<byte> bytes = new List<byte>()
            {
                (byte)'C', (byte)'F', (byte)'G', (byte)'B',
                Version,
                Type,
                ActLike,
                Addr1656, Addr1662, Addr166E, Addr167A, Addr1686, Addr190F
            };

            if(Type != 0)
            {
                bytes.Add(ExProp1);
                bytes.Add(ExProp2);

                bytes.AddRange(Encoding.ASCII.GetBytes(AsmFile));
                bytes.Add(0);
            }

            return bytes.ToArray();
        }

        public void FromByteArray(byte[] array)
        {
            if (array[0] != 'C' || array[1] != 'F' || array[2] != 'G' || array[3] != 'B')
                throw new ArgumentException("Magic number is not matching", nameof(array));
            if(array[4] > Version)
                throw new ArgumentException("Version of file is higher than tool version", nameof(array));

            Type = array[5];
            ActLike = array[6];

            Addr1656 = array[7];
            Addr1662 = array[8];
            Addr166E = array[9];
            Addr167A = array[10];
            Addr1686 = array[11];
            Addr190F = array[12];

            if(Type != 0)
            {
                ExProp1 = array[13];
                ExProp2 = array[14];

                int endIndex = Array.IndexOf(array, 0, 15);
                AsmFile = Encoding.ASCII.GetString(array, 15, endIndex - 15);
            }
        }

        public void FromLines(string text)
        {
            string[] lines = text.Split("\r\n".ToCharArray(), StringSplitOptions.RemoveEmptyEntries);

            Type = BytesFromStringLine(lines[0])[0];
            ActLike = BytesFromStringLine(lines[1])[0];

            byte[] tweaker = BytesFromStringLine(lines[2]);
            Addr1656 = tweaker[0];
            Addr1662 = tweaker[1];
            Addr166E = tweaker[2];
            Addr167A = tweaker[3];
            Addr1686 = tweaker[4];
            Addr190F = tweaker[5];
            
            TrySet(lines, 3, str =>
            {
                byte[] extraporp = BytesFromStringLine(str);
                ExProp1 = extraporp[0];
                ExProp2 = extraporp[1];
            }, () => { ExProp1 = ExProp2 = 0; });
            TrySet(lines, 4, str => AsmFile = str, () => AsmFile = "");
            TrySet(lines, 5, str =>
            {
                byte[] count = BytesFromStringLine(lines[5], ':');
                ByteCount = count[0];
                ExByteCount = count[1];
            }, () => { ByteCount = ExByteCount = 0; });
        }

        private byte[] BytesFromStringLine(string line, char split = ' ')
        {
            string[] vals = line.Split(split);
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
                return sb.ToString();

            sb.AppendLine(string.Format("{0:X2} {1:X2}", ExProp1, ExProp2));
            sb.AppendLine(AsmFile);
            sb.AppendLine(string.Format("{0:X2}:{1:X2}", ByteCount, ExByteCount));
            return sb.ToString();
        }
        
		protected void SetPropertyValue<T>(ref T priv, T val, [CallerMemberName] string caller = "")
		{
			bool pn = ReferenceEquals(priv, null);
			bool vn = ReferenceEquals(val, null);

			if (pn && vn)
				return;
			if ((pn && !vn) || !priv.Equals(val))
			{
				priv = val;
                PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(caller));
            }
		}

	}




	public static class ControlExtension
	{
		public static Binding BitsBind<TCon, TObj, TOProp>(
			this TCon control,
			TObj obj,
			Expression<Func<TCon, int>> controlProperty,
			Expression<Func<TObj, TOProp>> objectProperty,
			int bitsToGet = 1,
			int lsb = 0
			)
			where TCon : IBindableComponent
		{

			//TOProp is expected to be a number type, like byte, int, long, etz.

			Func<TOProp, int> castToControl = prop =>
			{
				ulong val = Convert.ToUInt64(prop);
				
				ulong and = (1ul << bitsToGet) - 1;
				return (int)((val & (and << lsb)) >> lsb);
			};

			Binding binding = control.Bind(obj, controlProperty, objectProperty, castToControl, null);

			binding.Parse += (o, e) =>
			{
				Binding b = (Binding)o;

				Type tObj = b.DataSource.GetType();
				string member = b.BindingMemberInfo.BindingMember;
				PropertyInfo pi = tObj.GetProperty(member);
				if (pi == null)
					return;
				ulong val = Convert.ToUInt64(pi.GetValue(b.DataSource));


				for (int i = 0; i < bitsToGet && i < 8; i++)
					val = val.SetBit(lsb + i, (((int)e.Value) & (0x01 << i)) != 0);

				e.Value = val;
			};
			return binding;
		}

		private static ulong SetBit(this ulong b, int bit, bool set)
		{
			if (set)
				return (b | (1ul << bit));
			return (b & ((1ul << bit) ^ ulong.MaxValue));
		}

		public static Binding BitBind<TCon, TObj, TOProp>(
			this TCon control,
			TObj obj,
			Expression<Func<TCon, bool>> controlProperty,
			Expression<Func<TObj, TOProp>> objectProperty,
			int bit = 0
			)
			where TCon : IBindableComponent
		{

			//TOProp is expected to be a number type, like byte, int, long, etz.

			Func<TOProp, bool> castToControl = prop =>
				{
					ulong val = Convert.ToUInt64(prop);
					return (val & (1ul << bit)) != 0;
				};
			
			Binding binding = control.Bind(obj, controlProperty, objectProperty, castToControl, null);

			binding.Parse += (o, e) =>
				{
					Binding b = (Binding)o;

					Type tObj = b.DataSource.GetType();
					string member = b.BindingMemberInfo.BindingMember;
					PropertyInfo pi = tObj.GetProperty(member);
					if (pi == null)
						return;

					ulong val = Convert.ToUInt64(pi.GetValue(b.DataSource));

					if ((bool)e.Value)
						val |= (1ul << bit);
					else
						val &= ((1ul << bit) ^ ulong.MaxValue);
					e.Value = val;
				};
			return binding;
		}


		/// <summary>
		/// Adds a binding to the Control using Expressions instead of constant strings and allows for
		/// optional parsing events to be added.
		/// </summary>
		/// <typeparam name="TCon">Type of the Control we want to bind to.</typeparam>
		/// <typeparam name="TCProp">Type of the Property of the Control we want to bind to.</typeparam>
		/// <typeparam name="TObj">Type of the object we want to bind to.</typeparam>
		/// <typeparam name="TOProp">Type of the property of the object we want to bind to.</typeparam>
		/// <param name="control">The control we bind to.</param>
		/// <param name="list">The list of object we want to bind to.</param>
		/// <param name="controlProperty">Lambda expression for the property of the Control</param>
		/// <param name="objectProperty">Lambdge expression for the property of the Object</param>
		/// <param name="castToControl">Otional casting method for values parsed into the control.</param>
		/// <param name="castToSource">Optional casting method for values coming from the contol.</param>
		/// <returns>The created Binding</returns>
		public static Binding BindList<TCon, TCProp, TObj, TOProp>
			(
			this TCon control,
			IEnumerable<TObj> list,
			Expression<Func<TCon, TCProp>> controlProperty,
			Expression<Func<TObj, TOProp>> objectProperty,
			Func<object, TCProp> castToControl = null,
			Func<object, TOProp> castToSource = null
			)
			where TCon : Control
		{
			string controlProp = "";
			if (controlProperty.Body as MemberExpression != null)
				controlProp = getName((MemberExpression)controlProperty.Body);

			string objectProp = "";
			if (objectProperty.Body as MemberExpression != null)
				objectProp = getName((MemberExpression)objectProperty.Body);

			Binding bind = new Binding(controlProp, list, objectProp);

			if (castToControl != null)
				bind.Format += (_, e) => e.Value = castToControl(e.Value);
			if (castToSource != null)
				bind.Parse += (_, e) => e.Value = castToSource(e.Value);

			control.DataBindings.Add(bind);
			return bind;
		}

		/// <summary>
		/// Adds a binding to the Control using Expressions instead of constant strings and allows for
		/// optional parsing events to be added.
		/// </summary>
		/// <typeparam name="TCon">Type of the Control we want to bind to.</typeparam>
		/// <typeparam name="TCProp">Type of the Property of the Control we want to bind to.</typeparam>
		/// <typeparam name="TObj">Type of the object we want to bind to.</typeparam>
		/// <typeparam name="TOProp">Type of the property of the object we want to bind to.</typeparam>
		/// <param name="control">The control we bind to.</param>
		/// <param name="obj">The object we want to bind to.</param>
		/// <param name="controlProperty">Lambda expression for the property of the Control</param>
		/// <param name="objectProperty">Lambdge expression for the property of the Object</param>
		/// <param name="castToControl">Otional casting method for values parsed into the control.</param>
		/// <param name="castToSource">Optional casting method for values coming from the contol.</param>
		/// <returns>The created Binding</returns>
		public static Binding Bind<TCon, TCProp, TObj, TOProp>(
			this TCon control,
			TObj obj,
			Expression<Func<TCon, TCProp>> controlProperty,
			Expression<Func<TObj, TOProp>> objectProperty,
			Func<TOProp, TCProp> castToControl = null,
			Func<TCProp, TOProp> castToSource = null
			)
			where TCon : IBindableComponent
		{
			string controlProp = "";
			if (controlProperty.Body as MemberExpression != null)
				controlProp = getName((MemberExpression)controlProperty.Body);

			string objectProp = "";
			if (objectProperty.Body as MemberExpression != null)
				objectProp = getName((MemberExpression)objectProperty.Body);

			Binding bind = new Binding(controlProp, obj, objectProp);

			if (castToControl != null)
				bind.Format += (_, e) => e.Value = castToControl((TOProp)e.Value);
			if (castToSource != null)
				bind.Parse += (_, e) => e.Value = castToSource((TCProp)e.Value);

			control.DataBindings.Add(bind);

			return bind;
		}


		private static string getName(MemberExpression mem)
		{
			string parent = "";
			if (mem.Expression as MemberExpression != null)
			{
				parent = getName((MemberExpression)mem.Expression) + ".";
			}
			return parent + mem.Member.Name;
		}
	}
}
