#include "PixiGuiUI.h"

#include <QApplication>
#include <QMessageBox>
#include <cstdio>
#include <string>
#include <vector>


#ifdef _WIN32
#define VC_EXTRALEAN
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#endif

int main(int argc, char* argv[]) {
    QApplication a(argc, argv);
    PixiGuiUI w;
    w.show();
    return a.exec();
}