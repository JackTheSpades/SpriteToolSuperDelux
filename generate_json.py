import re
import os
import json

def read_data():
    with open('tweak_bit_names.json','r') as f:
        return json.loads(f.read())

data = read_data()

cs_filename = 'JsonConst.cs'
cpp_filename = 'json_const.h'

def make_var_name(desc: str) -> str:
    desc = re.sub(r'\s+', '_', desc)
    desc = re.sub(r'[^\w]', '', desc)
    var_name: str = desc.title()
    return var_name.replace('_', '')

def make_cpp_func_name(ram_addr: str) -> str:
    return ram_addr.replace('$', 'j').lower()

def make_cs_class_name(ram_addr: str) -> str:
    return ram_addr.replace('$', 'Value')

cpp_prelude = "#include <nlohmann/json.hpp>\n"

cs_prelude = "using Newtonsoft.Json;\n\n"

cpp_func_proto = """
auto {}(const nlohmann::json& j) {{
    unsigned char c = 0;
    auto& byte = j["{}"];
{}
    return c;
}}
"""

cs_class_proto = """
    public class {} : ByteRepresentant 
    {{
{}
    }}
"""

def construct_cpp_func(address: str, values: list[str]) -> str:
    num_val = len(values)
    if num_val == 8:
        cpp_func_body = '\n'.join([f'    c |= (byte["{v}"] ? 0x{0x01 << i:02X} : 0);' for i, v in enumerate(values)])
    else:
        diff = 8 - num_val
        if address == "$166E":
            first_val = values[0]
            palette_val = values[1]
            cpp_func_body = f'    c |= (byte["{first_val}"] ? 0x01 : 0);\n'
            cpp_func_body += f'    c |= (((int)byte["{palette_val}"] & 0x07) << 1);\n'
            diff += 1
            cut = 2
        else:
            first_val = values[0]
            cpp_func_body = f'    c |= (((int)byte["{first_val}"] & 0x{(0x01 << (diff + 1)) - 1:02X}) << 0);\n'
            cut = 1
        cpp_func_body += '\n'.join([f'    c |= (byte["{v}"] ? 0x{0x01 << (i + diff + 1):02X} : 0);' for i, v in enumerate(values[cut:])])
    return str.format(cpp_func_proto, make_cpp_func_name(address), address, cpp_func_body)

def construct_cs_class(address: str, values: list[str]) -> str:
    num_val = len(values)
    if num_val == 8:
        cs_func_body = '\n'.join([f'        [JsonProperty(Order = {i}, PropertyName = "{v}")]\n        public bool {make_var_name(v)} {{ get; set; }}' for i, v in enumerate(values)])
    else:
        diff = 8 - num_val
        if address == "$166E":
            first_val = values[0]
            palette_val = values[1]
            cs_func_body = f'        [JsonProperty(Order = 0, PropertyName = "{first_val}")]\n        public bool {make_var_name(first_val)} {{ get; set; }}\n'
            cs_func_body += f'        [JsonProperty(Order = 1, PropertyName = "{palette_val}")]\n        [JsonIntProperty(Size = {diff + 1})]\n        public int {make_var_name(palette_val)} {{ get; set; }}\n'
            diff += 1
            cut = 2
        else:
            first_val = values[0]
            cs_func_body = f'        [JsonProperty(Order = 0, PropertyName = "{first_val}")]\n        [JsonIntProperty(Size = {diff + 1})]\n        public int {make_var_name(first_val)} {{ get; set; }}\n'
            cut = 1
        cs_func_body += '\n'.join([f'        [JsonProperty(Order = {i + diff + 1}, PropertyName = "{v}")]\n        public bool {make_var_name(v)} {{ get; set; }}' for i, v in enumerate(values[cut:])])
    return str.format(cs_class_proto, make_cs_class_name(address), cs_func_body)

def construct_cpp_file():
    with open(cpp_filename, 'w') as f:
        f.write(cpp_prelude)
        f.writelines([construct_cpp_func(addr, vals) for addr, vals in data.items()])

def construct_cs_file():
    with open(cs_filename, 'w') as f:
        f.write(cs_prelude)
        f.write('namespace CFG.Json\n{')
        f.writelines([construct_cs_class(addr, vals) for addr, vals in data.items()])
        f.write('}')

def move_files():
    os.replace(cpp_filename, os.path.join('src', cpp_filename))
    os.replace(cs_filename, os.path.join('src', 'CFG Editor', 'CFG Editor', 'Json', cs_filename))

construct_cpp_file()
construct_cs_file()
move_files()