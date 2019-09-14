
#ifndef MT_UZUME_SRC_ROM_H_
#define MT_UZUME_SRC_ROM_H_

#include <fstream>
#include <string>
#include <iostream>

using namespace std;

typedef unsigned char	uchar;
typedef unsigned short	ushort;
typedef unsigned int	uint;

// �l�p���ԗւ̍Ĕ����`
class Rom {

public:
	// rom�̎��
	enum ERomType {
		LOROM,HIROM,EXLOROM,EXHIROM,
	};

	// header�̗L��
	enum EHeader {
		NO_HEADER,HEADER
	};

	// bank���E���ׂ��ł�����
	enum EBankBorder {
		NG,OK
	};


	Rom();
	Rom(string romName);
	Rom(string romName,Rom::ERomType romType,Rom::EHeader header);
	~Rom();

	// rom���J��
	bool open(string romName);
	bool open(string romName,Rom::ERomType romType,Rom::EHeader header);

	// rom�̋󂫗̈��T��
	// RATS�^�O���l������
	// �߂�l �󂫗̈�̐擪�A�h���X -1�Ŏ��s
	int findFreeSpace(int startAddr,int size);
	int findFreeSpace(int startAddr,int endAddr,int size);
	int findFreeSpace(int startAddr,int endAddr,int size,Rom::EBankBorder border);

	// �w�肳�ꂽ�f�[�^���T��
	// �߂�l �f�[�^��̐擪�A�h���X -1�Ŏ��s
	int findData(void* data,int size,int startAddr);
	int findData(void* data,int size,int startAddr,int endAddr);

	// �w�肳�ꂽ�A�h���X��RATS�^�O�y�уf�[�^����������
	// �߂�l ��[���Ő���
	int writeRATSdata(void* data,int size,int addr);

	// �w�肳�ꂽ�A�h���X��RATS�^�O�擪�Ȃ�ی삳��Ă���f�[�^���폜
	// �߂�l �폜�����e�� 0�Ŏ��s
	int eraseRATSdata(int addr);

	// �w�肳�ꂽ�A�h���X��RATS�^�O�擪���m�F
	// �߂�l �ی�̈�̑傫��
	// 0�ȉ��̏ꍇRATS�^�O�ł͂Ȃ�
	int checkRATSdata(int addr);

	// �w�肵���̈���폜
	// ��[���Ő���
	int eraseData(int addr,int size);
	int eraseData(int addr,int size,bool alwaysMode);

	// �w�肳�ꂽ�A�h���X�Ƀf�[�^����������
	// ��[���Ő���
	int writeData(void* data,int size,int addr);

	// �w�肳�ꂽ�A�h���X�Ƀf�[�^���J��Ԃ���������
	// ��[���Ő���
	int writeReptData(void* data,int dataSize,int size,int addr);

	// �w�肳�ꂽ�A�h���X����f�[�^��ǂݍ���
	// ��[���Ő���
	int readData(void* data,int size,int addr);

	// �ҏW�����f�[�^��ۑ�
	// ��[���Ő���
	int writeRomFile();

	// �A�N�Z�b�T����
	bool isSa1();
	bool isOpen();						// �t�@�C�����J�������m�F
	void* getRomDataPtr();				// �t�@�C���o�b�t�@�̃|�C���^���擾
	int getRomSize();					// rom�e�ʎ擾
	void setFreeSpaceNum(uchar num);	// �󂫗̈�Ƃ���l��ύX

	int getRomData(int addr);			// rom�f�[�^�ǂݍ���
	int setRomData(int addr,uchar num);// rom�f�[�^��������

private:
	// ������̃R���X�g���N�^
	void init (string romName,Rom::ERomType romType,Rom::EHeader header);

	bool inline checkAddr(int addr,int size);

	fstream romFile;
	string romPath;

	// rom���J������
	bool fileOpen = false;

	// rom�̗e��
	int romSize = 0;

	// �󂫗̈�Ƃ���l �f�t�H���g�ł̓[��
	// �f�[�^�폜���͂��̒l�ŗ̈�𖄂߂�
	uchar freeSpaceNum = 0x00;

	// rom�̃f�[�^
	uchar* romData = (uchar*)0;

	// rom�̎��
	// SMW�̏ꍇLOROM
	ERomType romType = LOROM;

	// .smc�t�@�C����512bytes�w�b�_�̗L��
	// �ʏ�̓w�b�_����
	EHeader header = HEADER;

};

#endif /* MT_UZUME_SRC_ROM_H_ */
