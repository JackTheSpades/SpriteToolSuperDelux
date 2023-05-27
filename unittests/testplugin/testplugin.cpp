#include <cstdio>
static FILE* global_file = NULL;

#ifdef _MSC_VER
#define PIXI_EXPORT __declspec(dllexport)
#else
#define PIXI_EXPORT __attribute__((visibility("default")))
#endif

extern "C" {
PIXI_EXPORT int pixi_before_patching() {
    global_file = fopen("testplugin.txt", "w");
    fprintf(global_file, "Hello from testplugin! pixi_before_patching()\n");
    return 0;
}
PIXI_EXPORT int pixi_after_patching() {
    fprintf(global_file, "Hello from testplugin! pixi_after_patching()\n");
    return 0;
}
PIXI_EXPORT int pixi_check_version() {
    return 141;
}
PIXI_EXPORT int pixi_before_unload() {
    if (global_file == NULL) {
        return 0;
    }
    fprintf(global_file, "Hello from testplugin! pixi_before_unload()\n");
    fclose(global_file);
    return 0;
}
PIXI_EXPORT const char* pixi_plugin_error() {
    return "This is a generic error from my plugin!";
}
}