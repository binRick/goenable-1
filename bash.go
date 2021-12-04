package main

/*
#cgo pkg-config: bash
#include "builtins.h"
extern struct builtin goenable5_struct;
*/
import "C"

import (
	"fmt"
	"os"
	"strings"

	"github.com/johnstarich/goenable/cutils"
	"github.com/k0kubun/pp"
)

func init() {
	C.goenable5_struct.name = C.CString(Name())
	longDoc := strings.Split(Usage(), "\n")
	C.goenable5_struct.long_doc = (**C.char)(cutils.CStringArray(longDoc))
	C.goenable5_struct.short_doc = C.CString(UsageShort())
}

//export goenable5_builtin
func goenable5_builtin(list *C.WORD_LIST) C.int {
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

//export goenable5_builtin_load
func goenable5_builtin_load(cName *C.char) C.int {
	name := C.GoString(cName)
	fmt.Fprintf(os.Stdout, "Builtin Loading>  name: \"%s\"\n", name)
	//if Load(name) {
	//	return 1
	//}
	loaded := func() {
		fmt.Fprintf(os.Stdout, "Builtin Loaded>  name: \"%s\"\n", name)
	}
	defer loaded()
	return 1
}

//export goenable5_builtin_unload
func goenable5_builtin_unload() {
	fmt.Println(`unloading.........`)
	Unload()
	fmt.Println(`unloaded.........`)
}
