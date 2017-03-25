using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Linq.Expressions;
using System.Runtime.CompilerServices;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace CFG
{
	public class CFGFile : INotifyPropertyChanged
	{
		public event PropertyChangedEventHandler PropertyChanged;
			//{0x167A, 3},
			//{0x1686, 4},
			//{0x190F, 5},
			//{0x0001, 6},
			//{0x0002, 7},

		private string _AsmFile;
		/// <summary>
		/// The ASM file to use along with this CFG file.
		/// </summary>
		public string AsmFile
		{
			get { return _AsmFile; }
			set { SetPropertyValue(ref _AsmFile, value); }
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








		protected void SetPropertyValue<T>(ref T priv, T val, [CallerMemberName] string caller = "")
		{
			bool pn = ReferenceEquals(priv, null);
			bool vn = ReferenceEquals(val, null);

			if (pn && vn)
				return;
			if ((pn && !vn) || !priv.Equals(val))
			{
				priv = val;
				if (PropertyChanged != null)
					PropertyChanged(this, new PropertyChangedEventArgs(caller));
			}
		}

	}




	public static class ControlExtension
	{

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

			Func<bool, TOProp> castToSource = cont =>
				{
					return default(TOProp);
				};

			return control.Bind(obj, controlProperty, objectProperty, castToControl, castToSource);
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
