#include "map16.h"
#include "file_io.h"
#include "structs.h"

#include <algorithm>
#include <span>

size_t find_free_map(const map16* const map, size_t map_size, size_t count) {
    if (count == 0)
        return 0;

    for (size_t i = 0; i < map_size - count; i++) {
        std::span span{map + i, count};
        if (std::all_of(span.begin(), span.end(), [](const map16& m) { return m.empty(); })) {
            return i;
        }
    }
    return static_cast<size_t>(-1);
}

void read_map16(map16* map, const char* file) {
    auto* src = (map16*)read_all(file, false, MAP16_SIZE * sizeof(map16));
    memcpy(map, src, MAP16_SIZE * sizeof(map16));
    delete[] src;
}
