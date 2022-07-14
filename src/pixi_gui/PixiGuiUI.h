#pragma once
#include <QMainWindow>

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
    Ui::PixiGuiUI* ui;
    void addTextBoxes();
	void setVersionLabel();
};
