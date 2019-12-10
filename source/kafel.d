/*
   Kafel
   -----------------------------------------
   Copyright 2016 Google Inc. All Rights Reserved.
   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at
     http://www.apache.org/licenses/LICENSE-2.0
   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

/+
#include <linux/filter.h>
#include <stdint.h>
#include <stdio.h>
+/

version(Posix):

import core.stdc.stdio : FILE;
import symmetry.sildoc;


extern(C) @nogc nothrow:

alias sock_fprog = SockFilterProgram;
extern struct SockFilterProgram;

/+
struct SockFilterProgram
{
	int len;
	SockFilter* filter;
}
+/

struct kafel_ctxt {}

alias kafel_ctxt_t_const = const(kafel_ctxt)*;
alias kafel_ctxt_t = kafel_ctxt*;


struct KafelContext
{
	kafel_ctxt_t handle;

	static KafelContext create()
	{
		KafelContext ret;
		ret.handle = kafel_ctxt_create();
		return ret;
	}

	void dispose()
	{
		kafel_ctxt_destroy(&this.handle);
	}

	void setInputString(string s)
	{
		import std.string : toStringz;
		kafel_set_input_string(this.handle,s.toStringz);
	}

	void setInputFile(string filename)
	{
		import std.stdio : File;
		auto file = File(filename,"rb");
		kafel_set_input_file(this.handle,file.getFP());
	}

	void setTargetArch(uint targetArch)
	{
		kafel_set_target_arch(this.handle,targetArch);
	}

	void addIncludeSearchPath(string path)
	{
		import std.string : toStringz;
		kafel_add_include_search_path(this.handle,path.toStringz);
	}

	sock_fprog* compile()
	{
		import std.string : toStringz, fromStringz;
		import std.exception : enforce;
		import std.format : format;
		sock_fprog* ret;
		enforce(kafel_compile(this.handle,ret) == 0,
			   format!"compilation failed : %s"(kafel_error_msg(this.handle).fromStringz));
		return ret;
	}

	static sock_fprog* compileFile(string filename)
	{
		import std.stdio: File;
		auto file = File(filename,"rb");
		import std.string : toStringz, fromStringz;
		import std.exception : enforce;
		import std.format : format;
		sock_fprog* ret;
		enforce(kafel_compile_file(file.getFP(),ret) == 0, "compilation failed");
		return ret;
	}

	static sock_fprog* compileString(string policy)
	{
		import std.string : toStringz, fromStringz;
		import std.exception : enforce;
		import std.format : format;
		sock_fprog* ret;
		enforce(kafel_compile_string(policy.toStringz,ret) == 0, "compilation failed");
		return ret;
	}
}




@SILdoc("Creates and initializes a kafel context")
kafel_ctxt_t kafel_ctxt_create();

@SILdoc("Destroys kafel context pointed to by ctxt and releases related resources")
void kafel_ctxt_destroy(kafel_ctxt_t* ctxt);

@SILdoc("Sets input source for ctxt to file
	- Caller is responsible for closing the file stream after compilation")
void kafel_set_input_file(kafel_ctxt_t ctxt, FILE* file);

@SILdoc("Sets input source for ctxt to a NULL-terminated string")
void kafel_set_input_string(kafel_ctxt_t ctxt, const(char)* string);

@SILdoc("Sets compilation target architecture for ctxt to target_arch
		- target_arch must be a supported AUDIT_ARCH_* value (see <linux/audit.h>)")
void kafel_set_target_arch(kafel_ctxt_t ctxt, uint target_arch);

@SILdoc("Adds path to list of include search paths for ctxt")
void kafel_add_include_search_path(kafel_ctxt_t ctxt, const(char)* path);

@SILdoc("Compiles policy using ctxt as context.
 * Stores resulting code in prog.
 * Allocates memory for BPF code, caller is responsible freeing prog->filter
 *   once it does not need it. kafel_ctxt_destroy DOES NOT release this resource
 * Input source MUST be set first with kafel_set_input_string or
 *   kafel_set_input_file
 *
 * Returns 0 on success")
int kafel_compile(kafel_ctxt_t ctxt, sock_fprog* prog);

@SILdoc("Convenience function to compile a policy from a file
 * Does not preserve detailed error information
 * Same as for kafel_compile caller is repsonsible for freeing prog->filter
 * Caller is also responsible for closing the file stream
 *
 * Returns 0 on success")
int kafel_compile_file(FILE* file, sock_fprog* prog);

@SILdoc("Convenience function to compile a policy from a NULL-terminated string
 * Does not preserve detailed error information
 * Same as for kafel_compile caller is repsonsible for freeing prog->filter
 *
 * Returns 0 on success")
int kafel_compile_string(const(char)* source, sock_fprog* prog);

@SILdoc("Returns textual description of the error, if compilation using ctxt failed")
const(char)* kafel_error_msg(kafel_ctxt_t_const ctxt);
