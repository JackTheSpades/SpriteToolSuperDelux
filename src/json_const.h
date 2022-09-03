#include <nlohmann/json.hpp>

auto j1656(const nlohmann::json& j) {
    unsigned char c = 0;
    auto& byte = j["$1656"];
    c |= (((int)byte["Object Clipping"] & 0x0F) << 0);
    c |= (byte["Can be jumped on"] ? 0x10 : 0);
    c |= (byte["Dies when jumped on"] ? 0x20 : 0);
    c |= (byte["Hop in/kick shell"] ? 0x40 : 0);
    c |= (byte["Disappears in cloud of smoke"] ? 0x80 : 0);
    return c;
}

auto j1662(const nlohmann::json& j) {
    unsigned char c = 0;
    auto& byte = j["$1662"];
    c |= (((int)byte["Sprite Clipping"] & 0x3F) << 0);
    c |= (byte["Use shell as death frame"] ? 0x40 : 0);
    c |= (byte["Fall straight down when killed"] ? 0x80 : 0);
    return c;
}

auto j166e(const nlohmann::json& j) {
    unsigned char c = 0;
    auto& byte = j["$166E"];
    c |= (byte["Use second graphics page"] ? 0x01 : 0);
    c |= (((int)byte["Palette"] & 0x07) << 1);
    c |= (byte["Disable fireball killing"] ? 0x10 : 0);
    c |= (byte["Disable cape killing"] ? 0x20 : 0);
    c |= (byte["Disable water splash"] ? 0x40 : 0);
    c |= (byte["Don't interact with Layer 2"] ? 0x80 : 0);
    return c;
}

auto j167a(const nlohmann::json& j) {
    unsigned char c = 0;
    auto& byte = j["$167A"];
    c |= (byte["Don't disable cliping when starkilled"] ? 0x01 : 0);
    c |= (byte["Invincible to star/cape/fire/bounce blk."] ? 0x02 : 0);
    c |= (byte["Process when off screen"] ? 0x04 : 0);
    c |= (byte["Don't change into shell when stunned"] ? 0x08 : 0);
    c |= (byte["Can't be kicked like shell"] ? 0x10 : 0);
    c |= (byte["Process interaction with Mario every frame"] ? 0x20 : 0);
    c |= (byte["Gives power-up when eaten by yoshi"] ? 0x40 : 0);
    c |= (byte["Don't use default interaction with Mario"] ? 0x80 : 0);
    return c;
}

auto j1686(const nlohmann::json& j) {
    unsigned char c = 0;
    auto& byte = j["$1686"];
    c |= (byte["Inedible"] ? 0x01 : 0);
    c |= (byte["Stay in Yoshi's mouth"] ? 0x02 : 0);
    c |= (byte["Weird ground behaviour"] ? 0x04 : 0);
    c |= (byte["Don't interact with other sprites"] ? 0x08 : 0);
    c |= (byte["Don't change direction if touched"] ? 0x10 : 0);
    c |= (byte["Don't turn into coin when goal passed"] ? 0x20 : 0);
    c |= (byte["Spawn a new sprite"] ? 0x40 : 0);
    c |= (byte["Don't interact with objects"] ? 0x80 : 0);
    return c;
}

auto j190f(const nlohmann::json& j) {
    unsigned char c = 0;
    auto& byte = j["$190F"];
    c |= (byte["Make platform passable from below"] ? 0x01 : 0);
    c |= (byte["Don't erase when goal passed"] ? 0x02 : 0);
    c |= (byte["Can't be killed by sliding"] ? 0x04 : 0);
    c |= (byte["Takes 5 fireballs to kill"] ? 0x08 : 0);
    c |= (byte["Can be jumped on with upwards Y speed"] ? 0x10 : 0);
    c |= (byte["Death frame two tiles high"] ? 0x20 : 0);
    c |= (byte["Don't turn into a coin with silver POW"] ? 0x40 : 0);
    c |= (byte["Don't get stuck in walls (carryable sprites)"] ? 0x80 : 0);
    return c;
}
