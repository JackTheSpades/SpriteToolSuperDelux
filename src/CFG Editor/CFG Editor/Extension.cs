using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq.Expressions;
using System.Reflection;
using System.Windows.Forms;

namespace CFG
{
    public static class ControlExtension
    {
        public static void SetControllsEnabled(this IEnumerable<Control> controlls, bool enabled)
        {
            foreach (var control in controlls)
                control.Enabled = enabled;
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
