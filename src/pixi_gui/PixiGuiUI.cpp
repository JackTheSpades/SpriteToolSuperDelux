#include "PixiGuiUI.h"
#include "ui_PixiGui.h"

#include "PixiGui.h"

#include <QDockWidget>
#include <QPushButton>
#include <QTextEdit>
#include <QVBoxLayout>
#include <QLabel>

#include "pixi_api.h"
#include "argparser.h"
#include "structs.h"
#include "MeiMei/MeiMei.h"

PixiGuiUI::PixiGuiUI(QWidget* parent) : QMainWindow(parent), ui(new Ui::PixiGuiUI) {
    ui->setupUi(this);
	addTextBoxes();
	setVersionLabel();
}

PixiGuiUI::~PixiGuiUI() {
    delete ui;
}

void PixiGuiUI::setVersionLabel() {
	// VERSION_EDITION * 100 + VERSION_MAJOR * 10 + VERSION_MINOR
	int pixi_ver = pixi_api_version();
	int pixi_ver_maj = pixi_ver / 100;
	int pixi_ver_min = pixi_ver % 100;
	ui->pixiVersionLabel->setText(QString::asprintf("Pixi version: %d.%d", pixi_ver_maj, pixi_ver_min));
}

void PixiGuiUI::addTextBoxes() {
    std::string name;
    std::string lm_handle;
    bool version_requested{};
    argparser optparser{};
    PixiConfig cfg{};
    optparser.add_version(0, 0);
    optparser.allow_unmatched(1);
    optparser.add_usage_string("pixi <options> [ROM]");
    optparser.add_option("-v", "Print version information", version_requested)
        .add_option("--rom", "ROMFILE",
                    "ROM file, when the --rom is not given, it is assumed to be the first unmatched argument", name)
        .add_option("-d", "Enable debug output, the option flag -out only works when this is set", cfg.DebugEnabled)
        .add_option("-k", "Keep debug files", cfg.KeepFiles)
        .add_option("-l", "list path", "Specify a custom list file", cfg[PathType::List])
        .add_option("-pl", "Per level sprites - will insert perlevel sprite code", cfg.PerLevel)
        .add_option("-npl", "Disable per level sprites (default), kept for compatibility reasons", argparser::no_value)
        .add_option("-d255spl", "Disable 255 sprites per level support (won't do the 1938 remap)",
                    cfg.Disable255Sprites)
        .add_option("-w", "Enable asar warnings check, recommended to use when developing sprites.", cfg.Warnings)
        .add_option("-a", "asm", "Specify a custom asm directory", cfg[PathType::Asm])
        .add_option("-sp", "sprites", "Specify a custom sprites directory", cfg[PathType::Sprites])
        .add_option("-sh", "shooters", "Specify a custom shooters sprites directory", cfg[PathType::Shooters])
        .add_option("-g", "generators", "Specify a custom generators sprites directory", cfg[PathType::Generators])
        .add_option("-e", "extended", "Specify a custom extended sprites directory", cfg[PathType::Extended])
        .add_option("-c", "cluster", "Specify a custom cluster sprites directory", cfg[PathType::Cluster])
        .add_option("-me", "minorextended", "Specify a custom minor extended sprites directory",
                    cfg[PathType::MinorExtended])
        .add_option("-b", "bounce", "Specify a custom bounce sprites directory", cfg[PathType::Bounce])
        .add_option("-sm", "smoke", "Specify a custom smoke sprites directory", cfg[PathType::Smoke])
        .add_option("-sn", "spinningcoin", "Specify a custom spinningcoin sprites directory",
                    cfg[PathType::SpinningCoin])
        .add_option("-sc", "score", "Specify a custom score sprites directory", cfg[PathType::Score])
        .add_option("-r", "routines", "Specify a shared routine directory", cfg[PathType::Routines])
        .add_option("-nr", "number", "Specify limit to shared routines, the maximum number is 310", cfg.Routines)
        .add_option("-extmod-off", "Disables extmod file logging (check LM's readme for more info on what extmod is)",
                    cfg.ExtModDisabled)
        .add_option("-ssc", "append ssc", "Specify ssc file to be copied into <romname>.ssc", cfg[ExtType::Ssc])
        .add_option("-mwt", "append mwt", "Specify mwt file to be copied into <romname>.mwt", cfg[ExtType::Mwt])
        .add_option("-mw2", "append mw2", "Specify mw2 file to be copied into <romname>.mw2", cfg[ExtType::Mw2])
        .add_option("-s16", "base s16", "Specify s16 file to be used as a base for <romname>.s16", cfg[ExtType::S16])
        .add_option("-no-lm-aux", "Disables all of the Lunar Magic auxiliary files creation (ssc, mwt, mw2, s16)",
                    cfg.DisableAllExtensionFiles)
        .add_option("-meimei-off", "Shuts down MeiMei completely", cfg.DisableMeiMei)
        .add_option("-meimei-a", "Enables always remap sprite data", MeiMei::AlwaysRemap())
        .add_option("-meimei-k", "Enables keep temp patches files", MeiMei::KeepTemp())
        .add_option("-meimei-d", "Enables debug for MeiMei patches", MeiMei::Debug())
#ifdef _WIN32
        .add_option("-lm-handle", "lm_handle_code",
                    "To be used only within LM's custom user toolbar file, it receives LM's handle to reload the rom",
                    lm_handle)
#endif
        ;
}
