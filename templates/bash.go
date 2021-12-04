package main

/*
#cgo pkg-config: bash
#include "builtins.h"
#include <string.h>
#include <stdlib.h>

typedef struct {
	char *name;
	sh_builtin_func_t *function;
	int flags;
	char * const *long_doc;
	const char *short_doc;
	char *handle;
} go_builtin;


typedef int sh_builtin_func_t (WORD_LIST*);

extern go_builtin* (*external_lookup_builtin)(char*);
extern int (builtin_func_wrapper)(WORD_LIST*);

static int go_builtins_sz = 0;
static go_builtin *go_builtins = 0;

static inline go_builtin* go_lookup_builtin(char *name) {
	for (go_builtin *b = go_builtins; b && b->name; b++) {
		if (!strcmp(name, b->name)) {
			return b;
		}
	}
	return 0;
}


extern struct builtin __MODULE___struct;


static inline void go_add_builtin(go_builtin b) {
    go_builtins_sz++;
    go_builtins = realloc(go_builtins, sizeof(go_builtin) * (go_builtins_sz + 1));
    go_builtins[go_builtins_sz-1] = b;
    go_builtins[go_builtins_sz] = (go_builtin){};
}

static inline void go_del_builtin(char *name) {
    for (go_builtin *b = go_builtins; b && b->name; b++) {
        if (!strcmp(name, b->name)) {
            for (go_builtin *b2 = b+1; b && b->name; b2++, b++) {
                *b = *b2;
            }
            go_builtins_sz--;
            return;
        }
    }
}

static inline void go_init() {
  external_lookup_builtin = &go_lookup_builtin;
}

*/
import "C"

import (
	"fmt"
	"os"
	"strings"
	"sync"

	"github.com/johnstarich/goenable/cutils"
	"github.com/k0kubun/pp"
)

var (
	// mutex to guard the fns map
	mu  sync.Mutex
	fns = map[string]Function{}
)

func init() {
	C.__MODULE___struct.name = C.CString(Name())
	longDoc := strings.Split(Usage(), "\n")
	C.__MODULE___struct.long_doc = (**C.char)(cutils.CStringArray(longDoc))
	C.__MODULE___struct.short_doc = C.CString(UsageShort())
}

//export __MODULE___builtin
func __MODULE___builtin(list *C.WORD_LIST) C.int {
	args := make([]string, 0)
	Args := []string{}
	MODE := ``
	for list != nil {
		args = append(args, C.GoString(list.word.word))
		list = list.next
	}
	for i, I := range args {
		if i == 0 {
			MODE = fmt.Sprintf(`%s`, I)
		} else {
			Args = append(Args, I)
		}
	}

	fmt.Fprintf(os.Stdout, "Builtin Running>  MODE=%s | %d args: \"%s\"\n", MODE, len(Args), pp.Sprintf(strings.Join(Args, ` `)))
	result := C.int(0)
	fmt.Fprintf(os.Stdout, "Builtin Ran>   result: %d\n", result)
	return result
}

// Unregister removes the function associated with the provided name.
func Unregister(name string) {
	mu.Lock()
	defer mu.Unlock()
	C.go_del_builtin(C.CString(name))
	delete(fns, name)
}

// Function represents a Go function that can be used as a bash builtin.
type Function func(args ...string) (status int)

//export builtin_func_wrapper
/*
func builtin_func_wrapper(wl *C.WORD_LIST) C.int {
	args := make([]string, 0, 4)
	for ; wl != nil; wl = wl.next {
		args = append(args, C.GoString(wl.word.word))
	}
	fn := lookup(C.GoString(C.current_builtin.name))
	return C.int(fn(args...))
}
*/

func lookup(name string) Function {
	mu.Lock()
	defer mu.Unlock()
	return fns[name]
}

//export __MODULE___builtin_load
func __MODULE___builtin_load(cName *C.char) C.int {
	name := C.GoString(cName)
	fmt.Fprintf(os.Stdout, "Builtin Loading>  name: \"%s\"\n", name)
	//if Load(name) {
	//	return 1
	//}
	loaded := func() {
		fmt.Fprintf(os.Stdout, "Builtin Loaded>  name: \"%s\"\n", name)
	}
	defer loaded()
	//	C.go_add_builtin(C.go_builtin{name: C.CString(name), function: (*C.sh_builtin_func_t)(C.builtin_func_wrapper)})
	return 1
}

//export __MODULE___builtin_unload
func __MODULE___builtin_unload() {
	fmt.Println(`unloading.........`)
	Unload()
	fmt.Println(`unloaded.........`)
}
