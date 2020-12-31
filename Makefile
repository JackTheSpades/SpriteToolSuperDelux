CXXFLAGS += -std=c++17 -Wl,--gc-sections -ffunction-sections -fdata-sections
CXXFLAGS += -s -O2 -Wall --std=c++17 -Wno-format
LDFLAGS += -ldl

SOURCES = $(wildcard src/*.cpp) $(wildcard src/MeiMei/*.cpp) src/json/base64.cpp

OBJECTS = $(patsubst %.cpp,%.o,$(SOURCES)) src/asar/asardll.o

pixi: $(OBJECTS)
	$(CXX) -o $@ $^ $(LDFLAGS) $(CXXFLAGS)

clean:
	rm -f pixi $(OBJECTS)

all: pixi
