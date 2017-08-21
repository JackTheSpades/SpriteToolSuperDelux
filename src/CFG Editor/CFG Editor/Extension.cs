using System;
using System.Collections;
using System.Collections.Generic;
using System.ComponentModel;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Linq.Expressions;
using System.Reflection;
using System.Runtime.CompilerServices;
using System.Windows.Forms;

namespace CFG
{
    public static class ControlExtension
    {

        public static bool GetBit(this byte b, int bit)
        {
            return (b & (1 << bit)) != 0;
        }
        public static byte SetBit(this byte b, int bit, bool set)
        {
            if (set)
                return (byte)(b | (1 << bit));
            return (byte)(b & ((1 << bit) ^ 0xFF));
        }

        /// <summary>
        /// Sets a number of bits based on an integer value
        /// </summary>
        /// <param name="b">The byte who's bits are to be set</param>
        /// <param name="value">The value the bits should be set to</param>
        /// <param name="bitsToSet">How many bits should be set based on the value</param>
        /// <param name="lsb">Which is the least bit to be affected.</param>
        /// <returns></returns>
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




        public static void ForEach<T>(this IEnumerable<T> list, Action<T> action)
        {
            foreach (T t in list)
                action(t);
        }
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

        public static void SetControllsEnabled(this IEnumerable<Control> controlls, bool enabled)
        {
            foreach (var control in controlls)
                control.Enabled = enabled;
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

        public static string GetName(this Enum en)
        {
            var memInfo = en.GetType().GetMember(en.ToString())[0];
            var attr = memInfo.GetCustomAttribute<DescriptionAttribute>();
            if (attr != null)
                return attr.Description;
            return en.ToString();
        }
    }
}
