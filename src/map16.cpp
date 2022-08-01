#include "map16.h"
#include "file_io.h"
#include "structs.h"

size_t find_free_map(const map16 *map, size_t map_size, size_t count) {
    if (count == 0)
        return 0;

    char *zero = new char[count * 8];
    memset(zero, 0, count * 8);

    for (int i = 0; i < map_size; i++) {
        if (!memcmp(zero, (char *)(map + i), 8)) {
            delete[] zero;
            return i;
        }
    }
    delete[] zero;
    return static_cast<size_t>(-1);
}

void read_map16(map16 *map, const char *file) {
    auto *src = (map16 *)read_all(file, false, MAP16_SIZE * sizeof(map16));
    memcpy(map, src, MAP16_SIZE * sizeof(map16));
    delete[] src;
}
