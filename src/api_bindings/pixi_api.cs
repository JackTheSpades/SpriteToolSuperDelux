using System;
using System.Runtime.InteropServices;
using System.Text;

namespace PixiCLR
{
    public static unsafe class PixiAPI
    {
        [DllImport("pixi_api", EntryPoint = "pixi_run", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        [return: MarshalAs(UnmanagedType.I4)]
        private static extern int _pixi_run(int argc, IntPtr[] argv);

        [DllImport("pixi_api", EntryPoint = "pixi_api_version", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        [return: MarshalAs(UnmanagedType.I4)]
        private static extern int _api_version();

        [DllImport("pixi_api", EntryPoint = "pixi_check_api_version", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        [return: MarshalAs(UnmanagedType.I4)]
        private static extern int _check_api_version(int edition, int major, int minor);

        [DllImport("pixi_api", EntryPoint = "pixi_parse_json_sprite", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        private static extern IntPtr _pixi_parse_json_sprite(string filename);
        [DllImport("pixi_api", EntryPoint = "pixi_parse_cfg_sprite", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        private static extern IntPtr _pixi_parse_cfg_sprite(string filename);
        [DllImport("pixi_api", EntryPoint = "pixi_sprite_free", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        private static extern void _pixi_sprite_free(IntPtr sprite);
        [DllImport("pixi_api", EntryPoint = "pixi_free_map16_array", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        private static extern void _pixi_free_map16_array(IntPtr* array);
        [DllImport("pixi_api", EntryPoint = "pixi_free_display_array", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        private static extern void _pixi_free_display_array(IntPtr* array);
        [DllImport("pixi_api", EntryPoint = "pixi_free_collection_array", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        private static extern void _pixi_free_collection_array(IntPtr* array);
        [DllImport("pixi_api", EntryPoint = "pixi_free_tile_array", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        private static extern void _pixi_free_tile_array(IntPtr* array);

        // Sprite information APIs
        [DllImport("pixi_api", EntryPoint = "pixi_sprite_line", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        [return: MarshalAs(UnmanagedType.I4)]
        private static extern int _pixi_sprite_line(IntPtr sprite);
        [DllImport("pixi_api", EntryPoint = "pixi_sprite_number", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        [return: MarshalAs(UnmanagedType.I4)]
        private static extern int _pixi_sprite_number(IntPtr sprite);
        [DllImport("pixi_api", EntryPoint = "pixi_sprite_level", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        [return: MarshalAs(UnmanagedType.I4)]
        private static extern int _pixi_sprite_level(IntPtr sprite);
        [DllImport("pixi_api", EntryPoint = "pixi_sprites_sprite_table", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        private static extern IntPtr _pixi_sprites_sprite_table(IntPtr sprite);
        [DllImport("pixi_api", EntryPoint = "pixi_sprite_status_pointers", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        private static extern IntPtr _pixi_sprite_status_pointers(IntPtr sprite);
        [DllImport("pixi_api", EntryPoint = "pixi_extended_cape_ptr", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        private static extern int _pixi_extended_cape_ptr(IntPtr sprite);
        [DllImport("pixi_api", EntryPoint = "pixi_sprite_byte_count", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        [return: MarshalAs(UnmanagedType.I4)]
        private static extern int _pixi_sprite_byte_count(IntPtr sprite);
        [DllImport("pixi_api", EntryPoint = "pixi_sprite_extra_byte_count", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        [return: MarshalAs(UnmanagedType.I4)]
        private static extern int _pixi_sprite_extra_byte_count(IntPtr sprite);
        [DllImport("pixi_api", EntryPoint = "pixi_sprite_directory", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        private static extern sbyte* _pixi_sprite_directory(IntPtr sprite, out int size);
        [DllImport("pixi_api", EntryPoint = "pixi_sprite_asm_file", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        private static extern sbyte* _pixi_sprite_asm_file(IntPtr sprite, out int size);
        [DllImport("pixi_api", EntryPoint = "pixi_sprite_cfg_file", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        private static extern sbyte* _pixi_sprite_cfg_file(IntPtr sprite, out int size);
        [DllImport("pixi_api", EntryPoint = "pixi_sprite_map_data", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        private static extern IntPtr* _pixi_sprite_map_data(IntPtr sprite, out int size);
        [DllImport("pixi_api", EntryPoint = "pixi_sprite_displays", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        private static extern IntPtr* _pixi_sprite_displays(IntPtr sprite, out int size);
        [DllImport("pixi_api", EntryPoint = "pixi_sprite_collections", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        private static extern IntPtr* _pixi_sprite_collections(IntPtr sprite, out int size);
        [DllImport("pixi_api", EntryPoint = "pixi_sprite_type", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        [return: MarshalAs(UnmanagedType.I4)]
        private static extern int _pixi_sprite_type(IntPtr sprite);

        // Tile information APIs
        [DllImport("pixi_api", EntryPoint = "pixi_tile_x_offset", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        [return: MarshalAs(UnmanagedType.I4)]
        private static extern int _pixi_tile_x_offset(IntPtr tile);
        [DllImport("pixi_api", EntryPoint = "pixi_tile_y_offset", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        [return: MarshalAs(UnmanagedType.I4)]
        private static extern int _pixi_tile_y_offset(IntPtr tile);
        [DllImport("pixi_api", EntryPoint = "pixi_tile_tile_number", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        [return: MarshalAs(UnmanagedType.I4)]
        private static extern int _pixi_tile_tile_number(IntPtr tile);
        [DllImport("pixi_api", EntryPoint = "pixi_tile_text", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        private static extern sbyte* _pixi_tile_text(IntPtr tile, out int size);

        // Display information APIs
        [DllImport("pixi_api", EntryPoint = "pixi_display_description", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        private static extern sbyte* _pixi_display_description(IntPtr display, out int size);
        [DllImport("pixi_api", EntryPoint = "pixi_display_tiles", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        private static extern IntPtr* _pixi_display_tiles(IntPtr display, out int size);
        [DllImport("pixi_api", EntryPoint = "pixi_display_extra_bit", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        [return: MarshalAs(UnmanagedType.I4)]
        private static extern int _pixi_display_extra_bit(IntPtr display);
        [DllImport("pixi_api", EntryPoint = "pixi_display_x", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        [return: MarshalAs(UnmanagedType.I4)]
        private static extern int _pixi_display_x(IntPtr display);
        [DllImport("pixi_api", EntryPoint = "pixi_display_y", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        [return: MarshalAs(UnmanagedType.I4)]
        private static extern int _pixi_display_y(IntPtr display);

        // Collection information APIs
        [DllImport("pixi_api", EntryPoint = "pixi_collection_name", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        private static extern sbyte* _pixi_collection_name(IntPtr collection, out int size);
        [DllImport("pixi_api", EntryPoint = "pixi_collection_extra_bit", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        private static extern int _pixi_collection_extra_bit(IntPtr collection);
        [DllImport("pixi_api", EntryPoint = "pixi_collection_prop", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        private static extern byte* _pixi_collection_prop(IntPtr collection, out int size);

        // Map8x8 information APIs
        [DllImport("pixi_api", EntryPoint = "pixi_map8x8_tile", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        [return: MarshalAs(UnmanagedType.I1)]
        private static extern sbyte _pixi_map8x8_tile(IntPtr map8x8);
        [DllImport("pixi_api", EntryPoint = "pixi_map8x8_prop", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        [return: MarshalAs(UnmanagedType.I1)]
        private static extern sbyte _pixi_map8x8_prop(IntPtr map8x8);

        // Map16 information APIs
        [DllImport("pixi_api", EntryPoint = "pixi_map16_top_left", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        private static extern IntPtr _pixi_map16_top_left(IntPtr map16);
        [DllImport("pixi_api", EntryPoint = "pixi_map16_bottom_left", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        private static extern IntPtr _pixi_map16_bottom_left(IntPtr map16);
        [DllImport("pixi_api", EntryPoint = "pixi_map16_top_right", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        private static extern IntPtr _pixi_map16_top_right(IntPtr map16);
        [DllImport("pixi_api", EntryPoint = "pixi_map16_bottom_right", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        private static extern IntPtr _pixi_map16_bottom_right(IntPtr map16);

        // Status pointers information APIs
        [DllImport("pixi_api", EntryPoint = "pixi_status_pointers_carriable", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        [return: MarshalAs(UnmanagedType.I4)]
        private static extern int _pixi_status_pointers_carriable(IntPtr status_pointers);
        [DllImport("pixi_api", EntryPoint = "pixi_status_pointers_kicked", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        [return: MarshalAs(UnmanagedType.I4)]
        private static extern int _pixi_status_pointers_kicked(IntPtr status_pointers);
        [DllImport("pixi_api", EntryPoint = "pixi_status_pointers_carried", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        [return: MarshalAs(UnmanagedType.I4)]
        private static extern int _pixi_status_pointers_carried(IntPtr status_pointers);
        [DllImport("pixi_api", EntryPoint = "pixi_status_pointers_mouth", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        [return: MarshalAs(UnmanagedType.I4)]
        private static extern int _pixi_status_pointers_mouth(IntPtr status_pointers);
        [DllImport("pixi_api", EntryPoint = "pixi_status_pointers_goal", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        [return: MarshalAs(UnmanagedType.I4)]
        private static extern int _pixi_status_pointers_goal(IntPtr status_pointers);

        // Sprite table information APIs
        [DllImport("pixi_api", EntryPoint = "pixi_sprite_table_type", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        [return: MarshalAs(UnmanagedType.U1)]
        private static extern byte _pixi_sprite_table_type(IntPtr sprite_table);
        [DllImport("pixi_api", EntryPoint = "pixi_sprite_table_actlike", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        [return: MarshalAs(UnmanagedType.U1)]
        private static extern byte _pixi_sprite_table_actlike(IntPtr sprite_table);
        [DllImport("pixi_api", EntryPoint = "pixi_sprite_table_tweak", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        private static extern byte* _pixi_sprite_table_tweak(IntPtr sprite_table, out int size);
        [DllImport("pixi_api", EntryPoint = "pixi_sprite_table_init", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        [return: MarshalAs(UnmanagedType.I4)]
        private static extern int _pixi_sprite_table_init(IntPtr sprite_table);
        [DllImport("pixi_api", EntryPoint = "pixi_sprite_table_main", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        [return: MarshalAs(UnmanagedType.I4)]
        private static extern int _pixi_sprite_table_main(IntPtr sprite_table);
        [DllImport("pixi_api", EntryPoint = "pixi_sprite_table_extra", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.Cdecl)]
        private static extern byte* _pixi_sprite_table_extra(IntPtr sprite_table, out int size);

        public abstract class PointerInternalBase : IDisposable
        {
            protected readonly IntPtr data_pointer;
            protected bool disposedValue;

            protected PointerInternalBase(IntPtr ptr)
            {
                data_pointer = ptr;
            }

            protected virtual void Dispose(bool disposing)
            {
                // Do nothing as base case, subclasses will override and do things if necessary
            }
            ~PointerInternalBase()
            {
                Dispose(disposing: false);
            }

            public void Dispose()
            {
                Dispose(disposing: true);
                GC.SuppressFinalize(this);
            }
        }

        public class SpriteTable : PointerInternalBase
        {
            public SpriteTable(IntPtr data_pointer) : base(data_pointer)
            {
            }

            public byte Type()
            {
                return _pixi_sprite_table_type(data_pointer);
            }
            public byte ActLike()
            {
                return _pixi_sprite_table_actlike(data_pointer);
            }
            public byte[] Tweak()
            {
                var carr = _pixi_sprite_table_tweak(data_pointer, out int size);
                byte[] ret = new byte[size];
                for (int i = 0; i < size; i++)
                    ret[i] = carr[i];
                return ret;
            }
            public int Init()
            {
                return _pixi_sprite_table_init(data_pointer);
            }
            public int Main()
            {
                return _pixi_sprite_table_main(data_pointer);
            }
            public byte[] Extra()
            {
                var carr = _pixi_sprite_table_extra(data_pointer, out int size);
                byte[] ret = new byte[size];
                for (int i = 0; i < size; i++)
                    ret[i] = carr[i];
                return ret;
            }
        }

        public class StatusPointers : PointerInternalBase
        {
            public StatusPointers(IntPtr data_pointer) : base(data_pointer)
            {
            }
            public int Carriable()
            {
                return _pixi_status_pointers_carriable(data_pointer);
            }
            public int Kicked()
            {
                return _pixi_status_pointers_kicked(data_pointer);
            }
            public int Carried()
            {
                return _pixi_status_pointers_carried(data_pointer);
            }
            public int Mouth()
            {
                return _pixi_status_pointers_mouth(data_pointer);
            }
            public int Goal()
            {
                return _pixi_status_pointers_goal(data_pointer);
            }
        }

        public class Tile : PointerInternalBase
        {
            public Tile(IntPtr data_pointer) : base(data_pointer)
            {
            }
            public int XOffset()
            {
                return _pixi_tile_x_offset(data_pointer);
            }
            public int YOffset()
            {
                return _pixi_tile_y_offset(data_pointer);
            }
            public int TileNumber()
            {
                return _pixi_tile_tile_number(data_pointer);
            }
            public string Text()
            {
                var cstr = _pixi_tile_text(data_pointer, out int size);
                string str = new(cstr, 0, size, Encoding.ASCII);
                return str;
            }
        }

        public class Display : PointerInternalBase
        {
            public Display(IntPtr data_pointer) : base(data_pointer)
            {
            }
            public string Description()
            {
                var cstr = _pixi_display_description(data_pointer, out int size);
                string str = new(cstr, 0, size, Encoding.ASCII);
                return str;
            }
            public Tile[] Tiles()
            {
                var carr = _pixi_display_tiles(data_pointer, out int size);
                Tile[] tiles = new Tile[size];
                for (int i = 0; i < size; i++)
                    tiles[i] = new Tile(carr[i]);
                _pixi_free_tile_array(carr);
                return tiles;
            }
            public int ExtraBit()
            {
                return _pixi_display_extra_bit(data_pointer);
            }
            public int X()
            {
                return _pixi_display_x(data_pointer);
            }
            public int Y()
            {
                return _pixi_display_y(data_pointer);
            }
        }

        public class Collection : PointerInternalBase
        {
            public Collection(IntPtr data_pointer) : base(data_pointer)
            {
            }
            public string Name()
            {
                var cstr = _pixi_collection_name(data_pointer, out int size);
                return new string(cstr, 0, size, Encoding.ASCII);
            }
            public int ExtraBit()
            {
                return _pixi_collection_extra_bit(data_pointer);
            }
            public byte[] Prop()
            {
                var carr = _pixi_collection_prop(data_pointer, out int size);
                byte[] ret = new byte[size];
                for (int i = 0; i < size; i++)
                    ret[i] = carr[i];
                return ret;
            }
        }

        public class Map8x8 : PointerInternalBase
        {
            public Map8x8(IntPtr data_pointer) : base(data_pointer)
            {
            }
            public int Tile()
            {
                return _pixi_map8x8_tile(data_pointer);
            }
            public int Prop()
            {
                return _pixi_map8x8_prop(data_pointer);
            }
        }

        public class Map16 : PointerInternalBase
        {
            public Map16(IntPtr data_pointer) : base(data_pointer)
            {
            }
            public Map8x8 TopLeft()
            {
                return new Map8x8(_pixi_map16_top_left(data_pointer));
            }
            public Map8x8 BottomLeft()
            {
                return new Map8x8(_pixi_map16_bottom_left(data_pointer));
            }
            public Map8x8 TopRight()
            {
                return new Map8x8(_pixi_map16_top_right(data_pointer));

            }
            public Map8x8 BottomRight()
            {
                return new Map8x8(_pixi_map16_bottom_right(data_pointer));
            }
        }

        public class Sprite : PointerInternalBase
        {
            public Sprite(IntPtr sprite_pointer) : base(sprite_pointer)
            {
            }

            protected override void Dispose(bool disposing)
            {
                if (!disposedValue)
                {
                    if (disposing)
                    {
                    }
                    _pixi_sprite_free(data_pointer);
                    disposedValue = true;
                }
            }

            public static Sprite FromJson(string filename)
            {
                IntPtr intPtr = _pixi_parse_json_sprite(filename);
                Sprite sprite = new(intPtr);
                return sprite;
            }
            public static Sprite FromCFG(string filename)
            {
                IntPtr intPtr = _pixi_parse_cfg_sprite(filename);
                Sprite sprite = new(intPtr);
                return sprite;
            }

            public int Line()
            {
                return _pixi_sprite_line(data_pointer);
            }
            public int Number()
            {
                return _pixi_sprite_number(data_pointer);
            }
            public int Level()
            {
                return _pixi_sprite_level(data_pointer);
            }
            public SpriteTable SpriteTable()
            {
                return new SpriteTable(_pixi_sprites_sprite_table(data_pointer));
            }
            public StatusPointers StatusPointers()
            {
                return new StatusPointers(_pixi_sprite_status_pointers(data_pointer));
            }
            public int ExtendedCapePtr()
            {
                return _pixi_extended_cape_ptr(data_pointer);
            }
            public int ByteCount()
            {
                return _pixi_sprite_byte_count(data_pointer);
            }
            public int ExtraByteCount()
            {
                return _pixi_sprite_extra_byte_count(data_pointer);
            }
            public string Directory()
            {
                var cstr = _pixi_sprite_directory(data_pointer, out int size);
                string str = new(cstr, 0, size, Encoding.ASCII);
                return str;
            }
            public string AsmFile()
            {
                var cstr = _pixi_sprite_asm_file(data_pointer, out int size);
                string str = new(cstr, 0, size, Encoding.ASCII);
                return str;
            }
            public string CfgFile()
            {
                var cstr = _pixi_sprite_cfg_file(data_pointer, out int size);
                string str = new(cstr, 0, size, Encoding.ASCII);
                return str;
            }
            public Map16[] MapData()
            {
                var carr = _pixi_sprite_map_data(data_pointer, out int size);
                Map16[] map = new Map16[size];
                for (int i = 0; i < size; i++)
                    map[i] = new Map16(carr[i]);
                _pixi_free_map16_array(carr);
                return map;
            }
            public Display[] Displays()
            {
                var carr = _pixi_sprite_displays(data_pointer, out int size);
                Display[] map = new Display[size];
                for (int i = 0; i < size; i++)
                    map[i] = new Display(carr[i]);
                _pixi_free_display_array(carr);
                return map;
            }
            public Collection[] Collections()
            {
                var carr = _pixi_sprite_collections(data_pointer, out int size);
                Collection[] map = new Collection[size];
                for (int i = 0; i < size; i++)
                    map[i] = new Collection(carr[i]);
                _pixi_free_collection_array(carr);
                return map;
            }
            public int Type()
            {
                return _pixi_sprite_type(data_pointer);
            }
        }

        /// <summary>
        /// Runs Pixi with the specified arguments
        /// stdin and stdout are optional parameters that will override the input and output of the program
        /// If not passed they will default to the normal stdin/stdout
        /// </summary>
        /// <param name="argv">Arguments</param>
        /// <returns>Exit code of the Pixi run</returns>
        public static int Run(string[] argv)
        {
            // this code is absolutely HORRIFIC but it's the only way I found to make this work
            // if anyone has better idea, PLEASE help.
            byte[] zerobyte = new byte[] { 0 };
            IntPtr[] argv_cpp = new IntPtr[argv.Length];
            for (int i = 0; i < argv.Length; i++)
            {
                byte[] buffer = Encoding.ASCII.GetBytes(argv[i]);
                IntPtr memory = Marshal.AllocHGlobal(buffer.Length + 1);
                Marshal.Copy(buffer, 0, memory, buffer.Length);
                Marshal.Copy(zerobyte, 0, memory + buffer.Length, 1);
                argv_cpp[i] = memory;
            }
            int ret_val = _pixi_run(argv.Length, argv_cpp);

            foreach (var ptr in argv_cpp)
                Marshal.FreeHGlobal(ptr);
            return ret_val;
        }

        /// <summary>
        /// Returns the API version that the pixi dll is currently using
        /// </summary>
        /// <returns>Full API version in the format EDITION*100+MAJOR*10+MINOR</returns>
        public static int ApiVersion()
        {
            return _api_version();
        }

        /// <summary>
        /// Checks if the version passed in equals the current version present in the DLL.
        /// </summary>
        /// <param name="edition">Edition</param>
        /// <param name="major">Major</param>
        /// <param name="minor">Minor</param>
        /// <returns>True if matching, False otherwise</returns>
        public static bool CheckApiVersion(int edition, int major, int minor)
        {
            return _check_api_version(edition, major, minor) == 1;
        }
    }
}