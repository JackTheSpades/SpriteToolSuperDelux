#include "base64.h"
#include "json.hpp"
#include <fstream>  // std::ifstream
#include <iostream> // std::cout


using json = nlohmann::json;

int main() {
    std::ifstream i("venus.json");
    json j;
    i >> j;

    std::cout << j["AsmFile"] << std::endl;
    for (auto it : j["$190F"]) {
        std::cout << "\t" << it << std::endl;
    }

    std::cout << "Number of display entries: " << j["Displays"].size() << std::endl;

    for (auto it = j["Displays"].begin(); it < j["Displays"].end(); it++)
        std::cout << "\t" << (*it)["Description"] << std::endl;

    std::string decoded = base64_decode(j["Map16"]);
    const char *map16Data = decoded.c_str();
    for (int i = 0; i < decoded.size(); i++)
        std::cout << std::hex << ((int)map16Data[i] & 0xFF) << ", ";
    std::cout << std::endl;

    int val = j["ActLike"];
    std::cout << val << std::endl;
}