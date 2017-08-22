#ifdef __powerpc__

#define CRC32_FUNCTION crc32c_vpmsum
#define __CRC32_FUNCTION __crc32c_vpmsum

#define POWER8_INTRINSICS
#define CRC_TABLE

#include "crc32c_constants.h"

#include "vec_crc32.ic"
#include "vec_crc32_wrapper.ic"

#endif

