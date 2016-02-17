#ifndef _PBMSGS_H
#define _PBMSGS_H

#include <pb-machinekit.h>
#include <nanopb/pb_decode.h>
#include <nanopb/pb_encode.h>

// the message type descriptor
typedef struct {
    uint32_t msgid;
    int32_t encoded_size;
    const char *name;
    size_t size;
    const pb_field_t *fields;
    void *user;
} msginfo_t;

#define PB_MSG(id, size, name) {				\
	id,							\
	    size,						\
	    # name,						\
	    sizeof(PB_MSG_ ## id),				\
	    name ## _fields,					\
	    NULL,						\
	    },

#define PB_MSGINFO_DELIMITER {0, -1, NULL, 0, NULL, NULL}
#define PB_MSGID

#include <message.npb.h>
#include <value.npb.h>
#include <test.npb.h>


#endif // _PBMSGS_H
