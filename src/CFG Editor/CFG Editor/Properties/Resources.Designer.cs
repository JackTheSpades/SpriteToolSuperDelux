﻿//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated by a tool.
//     Runtime Version:4.0.30319.42000
//
//     Changes to this file may cause incorrect behavior and will be lost if
//     the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

namespace CFG.Properties {
    using System;
    
    
    /// <summary>
    ///   A strongly-typed resource class, for looking up localized strings, etc.
    /// </summary>
    // This class was auto-generated by the StronglyTypedResourceBuilder
    // class via a tool like ResGen or Visual Studio.
    // To add or remove a member, edit your .ResX file then rerun ResGen
    // with the /str option, or rebuild your VS project.
    [global::System.CodeDom.Compiler.GeneratedCodeAttribute("System.Resources.Tools.StronglyTypedResourceBuilder", "17.0.0.0")]
    [global::System.Diagnostics.DebuggerNonUserCodeAttribute()]
    [global::System.Runtime.CompilerServices.CompilerGeneratedAttribute()]
    internal class Resources {
        
        private static global::System.Resources.ResourceManager resourceMan;
        
        private static global::System.Globalization.CultureInfo resourceCulture;
        
        [global::System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("Microsoft.Performance", "CA1811:AvoidUncalledPrivateCode")]
        internal Resources() {
        }
        
        /// <summary>
        ///   Returns the cached ResourceManager instance used by this class.
        /// </summary>
        [global::System.ComponentModel.EditorBrowsableAttribute(global::System.ComponentModel.EditorBrowsableState.Advanced)]
        internal static global::System.Resources.ResourceManager ResourceManager {
            get {
                if (object.ReferenceEquals(resourceMan, null)) {
                    global::System.Resources.ResourceManager temp = new global::System.Resources.ResourceManager("CFG.Properties.Resources", typeof(Resources).Assembly);
                    resourceMan = temp;
                }
                return resourceMan;
            }
        }
        
        /// <summary>
        ///   Overrides the current thread's CurrentUICulture property for all
        ///   resource lookups using this strongly typed resource class.
        /// </summary>
        [global::System.ComponentModel.EditorBrowsableAttribute(global::System.ComponentModel.EditorBrowsableState.Advanced)]
        internal static global::System.Globalization.CultureInfo Culture {
            get {
                return resourceCulture;
            }
            set {
                resourceCulture = value;
            }
        }
        
        /// <summary>
        ///   Looks up a localized resource of type System.Drawing.Bitmap.
        /// </summary>
        internal static System.Drawing.Bitmap Letters {
            get {
                object obj = ResourceManager.GetObject("Letters", resourceCulture);
                return ((System.Drawing.Bitmap)(obj));
            }
        }
        
        /// <summary>
        ///   Looks up a localized resource of type System.Byte[].
        /// </summary>
        internal static byte[] m16Page1_3 {
            get {
                object obj = ResourceManager.GetObject("m16Page1_3", resourceCulture);
                return ((byte[])(obj));
            }
        }
        
        /// <summary>
        ///   Looks up a localized string similar to 00 Green Koopa, no shell
        ///01 Red Koopa, no shell
        ///02 Blue Koopa, no shell
        ///03 Yellow Koopa, no shell
        ///04 Green Koopa
        ///05 Red Koopa
        ///06 Blue Koopa
        ///07 Yellow Koopa
        ///08 Green Koopa, flying left
        ///09 Green bouncing Koopa (Y&amp;1)
        ///0A Red vertical flying Koopa
        ///0B Red horizontal flying Koopa
        ///0C Yellow Koopa with wings
        ///0D Bob-omb
        ///0E Keyhole
        ///0F Goomba
        ///10 Bouncing Goomba with wings
        ///11 Buzzy Beetle
        ///12 Unused
        ///13 Spiny
        ///14 Spiny falling
        ///15 Fish, horizontal
        ///16 Fish, vertical
        ///17 Fish, created from generator
        ///18  [rest of string was truncated]&quot;;.
        /// </summary>
        internal static string SpriteList {
            get {
                return ResourceManager.GetString("SpriteList", resourceCulture);
            }
        }
        
        /// <summary>
        ///   Looks up a localized resource of type System.Byte[].
        /// </summary>
        internal static byte[] sprites_palettes {
            get {
                object obj = ResourceManager.GetObject("sprites_palettes", resourceCulture);
                return ((byte[])(obj));
            }
        }
    }
}
