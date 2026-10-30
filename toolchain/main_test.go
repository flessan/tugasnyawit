package main

import (
	"strings"
	"testing"
)

func mustContain(t *testing.T, out string, wants ...string) {
	t.Helper()
	for _, want := range wants {
		if !strings.Contains(out, want) {
			t.Errorf("output missing %q\ngot:\n%s", want, out)
		}
	}
}

func mustNotContain(t *testing.T, out string, bads ...string) {
	t.Helper()
	for _, bad := range bads {
		if strings.Contains(out, bad) {
			t.Errorf("output should not contain %q\ngot:\n%s", bad, out)
		}
	}
}

func TestKeywordAndFunctionMapping(t *testing.T) {
	out := transpile("tandan panenUtama() { hutan x; buzzer(\"hi\"); setor 0; }")
	mustContain(t, out, "int main()", "void x;", "sawit_buzzer(", "return 0;")
}

func TestDoWhileMapping(t *testing.T) {
	out := transpile("pidato { setor 0; } janji (sesuai);")
	mustContain(t, out, "do {", "} while (true);")
}

func TestCommentsAndStringsPreserved(t *testing.T) {
	src := "// tandan panenUtama buzzer\n" +
		"tandan panenUtama() {\n" +
		"    buzzer(\"tandan panenUtama buzzer\\n\");\n" +
		"    setor 0;\n}\n"
	out := transpile(src)
	mustContain(t, out,
		"// tandan panenUtama buzzer",
		"\"tandan panenUtama buzzer\\n\"",
		"int main()",
	)
}

func TestIdentifiersNotSplit(t *testing.T) {
	out := transpile("tandan tandananku = 1;")
	mustContain(t, out, "int tandananku")
}

func TestConstructorKeywordsRemoved(t *testing.T) {
	out := transpile("tanam() { tebang(); }")
	mustNotContain(t, out, "constructor", "destructor")
}

func TestAllocatorMappedToRuntime(t *testing.T) {
	out := transpile("hutan *p = beli(8); jual(p);")
	mustContain(t, out, "sawit_beli(8)", "sawit_jual(p)")
	mustNotContain(t, out, "malloc", "free(")
}

func TestUnterminatedStringDoesNotPanic(t *testing.T) {
	defer func() {
		if r := recover(); r != nil {
			t.Fatalf("transpile panicked on unterminated string: %v", r)
		}
	}()
	_ = transpile("buzzer(\"abc\\")
}

func TestUnterminatedCommentDoesNotPanic(t *testing.T) {
	defer func() {
		if r := recover(); r != nil {
			t.Fatalf("transpile panicked on unterminated comment: %v", r)
		}
	}()
	_ = transpile("/* unclosed")
}

func TestTranspileAlwaysIncludesRuntime(t *testing.T) {
	out := transpile("")
	mustContain(t, out, `#include "sawit_runtime.h"`)
}
