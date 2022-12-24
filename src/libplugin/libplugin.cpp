#include "libplugin.h"
#include "../iohandler.h"
#include <array>
#include <filesystem>

namespace fs = std::filesystem;

#ifdef ON_WINDOWS
#define PATHF "%S"
#define LoadEntryPoint GetProcAddress
#define LoadPlugin LoadLibrary
#define ClosePlugin FreeLibrary
#else
#include <dlfcn.h>
#define PATHF "%s"
#define LoadEntryPoint dlsym
#define LoadPlugin(x) dlopen(x, RTLD_NOW)
#define ClosePlugin dlclose
#endif

namespace plugins {
plugin::plugin(plugin::path_type name) : m_name(std::move(name)) {
}
int plugin::load() {
    m_lib_handle = LoadPlugin(m_name.c_str());
    if (m_lib_handle != NULL) {
        m_before_patching = reinterpret_cast<pluginEntryPoint>(LoadEntryPoint(m_lib_handle, "pixi_before_patching"));
        m_after_patching = reinterpret_cast<pluginEntryPoint>(LoadEntryPoint(m_lib_handle, "pixi_after_patching"));
        m_check_version = reinterpret_cast<pluginEntryPoint>(LoadEntryPoint(m_lib_handle, "pixi_check_version"));
        m_before_unload = reinterpret_cast<pluginEntryPoint>(LoadEntryPoint(m_lib_handle, "pixi_before_unload"));
        m_plugin_error = reinterpret_cast<pluginErrorInfo>(LoadEntryPoint(m_lib_handle, "pixi_plugin_error"));
    } else {
        return EXIT_FAILURE;
    }
    return EXIT_SUCCESS;
}

#define PLUGIN_CHECK_RETURN(FUNC_NAME)                                                                                 \
    if (ec != EXIT_SUCCESS) {                                                                                          \
        plugin::path_type filename = fs::path(m_name).filename().native();                                             \
        if (m_plugin_error != NULL) {                                                                                  \
            iohandler::get_global().error("Plugin \"" PATHF "\" " FUNC_NAME                                            \
                                          " hook failed with \"%s\" (exit code: %d)",                                  \
                                          filename.c_str(), m_plugin_error(), ec);                                     \
        } else {                                                                                                       \
            iohandler::get_global().error("Plugin \"" PATHF "\" " FUNC_NAME " hook failed with exit code: %d",         \
                                          filename.c_str(), ec);                                                       \
        }                                                                                                              \
    }

int plugin::before_patching() const {
    if (m_before_patching != NULL) {
        int ec = m_before_patching();
        PLUGIN_CHECK_RETURN("pixi_before_patching()");
        return ec;
    }
    return 0;
}
int plugin::after_patching() const {
    if (m_after_patching != NULL) {
        int ec = m_after_patching();
        PLUGIN_CHECK_RETURN("pixi_after_patching()");
        return ec;
    }
    return 0;
}
int plugin::check_version(int expected_version) const {
    if (m_check_version != NULL) {
        int required_ver = m_check_version();
        bool good = expected_version == required_ver;
        if (!good) {
            plugin::path_type filename = fs::path(m_name).filename().native();
            iohandler::get_global().error("Plugin \"" PATHF
                                          "\" version checking failed, expected pixi version %d but got %d\n",
                                          filename.c_str(), expected_version, required_ver);
        }
        return good ? EXIT_SUCCESS : EXIT_FAILURE;
    }
    return 0;
}
plugin::~plugin() {
    if (m_before_unload != NULL) {
        int ec = m_before_unload();
        PLUGIN_CHECK_RETURN("pixi_before_unload()");
    }
    ClosePlugin(m_lib_handle);
}
} // namespace plugins