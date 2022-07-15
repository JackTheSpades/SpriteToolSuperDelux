#pragma once
#include <QMainWindow>
#include <string>
#include <vector>
#include <QPushButton>
#include <QLineEdit>
#include "config.h"

QT_BEGIN_NAMESPACE
namespace Ui {
class PixiGuiUI;
}
QT_END_NAMESPACE

class PixiGuiUI : public QMainWindow {
    Q_OBJECT

  public:
    PixiGuiUI(QWidget* parent = nullptr);
    ~PixiGuiUI();

  private:
	QString m_rom_path{};
	constexpr static std::array<std::string_view, FromEnum(PathType::__SIZE__)> m_path_opts {
		"-r",
		"-sp",
		"-g",
		"-sh",
		"-l",
		"-a",
		"-e",
		"-c",
		"-me",
		"-b",
		"-sm",
		"-sn",
		"-sc"
	};
	constexpr static std::array<std::string_view, FromEnum(ExtType::__SIZE__)> m_ext_opts {
		"-ssc",
		"-mwt",
		"-mw2",
		"-s16"
	};
	PixiConfig cfg{};
	struct MeiMeiOptions {
		bool remap = false;
		bool keep = false;
		bool debug = false;
	} meimeicfg;
	Ui::PixiGuiUI* ui;
	void setVersionLabel();
	void connectPathButton(QPushButton* btn, QLineEdit* line, QPushButton* showBtn, PathType type);
	void connectPathButton(QPushButton* btn, QLineEdit* line, QPushButton* showBtn, ExtType type, const char* ext);
	void connectPathButtons();
	void connectBooleanOptions();
	void connectSharedRoutinesCounter();
	void connectDumpCommandLine();
	std::vector<std::string> createCommandLine();
	std::string createCommandLineStr();
};
