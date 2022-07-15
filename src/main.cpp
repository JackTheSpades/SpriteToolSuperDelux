#include "api_bindings/pixi_api.h"
#include "iohandler.h"
#include "libconsole/libconsole.h"

int main(int argc, char** argv) {
    if (!libconsole::init()) {
        iohandler::get_global().error("Failed to initialize console output. Please report this to " GITHUB_ISSUE_LINK
                                      ". Aborting...\n");
        return EXIT_FAILURE;
    }
	const char** copied_argv = new const char*[argc];
	for (int i = 0; i < argc; i++) {
		copied_argv[i] = argv[i];
	}
    int retval = pixi_run(argc, copied_argv);
    delete[] copied_argv;
    return retval;
}
