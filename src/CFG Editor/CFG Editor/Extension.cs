using System;
using System.Collections;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.IO;
using System.Linq.Expressions;
using System.Reflection;
using System.Runtime.CompilerServices;
using System.Runtime.Serialization;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace CFG
{
    public class UserException : Exception
    {
        public MessageBoxButtons Buttons { get; set; } = MessageBoxButtons.OK;
        public MessageBoxIcon Icon { get; set; } = MessageBoxIcon.Error;
        public string Caption { get; set; } = "Error";

        public UserException() { }
        public UserException(string message) : base(message) { }
        public UserException(string message, Exception innerException) : base(message, innerException) { }
        protected UserException(SerializationInfo info, StreamingContext context) : base(info, context) { }

        public UserException(string message, string caption, MessageBoxButtons buttons, MessageBoxIcon icon) : base(message)
        {
            Caption = caption;
            Buttons = buttons;
            Icon = icon;
        }
        public UserException(string message, string caption, MessageBoxButtons buttons, MessageBoxIcon icon, Exception innerException) : base(message, innerException)
        {
            Caption = caption;
            Buttons = buttons;
            Icon = icon;
        }


        public DialogResult Show() => MessageBox.Show(Message, Caption, Buttons, Icon);
    }

    
    /// <summary>
    /// Helper class for diagnosis. Only realls does anything if DEBUG is defined.
    /// </summary>
    public static class Diagnose
    {
        /// <summary>
        /// Restarts the stopwatch.
        /// </summary>
        public static Stopwatch Stopwatch;
        [Conditional("DEBUG")]
        public static void Start()
        {
            if (Stopwatch == null)
                Stopwatch = new Stopwatch();
            Stopwatch.Restart();
        }
        /// <summary>
        /// Prints the elapsed time and the name of the member calling this method.
        /// </summary>
        /// <param name="name">The name to be put before the elsapsed time.</param>
        [Conditional("DEBUG")]
        public static void Time([CallerMemberName]string name = null)
        {
            if (name == null)
                Console.WriteLine(Stopwatch.Elapsed);
            else
                Console.WriteLine(name + ": " + Stopwatch.Elapsed);
        }
    }
    

    public static class Extensions
    {
        
        /// <summary>
        /// Detects if an enumeration contains duplicate entries
        /// </summary>
        /// <typeparam name="T">The type of the list</typeparam>
        /// <param name="elements">The enumertion to check</param>
        /// <param name="comparer">The (optional) comparer to be used in the detection</param>
        /// <returns><c>True</c> if there are no duplicate entries</returns>
        public static bool IsDistinct<T>(this IEnumerable<T> elements, IEqualityComparer<T> comparer = null)
        {
            var set = new HashSet<T>(comparer ?? EqualityComparer<T>.Default);
            foreach(T t in elements)
                if (!set.Add(t))
                    return false;
            return true;
        }

        /// <summary>
        /// Gets the bit of a byte, start counting from the right side with 0.
        /// </summary>
        /// <param name="b">The byte to read from.</param>
        /// <param name="bit">The digit the bit is at. Starts from the right with 0</param>
        /// <returns><c>True</c> if the bit is set.</returns>
        public static bool GetBit(this byte b, int bit)
        {
            if (bit >= sizeof(byte) * 8 || bit < 0)
                throw new ArgumentOutOfRangeException(nameof(bit), bit, "Cannot fetch bit outside of bitrange of value");
            return (b & (1 << bit)) != 0;
        }
        /// <summary>
        /// Sets the bit of a byte and returns the new byte. The value of the byte this is called on remains unaffected
        /// </summary>
        /// <param name="b">The source byte</param>
        /// <param name="bit">The the digit of the bit. Starting from the right with 0</param>
        /// <param name="set">Wether to set or clear the bit</param>
        /// <returns>The new byte.</returns>
        public static byte SetBit(this byte b, int bit, bool set)
        {
            if (bit >= sizeof(byte) * 8 || bit < 0)
                throw new ArgumentOutOfRangeException(nameof(bit), bit, "Cannot set bit outside of bitrange of value");
            if (set)
                return (byte)(b | (1 << bit));
            return (byte)(b & ((1 << bit) ^ 0xFF));
        }

        /// <summary>
        /// Sets a number of bits based on an integer value
        /// </summary>
        /// <param name="b">The byte used as a reference to set the bits</param>
        /// <param name="value">The value the bits should be set to</param>
        /// <param name="bitsToSet">How many bits should be set based on the value</param>
        /// <param name="lsb">Which is the least bit to be affected.</param>
        /// <returns>A new byte with the bits set.</returns>
        public static byte SetBits(this byte b, int value, int bitsToSet, int lsb)
        {
            byte b2 = b;
            for (int i = 0; i < bitsToSet && i < 8; i++)
                b2 = b2.SetBit(lsb + i, (value & (0x01 << i)) != 0);
            return b2;
        }

        /// <summary>
        /// Gets a number of bits from a byte as an integer
        /// </summary>
        /// <param name="b">The byte who's bits should be interpreted</param>
        /// <param name="bitsToGet">How many bits should be get</param>
        /// <param name="lsb">Which is the first bit of the 8 to be fetched.</param>
        /// <returns></returns>
        public static int GetBits(this byte b, int bitsToGet, int lsb)
        {
            int and = (1 << bitsToGet) - 1;
            return (b & (and << lsb)) >> lsb;
        }


        /// <summary>
        /// Itterates over each entry and executes and action with the item.
        /// </summary>
        /// <typeparam name="T">The type of the enumeration</typeparam>
        /// <param name="list">The list to iterate</param>
        /// <param name="action">The action to be execute with each entry passed</param>
        public static void ForEach<T>(this IEnumerable<T> list, Action<T> action)
        {
            foreach (T t in list)
                action(t);
        }
        /// <summary>
        /// Itterates over each entry and executes and action with the item and the index of said item.
        /// </summary>
        /// <typeparam name="T">The type of the enumeration</typeparam>
        /// <param name="list">The list to iterate</param>
        /// <param name="action">The action to be execute with each entry and index passed.</param>
        public static void ForEach<T>(this IEnumerable<T> list, Action<T, int> action)
        {
            int i = 0;
            foreach (T t in list)
                action(t, i++);
        }
        public static TRet GetAll<T, TRet>(this IEnumerable<T> list, Func<T, TRet> get, TRet fallback, IEqualityComparer<TRet> comp = null)
        {
            if (comp == null)
                comp = EqualityComparer<TRet>.Default;

            bool first = true;
            TRet prev = default(TRet);
            foreach(T t in list)
            {
                TRet ret = get(t);
                if(!first && comp.Equals(ret, prev))
                {
                    return fallback;
                }
                prev = ret;
                first = false;
            }
            return prev;
        }
                
        /// <summary>
        /// Sets the background image of a control to a gradient.
        /// </summary>
        /// <param name="control">The PictureBox which's background image should be set</param>
        /// <param name="end">The bottom color of the gradient</param>
        /// <param name="start">The top color of the gradient</param>
        public static void SetBackgroundGradient(this Control control, Color end, Color start)
        {
            Bitmap bm = new Bitmap(control.Width, control.Height);
            using (Graphics g = Graphics.FromImage(bm))
            {
                Rectangle rec = new Rectangle(0, 0, bm.Width, bm.Height);
                using (LinearGradientBrush lgd = new LinearGradientBrush(rec, start, end, 90))
                    g.FillRectangle(lgd, rec);
            }
            control.BackgroundImage = bm;
        }

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
                controlProp = GetName((MemberExpression)controlProperty.Body);

            string objectProp = "";
            if (objectProperty.Body as MemberExpression != null)
                objectProp = GetName((MemberExpression)objectProperty.Body);

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
                controlProp = GetName((MemberExpression)controlProperty.Body);

            string objectProp = "";
            if (objectProperty.Body as MemberExpression != null)
                objectProp = GetName((MemberExpression)objectProperty.Body);

            Binding bind = new Binding(controlProp, obj, objectProp);

            if (castToControl != null)
                bind.Format += (_, e) => e.Value = castToControl((TOProp)e.Value);
            if (castToSource != null)
                bind.Parse += (_, e) => e.Value = castToSource((TCProp)e.Value);
            
            control.DataBindings.Add(bind);

            return bind;
        }


        public static string GetName(this MemberExpression mem)
        {
            string parent = "";
            if (mem.Expression as MemberExpression != null)
            {
                parent = GetName((MemberExpression)mem.Expression) + ".";
            }
            return parent + mem.Member.Name;
        }

        public static string GetName(this Enum en) => en.GetName<DisplayNameAttribute>(a => a.Name);
        public static string GetName<TAttr>(this Enum en, Func<TAttr, string> getName) where TAttr : Attribute
        {
            var memInfo = en.GetType().GetMember(en.ToString())[0];
            var attr = memInfo.GetCustomAttribute<TAttr>();
            if (attr != null)
                return getName(attr);
            return en.ToString();
        }
    }

    [AttributeUsage(AttributeTargets.Field, AllowMultiple = false)]
    public class DisplayNameAttribute : Attribute
    {
        public string Name { get; set; }
        public DisplayNameAttribute(string name)
        {
            Name = name;
        }
    }
}
