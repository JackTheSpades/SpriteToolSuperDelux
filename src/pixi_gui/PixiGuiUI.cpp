#include "PixiGuiUI.h"
#include "ui_PixiGui.h"

#include "PixiGui.h"

#include <QDockWidget>
#include <QPushButton>
#include <QTextEdit>
#include <QVBoxLayout>
#include <QLabel>
#include <QFileDialog>
#include <QMessageBox>
#include <QClipboard>
#include <QDesktopServices>
#include <filesystem>

#include "pixi_api.h"
#include "structs.h"
#include "config.h"

PixiGuiUI::PixiGuiUI(QWidget* parent) : QMainWindow(parent), ui(new Ui::PixiGuiUI) {
	ui->setupUi(this);
	setVersionLabel();
	connectPathButtons();
	connectBooleanOptions();
	connectSharedRoutinesCounter();
	connectDumpCommandLine();
}

PixiGuiUI::~PixiGuiUI() {
    delete ui;
}

std::vector<std::string> PixiGuiUI::createCommandLine() {
	std::vector<std::string> arguments{};
	arguments.push_back("pixi.exe");
	for (size_t i = 0; i < FromEnum(PathType::__SIZE__); i++) {
		PathType e = static_cast<PathType>(i);
		arguments.push_back(std::string{m_path_opts[i]});
		arguments.push_back(cfg[e]);
	}
	for (size_t i = 0; i < FromEnum(ExtType::__SIZE__); i++) {
		ExtType e = static_cast<ExtType>(i);
		if (!cfg[e].empty()) {
			arguments.push_back(std::string{m_ext_opts[i]});
			arguments.push_back(cfg[e]);
		}
	}

	if (cfg.DebugEnabled) {
		arguments.push_back("-d");
	}
	if (cfg.KeepFiles) {
		arguments.push_back("-k");
	}
	if (cfg.PerLevel) {
		arguments.push_back("-pl");
	}
	if (cfg.Disable255Sprites) {
		arguments.push_back("-d255spl");
	}
	if (cfg.Warnings) {
		arguments.push_back("-w");
	}
	if (cfg.ExtModDisabled) {
		arguments.push_back("-extmod-off");
	}
	if (cfg.DisableMeiMei) {
		arguments.push_back("-meimei-off");
	}
	if (cfg.DisableAllExtensionFiles) {
		arguments.push_back("-no-lm-aux");
	}
	if (!cfg.DisableMeiMei) {
		if (meimeicfg.debug) {
			arguments.push_back("-meimei-d");
		}
		if (meimeicfg.keep) {
			arguments.push_back("-meimei-k");
		}
		if (meimeicfg.remap) {
			arguments.push_back("-meimei-a");
		}
	}
	arguments.push_back("-nr");
	arguments.push_back(std::to_string(cfg.Routines));
	while (m_rom_path.isEmpty()) {
		m_rom_path = QFileDialog::getOpenFileName(this, tr("Select ROM..."), "", tr("ROM files(*.smc)"));
		ui->romPathLine->setText(m_rom_path);
	}
	arguments.push_back(m_rom_path.toStdString());
	return arguments;
}

std::string PixiGuiUI::createCommandLineStr() {
	const auto arguments = createCommandLine();
	return std::accumulate(arguments.begin(), arguments.end(), std::string{}, [](std::string acc, const std::string& val) {
		return acc + " " + val;
	});
}

void PixiGuiUI::connectDumpCommandLine() {
	QObject::connect(ui->dumpCommandLine, &QPushButton::clicked, this, [&]() {
		QString str = QString::fromStdString(createCommandLineStr());
		QClipboard* clipBoard = QApplication::clipboard();
		clipBoard->setText(str, QClipboard::Clipboard);
		QMessageBox::information(this, "Command line dump (command line was also copied to your clipboard)", str);
	});
	QObject::connect(ui->pixiRunButton, &QPushButton::clicked, this, [&]() {
		auto commandLine = createCommandLine();
		const char** argv = new const char*[commandLine.size()];
		for (size_t i = 0; i < commandLine.size(); i++) {
			argv[i] = commandLine[i].c_str();
		}
		int ret = pixi_run(commandLine.size(), argv);
		int size = 0;
		if (ret == EXIT_FAILURE) {
			QMessageBox::warning(this, "Pixi exited with error: ", QString{pixi_last_error(&size)});
		} else {
			QMessageBox::information(this, "Pixi finished successfully", QString::number(ret));
		}
		delete[] argv;
	});
}

void PixiGuiUI::connectSharedRoutinesCounter() {
	QObject::connect(ui->nroutinesSpinBox, &QSpinBox::valueChanged, this, [&](int value) {
		cfg.Routines = value;
	});
}

void PixiGuiUI::connectBooleanOptions() {
	QObject::connect(ui->debugCheckBox, &QCheckBox::stateChanged, this, [&](int state) {
		cfg.DebugEnabled = ui->debugCheckBox->isChecked();
	});
	QObject::connect(ui->tempFilesCheckBox, &QCheckBox::stateChanged, this, [&](int state) {
		cfg.KeepFiles = ui->tempFilesCheckBox->isChecked();
	});
	QObject::connect(ui->warningsCheckBox, &QCheckBox::stateChanged, this, [&](int state) {
		cfg.Warnings = ui->warningsCheckBox->isChecked();
	});
	QObject::connect(ui->d255splCheckBox, &QCheckBox::stateChanged, this, [&](int state) {
		cfg.Disable255Sprites = ui->d255splCheckBox->isChecked();
	});
	QObject::connect(ui->perLevelSpritesCheckBox, &QCheckBox::stateChanged, this, [&](int state) {
		cfg.PerLevel = ui->perLevelSpritesCheckBox->isChecked();
	});
	QObject::connect(ui->extModCheckBox, &QCheckBox::stateChanged, this, [&](int state) {
		cfg.ExtModDisabled = ui->extModCheckBox->isChecked();
	});
	QObject::connect(ui->disableExtCheckBox, &QCheckBox::stateChanged, this, [&](int state) {
		cfg.DisableAllExtensionFiles = ui->disableExtCheckBox->isChecked();
	});

	QObject::connect(ui->meimeiDisableCheckBox, &QCheckBox::stateChanged, this, [&](int state) {
		cfg.DisableMeiMei = ui->meimeiDisableCheckBox->isChecked();
		ui->meimeiAlwaysRemapCheckBox->setDisabled(cfg.DisableMeiMei);
		ui->meimeiKeepTempCheckBox->setDisabled(cfg.DisableMeiMei);
		ui->meimeiDebugOutputCheckBox->setDisabled(cfg.DisableMeiMei);
	});
	QObject::connect(ui->meimeiKeepTempCheckBox, &QCheckBox::stateChanged, this, [&](int state) {
		meimeicfg.keep = ui->meimeiKeepTempCheckBox->isChecked();
	});
	QObject::connect(ui->meimeiAlwaysRemapCheckBox, &QCheckBox::stateChanged, this, [&](int state) {
		meimeicfg.remap = ui->meimeiAlwaysRemapCheckBox->isChecked();
	});
	QObject::connect(ui->meimeiDebugOutputCheckBox, &QCheckBox::stateChanged, this, [&](int state) {
		meimeicfg.debug = ui->meimeiDebugOutputCheckBox->isChecked();
	});
}

void PixiGuiUI::connectPathButton(QPushButton* btn, QLineEdit* line, QPushButton* showBtn, PathType type) {
	QObject::connect(btn, &QPushButton::clicked, this, [this, btn, line, type]() {
		std::string path = QFileDialog::getExistingDirectory(this, tr("Select directory..."), "", QFileDialog::ShowDirsOnly | QFileDialog::DontResolveSymlinks).toStdString();
		if (!path.empty()) {
			cfg[type] = path;
			line->setText(QString::fromStdString(cfg[type]));
		}
	});
	QObject::connect(showBtn, &QPushButton::clicked, this, [this, line]() {
		if (!QDesktopServices::openUrl(QUrl::fromLocalFile(line->text()))) {
			QMessageBox::warning(this, "Warning", QString{"Cannot open path "} + line->text());
		}
	});
}

void PixiGuiUI::connectPathButton(QPushButton* btn, QLineEdit* line, QPushButton* showBtn, ExtType type, const char* ext) {
	QObject::connect(btn, &QPushButton::clicked, this, [this, btn, line, type, ext]() {
		std::string path = QFileDialog::getOpenFileName(this, QString::asprintf("Select %s file...", ext), "", QString::asprintf("%s files(*.%s)", ext, ext)).toStdString();
		if (!path.empty()) {
			cfg[type] = path;
			line->setText(QString::fromStdString(cfg[type]));
		}
	});
	QObject::connect(showBtn, &QPushButton::clicked, this, [this, line]() {
		std::filesystem::path p = line->text().toStdString();
		if (!QDesktopServices::openUrl(QUrl::fromLocalFile(QString::fromStdString(
															   p.parent_path().generic_string())))) {
			QMessageBox::warning(this, "Warning", QString{"Cannot open path "} + line->text());
		}
	});
}

void PixiGuiUI::connectPathButtons() {
	ui->routinesDirLine->setText(QString::fromStdString(cfg[PathType::Routines]));
	ui->spritesDirLine->setText(QString::fromStdString(cfg[PathType::Sprites]));
	ui->genDirLine->setText(QString::fromStdString(cfg[PathType::Generators]));
	ui->shootersDirLine->setText(QString::fromStdString(cfg[PathType::Shooters]));
	ui->listPathLine->setText(QString::fromStdString(cfg[PathType::List]));
	ui->asmDirLine->setText(QString::fromStdString(cfg[PathType::Asm]));
	ui->extendedDirLine->setText(QString::fromStdString(cfg[PathType::Extended]));
	ui->clusterDirLine->setText(QString::fromStdString(cfg[PathType::Cluster]));
	ui->minorextDirLine->setText(QString::fromStdString(cfg[PathType::MinorExtended]));
	ui->bounceDirLine->setText(QString::fromStdString(cfg[PathType::Bounce]));
	ui->smokeDirLine->setText(QString::fromStdString(cfg[PathType::Smoke]));
	ui->spinningDirLine->setText(QString::fromStdString(cfg[PathType::SpinningCoin]));
	ui->scoreDirLine->setText(QString::fromStdString(cfg[PathType::Score]));

	connectPathButton(ui->routinesDirBtn, ui->routinesDirLine, ui->routinesDirShow, PathType::Routines);
	connectPathButton(ui->spritesDirBtn, ui->spritesDirLine, ui->spritesDirShow, PathType::Sprites);
	connectPathButton(ui->genDirBtn, ui->genDirLine, ui->genDirShow, PathType::Generators);
	connectPathButton(ui->shootersDirBtn, ui->shootersDirLine, ui->shootersDirShow, PathType::Shooters);
	connectPathButton(ui->asmDirBtn, ui->asmDirLine, ui->asmDirShow, PathType::Asm);
	connectPathButton(ui->extendedDirBtn, ui->extendedDirLine, ui->extendedDirShow, PathType::Extended);
	connectPathButton(ui->clusterDirBtn, ui->clusterDirLine, ui->clusterDirShow, PathType::Cluster);
	connectPathButton(ui->minorextDirBtn, ui->minorextDirLine, ui->minorextDirShow, PathType::MinorExtended);
	connectPathButton(ui->bounceDirBtn, ui->bounceDirLine, ui->bounceDirShow, PathType::Bounce);
	connectPathButton(ui->smokeDirBtn, ui->smokeDirLine, ui->smokeDirShow, PathType::Smoke);
	connectPathButton(ui->spinningDirBtn, ui->spinningDirLine, ui->spinningDirShow, PathType::SpinningCoin);
	connectPathButton(ui->scoreDirBtn, ui->scoreDirLine, ui->scoreDirShow, PathType::Score);

	connectPathButton(ui->sscPathBtn, ui->sscPathLine, ui->sscPathShow, ExtType::Ssc, "ssc");
	connectPathButton(ui->mwtPathBtn, ui->mwtPathLine, ui->mwtPathShow, ExtType::Mwt, "mwt");
	connectPathButton(ui->mw2PathBtn, ui->mw2PathLine, ui->mw2PathShow, ExtType::Mw2, "mw2");
	connectPathButton(ui->s16PathBtn, ui->s16PathLine, ui->s16PathShow, ExtType::S16, "s16");

	QObject::connect(ui->listPathBtn, &QPushButton::clicked, this, [&]() {
		std::string listpath = QFileDialog::getOpenFileName(this, tr("Select list file..."), "", tr("Text files(*.txt)")).toStdString();
		if (!listpath.empty()) {
			cfg[PathType::List] = listpath;
			ui->listPathLine->setText(QString::fromStdString(cfg[PathType::List]));
		}
	});
	QObject::connect(ui->listPathOpen, &QPushButton::clicked, this, [&]() {
		if (!QDesktopServices::openUrl(QUrl::fromLocalFile(ui->listPathLine->text()))) {
			QMessageBox::warning(this, "Warning", QString{"Cannot open path "} + ui->listPathLine->text());
		}
	});

	QObject::connect(ui->romPathButton, &QPushButton::clicked, this, [&]() {
		m_rom_path = QFileDialog::getOpenFileName(this, tr("Select ROM..."), "", tr("ROM files(*.smc)"));
		ui->romPathLine->setText(m_rom_path);
	});
}

void PixiGuiUI::setVersionLabel() {
	// VERSION_EDITION * 100 + VERSION_MAJOR * 10 + VERSION_MINOR
	int pixi_ver = pixi_api_version();
	int pixi_ver_maj = pixi_ver / 100;
	int pixi_ver_min = pixi_ver % 100;
	ui->pixiVersionLabel->setText(QString::asprintf("Pixi version: %d.%d", pixi_ver_maj, pixi_ver_min));
}
