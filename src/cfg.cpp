#include <stdio.h>
#include "cfg.h"
#include "structs.h"

#include <regex>
#include <sstream>
#include <string>
#include <iostream>

typedef void (*linehandler)(const char *, sprite *, int &, void *);

void cfg_type(const char *line, sprite *spr, int &handle, void *);
void cfg_actlike(const char *line, sprite *spr, int &handle, void *);
void cfg_tweak(const char *line, sprite *spr, int &handle, void *);
void cfg_prop(const char *line, sprite *spr, int &handle, void *);
void cfg_asm(const char *line, sprite *spr, int &handle, void *);
void cfg_extra(const char *line, sprite *spr, int &handle, void *);

bool read_cfg_file(sprite *spr, FILE *output)
{

	const int handlelimit = 6;
	linehandler handlers[handlelimit];

	//functions that parse lines
	handlers[0] = &cfg_type;	//parse line 1 of cfg file
	handlers[1] = &cfg_actlike; //parse line 2 etc...
	handlers[2] = &cfg_tweak;
	handlers[3] = &cfg_prop;
	handlers[4] = &cfg_asm;
	handlers[5] = &cfg_extra;

	int bytes_read = 0;
	simple_string current_line;
	int line = 0;

	int count = 0;
	const char *cfg = (char *)read_all(spr->cfg_file, true);

	do
	{
		current_line = static_cast<simple_string &&>(get_line(cfg, bytes_read));
		bytes_read += current_line.length;
		if (!current_line.length || !trim(current_line.data)[0])
			continue;

		handlers[line](current_line.data, spr, line, &count);

		if (line < 0)
		{
			delete[] cfg;
			return false;
		}

	} while (current_line.length && line < handlelimit);

	if (output)
	{
		fprintf(output, "Parsed: %s, %d lines\n", spr->cfg_file, line - 1);
	}

	delete[] cfg;
	return true;
}

void cfg_type(const char *line, sprite *spr, int &handle, void *)
{
	sscanf(line, "%x", &spr->table.type);
	handle++;
}
void cfg_actlike(const char *line, sprite *spr, int &handle, void *)
{
	sscanf(line, "%x", &spr->table.actlike);
	handle++;
}
void cfg_tweak(const char *line, sprite *spr, int &handle, void *)
{
	sscanf(line, "%x %x %x %x %x %x",
		   &spr->table.tweak[0], &spr->table.tweak[1], &spr->table.tweak[2],
		   &spr->table.tweak[3], &spr->table.tweak[4], &spr->table.tweak[5]);
	handle++;
}
void cfg_prop(const char *line, sprite *spr, int &handle, void *)
{
	sscanf(line, "%x %x",
		   &spr->table.extra[0], &spr->table.extra[1]);
	handle++;
}
void cfg_asm(const char *line, sprite *spr, int &handle, void *)
{

	spr->asm_file = append_to_dir(spr->cfg_file, line);
	handle++;
}

int parseHexString(std::string hexString)
{
	int hex;
	std::stringstream ss;
	ss << std::hex << hexString;
	ss >> hex;
	return hex;
}

void cfg_extra(const char *line, sprite *spr, int &handle, void *)
{
	handle++;

	std::string thisLine (line);
	std::regex reg (R"((0[\da-fA-F]):(0[\da-fA-F]))");
	std::smatch extraByteMatch;
	std::regex_match (thisLine, extraByteMatch, reg);
	
	if (!extraByteMatch.ready())
	{
		handle = -1;
		return;
	}

	if (extraByteMatch.empty())
	{
		spr->byte_count = 0;
		spr->extra_byte_count = 0;
		return;
	}

	int num (parseHexString(extraByteMatch[1]));
	int numExtra (parseHexString(extraByteMatch[2]));

	if (num > 12 || numExtra > 12)
	{
		handle = -1;
		return;
	}
	else
	{
		spr->byte_count = num;
		spr->extra_byte_count = numExtra;
		return;
	}
}
