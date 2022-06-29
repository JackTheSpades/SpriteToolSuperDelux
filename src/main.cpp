#include "api_bindings/pixi_api.h"

int main(int argc, char** argv) {
    const char** copied_argv = new const char*[argc];
    for (int i = 0; i < argc; i++) {
        copied_argv[i] = argv[i];
    }
    int retval = pixi_run(argc, copied_argv);
    delete[] copied_argv;
	return retval;
}