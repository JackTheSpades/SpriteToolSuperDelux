
#include <iostream>
#include <fstream>
#include <string>
#include <iomanip>
#include <sstream>
#include <stdio.h>

#include "windows.h"
#include "Rom.h"

#include "MeiMei.h"

#include "../asar/asardll.h"

#include "../structs.h"

using namespace std;

typedef unsigned int uint;
typedef unsigned short ushort;
typedef unsigned char uchar;

const int SPR_ADDR_LIMIT = 0x800;

#define ERR(msg) {printf("Error: %s", msg); goto end; }

uchar readByte(Rom* r, int addr) {
	uchar tmp;
	r->readData(&tmp, 1, addr);
	return tmp;
}

ushort readWord(Rom* r, int addr) {
	uchar tmp[2];
	r->readData(&tmp, 2, addr);
	return tmp[0]|(tmp[1]<<8);
}

uint readLong(Rom* r, int addr) {
	uchar tmp[3];
	r->readData(&tmp, 3, addr);
	return tmp[0]|(tmp[1]<<8)|(tmp[2]<<16);
}

void writeByte(Rom* r, int addr, uchar Data) {
	r->writeData(&Data, 1, addr);
}

void writeWord(Rom* r, int addr, ushort Data) {
	uchar tmp[2] = {(uchar)Data, (uchar)(Data>>8)};
	r->writeData(&tmp, 2, addr);
}

void writeLong(Rom* r, int addr, ushort Data) {
	uchar tmp[3] = {(uchar)Data, (uchar)(Data>>8), (uchar)(Data>>16)};
	r->writeData(&tmp, 3, addr);
}

int SNEStoPC(int addr, bool isSa1) 
{
	if (!isSa1)
	{
		return (addr&0x7FFF)+((addr&0x7F0000)>>1);
	}
	else
	{
		if (addr >= 0xC00000)
		{
			return addr - 0x800000;
		}
		else
		{
			int newAddr = addr;
			if (newAddr >= 0x800000)
			{
				newAddr -= 0x400000;
			}

			return (newAddr & 0x7FFF)|((newAddr >> 1) & 0x7F8000);
		}
	}
}

int PCtoSNES(int addr, bool isSa1) 
{
	if (!isSa1)
	{
		return ((addr&0x7FFF)+0x8000)+((addr&0x3F8000)<<1);
	}
	else
	{
		int newAddr = 0;
		if (addr >= 0x400000)
		{
			return addr + 0x800000;
		}
		else
		{
			newAddr = (addr & 0x7FFF)|((addr & ~0x7FFF)<<1)|0x8000;
			if (newAddr >= 0x400000)
			{
				return newAddr + 0x400000;
			}
			else
			{
				return newAddr;
			}
		}
	}
}

void wait() {
	fflush(stdin);
	getc(stdin);
}

string MeiMei::name;
Rom* MeiMei::prev;
uchar MeiMei::prevEx[0x400];
uchar MeiMei::nowEx[0x400];
bool MeiMei::always = false;
bool MeiMei::debug = false;
bool MeiMei::keepTemp = false;
string MeiMei::sa1DefPath;

void MeiMei::setAlwaysRemap()
{
	MeiMei::always = true;
}

void MeiMei::setDebug()
{
	MeiMei::debug = true;
}

void MeiMei::setKeepTemp()
{
	MeiMei::keepTemp = true;
}

void MeiMei::configureSa1Def(string pathToSa1Def)
{
	MeiMei::sa1DefPath = pathToSa1Def;
}

bool MeiMei::patch(const char *patch_name, ROM &rom)
{
	if (!asar_patch(patch_name, (char *)rom.real_data, MAX_ROM_SIZE, &rom.size))
	{
		int error_count;
		const errordata *errors = asar_geterrors(&error_count);
		printf("An error has been detected:\n");
		for (int i = 0; i < error_count; i++)
			printf("%s\n", errors[i].fullerrdata);
		return false;
	}

	if (MeiMei::debug)
	{
		int print_count = 0;
		const char *const *prints = asar_getprints(&print_count);
		for (int i=0; i<print_count; ++i)
		{
			cout << "\t" << prints[i] << endl;
		}
	}
	
	return true;
}

void MeiMei::initialize(const char* name)
{
	MeiMei::name = std::string(name);
	uchar* prevEx = MeiMei::prevEx;
	uchar* nowEx = MeiMei::nowEx;
	
	for (int i=0;i<0x400;i++)
	{
	 	prevEx[i] = 0x03;
	 	nowEx[i] = 0x03;
	}
	
	MeiMei::prev = new Rom(MeiMei::name);
	Rom* prev = MeiMei::prev;
	if (readByte(prev, 0x07730F)==0x42)
	{
		int addr = SNEStoPC((int)readLong(prev, 0x07730C), prev->isSa1());
	 	prev->readData(prevEx, 0x0400, addr);
	}
}

int MeiMei::run()
{
	ROM rom;
	rom.open(MeiMei::name.c_str());

	if (!asar_init())
	{
		error("Error: Asar library is missing or couldn't be initialized, please redownload the tool or add the dll.\n", "");
	}

	int returnValue = MeiMei::run(rom);

	rom.close();
	asar_close();

	if (returnValue)
	{
		prev->writeRomFile();
		printf("\n\nError occureted in MeiMei.\n"
				"Your rom has reverted to before pixi insert.\n");
	}

	return returnValue;
}

int MeiMei::run(ROM& rom)
{
	Rom* prev = MeiMei::prev;
	uchar* prevEx = MeiMei::prevEx;
	uchar* nowEx = MeiMei::nowEx;

	Rom* now = new Rom(MeiMei::name);
	if (readByte(prev, 0x07730F)==0x42)
	{
		int addr = SNEStoPC((int)readLong(now, 0x07730C), now->isSa1());
		now->readData(nowEx, 0x0400, addr);
	}

	bool changeEx = false;
	for (int i=0;i<0x400;i++)
	{
		if (prevEx[i] != nowEx[i])
		{
			changeEx = true;
			break;
		}
	}

	bool revert = changeEx||MeiMei::always;
	if (changeEx)
	{
		printf("\nExtra bytes change detected\n");
	}

	if (changeEx||MeiMei::always) 
	{
		uchar sprAllData[SPR_ADDR_LIMIT];
		uchar sprCommonData[3];
		bool remapped[0x0200];
		for(int i=0;i<0x0200;i++)
		{
			remapped[i] = false;
		}

		for (int lv=0;lv<0x200;lv++)
		{
			if (remapped[lv]) continue;

			int sprAddrSNES = (readByte(now, 0x077100+lv)<<16)+readWord(now, 0x02EC00+lv*2);
			if ((sprAddrSNES&0x8000) == 0)
			{
				ERR("Sprite Data has invalid address.");
			}

			int sprAddrPC = SNEStoPC(sprAddrSNES, now->isSa1());
			for (int i=0;i<SPR_ADDR_LIMIT;i++)
			{
				sprAllData[i] = 0;
			}
			
			sprAllData[0] = readByte(now, sprAddrPC);
			int prevOfs = 1;
			int nowOfs = 1;
			bool exlevelFlag = sprAllData[0] & (uchar) 0x20;
			bool changeData = false;

			#define OF_NOW_OFS() if(nowOfs>=SPR_ADDR_LIMIT) ERR("Sprite data is too large!");

			while (true)
			{
				now->readData(&sprCommonData, 3, sprAddrPC+prevOfs);
				if (nowOfs >= SPR_ADDR_LIMIT-3)
				{
					ERR("Sprite data is too large!");
				}

				if (sprCommonData[0]==0xFF)
				{
					sprAllData[nowOfs++] = 0xFF;
					if (!exlevelFlag)
					{	
						break;
					}

					sprAllData[nowOfs++] = sprCommonData[1];
					if (sprCommonData[1] == 0xFE)
					{				
						break;
					}
					else
					{
						prevOfs += 2;
						now->readData(&sprCommonData, 3, sprAddrPC+prevOfs);
					}
				}

				sprAllData[nowOfs++] = sprCommonData[0];	// YYYYEEsy
				sprAllData[nowOfs++] = sprCommonData[1];	// XXXXSSSS
				sprAllData[nowOfs++] = sprCommonData[2];	// NNNNNNNN

				int sprNum = ((sprCommonData[0]&0x0C)<<6)|(sprCommonData[2]);

				if (nowEx[sprNum] > prevEx[sprNum])
				{
					changeData = true;
					int i;
					for (i=3;i<prevEx[sprNum];i++)
					{
						sprAllData[nowOfs++] = readByte(now, sprAddrPC+prevOfs+i);
						OF_NOW_OFS();
					}
					for(;i<nowEx[sprNum];i++)
					{
						sprAllData[nowOfs++] = 0x00;
						OF_NOW_OFS();
					}
				} 
				else if (nowEx[sprNum] < prevEx[sprNum])
				{
					changeData = true;
					for(int i=3;i<nowEx[sprNum];i++)
					{
						sprAllData[nowOfs++] = readByte(now, sprAddrPC+prevOfs+i);
						OF_NOW_OFS();
					}
				}
				else
				{
					for(int i=3;i<nowEx[sprNum];i++)
					{
						sprAllData[nowOfs++] = readByte(now, sprAddrPC+prevOfs+i);
						OF_NOW_OFS();
					}
				}
				prevOfs += prevEx[sprNum];
			}

			prevOfs++;
			if(changeData)
			{
				stringstream ss;
				ss << uppercase << hex << lv;
				string levelAsHex = ss.str();

				// create sprite data binary
				std::string binaryFileName("_tmp_bin_");
				binaryFileName.append(levelAsHex);
				binaryFileName.append(".bin");
				std::ofstream binFile(binaryFileName, ios::out|ios::binary);

				if(sprAllData != nullptr) {
					uchar* dataPtr = (uchar*)sprAllData;
					for(int ara=0;ara<=nowOfs;ara++) {
						binFile << dataPtr[ara];
					}
				}
				binFile.close();

				// create patch for sprite data binary
				std::string fileName("_tmp_");
				fileName.append(levelAsHex);
				fileName.append(".asm");
				std::ofstream spriteDataPatch(fileName, ios::out|ios::binary);

				std::string binaryLabel("SpriteData");
				binaryLabel.append(levelAsHex);

				std::ostringstream oss;
				oss << std::setfill('0') << std::setw(6) << std::hex << PCtoSNES(0x077100+lv, now->isSa1());
				std::string levelBankAddress = oss.str();

				oss = std::ostringstream();
				oss << std::setfill('0') << std::setw(6) << std::hex << PCtoSNES(0x02EC00+lv*2, now->isSa1());
				std::string levelWordAddress = oss.str();

				// create actual asar patch
				spriteDataPatch << "incsrc \"" << MeiMei::sa1DefPath << "\"" << endl << endl;
				spriteDataPatch << "!oldDataPointer = read2($" << levelWordAddress << ")|(read1($" << levelBankAddress << ")<<16)" << endl;
				spriteDataPatch << "!oldDataSize = read2(pctosnes(snestopc(!oldDataPointer)-4))+1" << endl;
				spriteDataPatch << "autoclean !oldDataPointer" << endl << endl;

				spriteDataPatch << "org $" << levelBankAddress << endl;
				spriteDataPatch << "\tdb " << binaryLabel << ">>16" << endl << endl;

				spriteDataPatch << "org $" << levelWordAddress << endl;
				spriteDataPatch << "\tdw " << binaryLabel << endl << endl;

				spriteDataPatch << "freedata cleaned" << endl;
				spriteDataPatch << binaryLabel << ":" << endl;
				spriteDataPatch << "\t!newDataPointer = " << binaryLabel << endl;
				spriteDataPatch << "\tincbin " << binaryFileName << endl;
				spriteDataPatch << binaryLabel << "_end:" << endl;

				spriteDataPatch << "\tprint \"Data pointer  $\",hex(!oldDataPointer),\" : $\",hex(!newDataPointer)" << endl;
				spriteDataPatch << "\tprint \"Data size     $\",hex(!oldDataSize),\" : $\",hex(" << binaryLabel << "_end-" << binaryLabel << "-1)" << endl;
				
				spriteDataPatch.close();

				if (MeiMei::debug)
				{
					cout << "__________________________________" << endl;
					cout << "Fixing sprite data for level " << levelAsHex << endl;
				}

				if (!MeiMei::patch(fileName.c_str(), rom))
				{
					ERR("An error occured when patching sprite data with asar.")
				}

				if (MeiMei::debug)
				{
					cout << "Done!" << endl;
				}

				if (!MeiMei::keepTemp)
				{
					remove(binaryFileName.c_str());
					remove(fileName.c_str());
				}

				remapped[lv] = true;
			}
		}

		if (MeiMei::debug)
		{
			cout << "__________________________________" << endl << endl;
		}

		printf("Sprite data remapped successfully.\n");
		revert = false;
	}
end:
	if(revert) {
		return 1;
	}

	return 0;
}