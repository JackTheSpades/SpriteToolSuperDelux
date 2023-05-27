#pragma once
#include <concepts>
#include <functional>
#include <string>
#include <string_view>
#include <vector>

/*
 * PIXI PLUGIN DOCUMENTATION:
 * - Supports 4 hooks:
 *   - int pixi_before_patching(void) -> occurs before any modifications to the rom, always runs
 *   - int pixi_after_patching(void) -> occurs after all modifications to the rom, will only run if there are no errors
 *   - int pixi_check_version(void) -> returns an int that defines what version of pixi this plugin is targeting
 *   - int pixi_before_unload(void) -> occurs at plugin unloading, always runs
 *   - const char* pixi_plugin_error(void) -> used to retrieve error info in case a hook returns a non-zero exit code.
 * - All hooks are optional and may or may not be defined, as such, a plugin with no hooks is valid (but useless)
 * - All hooks are expected to take no arguments and return an integer,
 *   except for pixi_plugin_error which is expected to return a null terminated const char*
 *   the returned int is used as exit code in all cases except for pixi_check_version which uses it as version number
 *   an exit code of 0 is assumed to be success, everything else is failure
 *   the version number is MAJOR*100+MINOR*10+PATCH, for example 1.32 will be 132 and 1.40 will be 140.
 * - All hooks are required to be using the C calling convention (cdecl)
 * - Pixi will search for plugins in the plugins/ folder of the cwd if present. It'll load all dynamic libraries
 *   present in that folder and will try to call all of the hooks at the appropriate times.
 *   Plugin loading order and plugin calling order are both UNSPECIFIED,
 *   however, the loading order will be the same as the calling order.
 * - If a plugin hook is not found it's not an error, however, a hook call returning non-zero is treated as fatal error
 *   and pixi will exit.
 */

#ifdef ON_WINDOWS
#include <Windows.h>
using plugin_handle_t = HINSTANCE;
#else
using plugin_handle_t = void*;
#endif

namespace plugins {

extern "C" {
typedef int (*pluginEntryPoint)(void);
typedef const char* (*pluginErrorInfo)(void);
}
#define PLUGIN_ENTRY_POINT(name, ...)                                                                                  \
  private:                                                                                                             \
    pluginEntryPoint m_##name = NULL;                                                                                  \
                                                                                                                       \
  public:                                                                                                              \
    int name(__VA_ARGS__) const;

class plugin {
#ifdef UNICODE
    using path_type = std::wstring;
#else
    using path_type = std::string;
#endif
    path_type m_name;
    plugin_handle_t m_lib_handle = NULL;
    pluginErrorInfo m_plugin_error = NULL;
    int plugin_check_return(int ec, std::string_view) const;

  public:
    plugin(path_type name);
    int load();
    PLUGIN_ENTRY_POINT(before_patching)
    PLUGIN_ENTRY_POINT(after_patching)
    PLUGIN_ENTRY_POINT(check_version, int)
    PLUGIN_ENTRY_POINT(before_unload)
    ~plugin();
};

template <typename Callable, typename... Args>
concept Hook = std::is_invocable_r_v<int, Callable, plugin, Args...>;

template <typename Callable, typename... Args>
requires Hook<Callable, Args...>
int for_each_plugin(const std::vector<plugin>& plugins, Callable func, Args... args) {
    for (const auto& p : plugins) {
        if (std::invoke(func, p, args...) != EXIT_SUCCESS) {
            return EXIT_FAILURE;
        };
    }
    return EXIT_SUCCESS;
}

} // namespace plugins