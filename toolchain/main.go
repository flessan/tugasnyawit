package main

import (
	_ "embed"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"unicode"
)

//go:embed sawit_runtime.h
var runtimeHeader []byte

var keywords = map[string]string{
	"tandan": "int", "pertalite": "float", "pertamax": "double", "buah": "char",
	"pelepah": "std::string", "panen": "bool", "rodok": "bool", "hutan": "void",
	"kalauPanen": "if", "kalauTidak": "else", "rapat": "switch", "kasus": "case",
	"muter": "for", "selama": "while", "pidato": "do", "janji": "while",
	"pulang": "break", "lanjutPidato": "continue", "lanjutOmonOmon": "continue",
	"setor": "return", "perkebunan": "class", "kopdes": "struct",
	"jalanProduksi": "public", "lahanPribadi": "private", "lahanPejabat": "protected",
	"wilayahKebun": "namespace", "imporBibit": "#include", "RUU": "#define",
	"PerPres": "#define", "bakarHutan": "new", "gusur": "delete",
	"sesuai": "true", "hoaks": "false",
	"relokasi": "goto", "panenUtama": "main",
}

var functions = map[string]string{
	"buzzer": "sawit_buzzer", "bungkam": "sawit_bungkam", "bukaSuara": "sawit_buka_suara",
	"demoMasyarakat": "sawit_demo_masyarakat", "pajak": "sawit_pajak", "MBG": "sawit_mbg",
	"nyawit": "sawit_nyawit", "cair": "sawit_cair", "beli": "sawit_beli", "jual": "sawit_jual",
	"bersihkanLayar": "sawit_bersihkan_layar",
}

var buildAliases = map[string]string{
	"AMDAL.txt": "CMakeLists.txt", "SuratIzinTanam": "Makefile", "ProposalKebun": "meson.build",
	"ProyekStrategisNasional": "BUILD.bazel", "IzinTambang.txt": "conanfile.txt", "antekModal.json": "vcpkg.json",
}

func isIdentStart(r rune) bool { return r == '_' || unicode.IsLetter(r) }
func isIdentPart(r rune) bool  { return r == '_' || unicode.IsLetter(r) || unicode.IsDigit(r) }

func transpile(source string) string {
	var out strings.Builder
	out.WriteString("#include \"sawit_runtime.h\"\n\n")
	runes := []rune(source)
	for i := 0; i < len(runes); {
		if runes[i] == '/' && i+1 < len(runes) && runes[i+1] == '/' {
			start := i
			i += 2
			for i < len(runes) && runes[i] != '\n' {
				i++
			}
			out.WriteString(string(runes[start:i]))
			continue
		}
		if runes[i] == '/' && i+1 < len(runes) && runes[i+1] == '*' {
			start := i
			i += 2
			for i+1 < len(runes) && !(runes[i] == '*' && runes[i+1] == '/') {
				i++
			}
			if i+1 < len(runes) {
				i += 2
			} else {
				i = len(runes)
			}
			out.WriteString(string(runes[start:i]))
			continue
		}
		if runes[i] == '"' || runes[i] == '\'' {
			quote, start := runes[i], i
			i++
			for i < len(runes) {
				if runes[i] == '\\' {
					i += 2
					continue
				}
				i++
				if runes[i-1] == quote {
					break
				}
			}
			if i > len(runes) {
				i = len(runes)
			}
			out.WriteString(string(runes[start:i]))
			continue
		}
		if isIdentStart(runes[i]) {
			start := i
			i++
			for i < len(runes) && isIdentPart(runes[i]) {
				i++
			}
			word := string(runes[start:i])
			if replacement, ok := keywords[word]; ok {
				word = replacement
			} else if replacement, ok := functions[word]; ok {
				word = replacement
			}
			out.WriteString(word)
			continue
		}
		out.WriteRune(runes[i])
		i++
	}
	return out.String()
}

func compilerFor(source, requested string) (string, error) {
	if requested != "" {
		return requested, nil
	}
	candidates := []string{"gcc", "clang", "g++", "clang++"}
	if strings.HasSuffix(source, ".sawitpp") {
		candidates = []string{"g++", "clang++", "gcc", "clang"}
	}
	for _, candidate := range candidates {
		if path, err := exec.LookPath(candidate); err == nil {
			return path, nil
		}
	}
	return "", errors.New("compiler tidak ditemukan; pasang GCC/Clang/MSVC atau gunakan --compiler")
}

func compile(source, output, requested string, keep bool) error {
	compiler, err := compilerFor(source, requested)
	if err != nil {
		return err
	}
	data, err := os.ReadFile(source)
	if err != nil {
		return err
	}
	tmpDir, err := os.MkdirTemp(filepath.Dir(source), ".sawit-build-")
	if err != nil {
		return err
	}
	if !keep {
		defer os.RemoveAll(tmpDir)
	}
	ext := ".c"
	if strings.HasSuffix(source, ".sawitpp") {
		ext = ".cpp"
	}
	generated := filepath.Join(tmpDir, "program"+ext)
	if err := os.WriteFile(generated, []byte(transpile(string(data))), 0644); err != nil {
		return err
	}
	if err := os.WriteFile(filepath.Join(tmpDir, "sawit_runtime.h"), runtimeHeader, 0644); err != nil {
		return err
	}
	if output == "" {
		output = strings.TrimSuffix(source, filepath.Ext(source))
		if runtime.GOOS == "windows" {
			output += ".exe"
		}
	}
	cmd := exec.Command(compiler, generated, "-I", tmpDir, "-o", output)
	cmd.Stdout, cmd.Stderr = os.Stdout, os.Stderr
	return cmd.Run()
}

func runProgram(source, compiler string, args []string) error {
	suffix := ""
	if runtime.GOOS == "windows" {
		suffix = ".exe"
	}
	tmp, err := os.CreateTemp(filepath.Dir(source), ".sawit-run-*"+suffix)
	if err != nil {
		return err
	}
	output := tmp.Name()
	tmp.Close()
	os.Remove(output)
	defer os.Remove(output)
	if err := compile(source, output, compiler, false); err != nil {
		return err
	}
	cmd := exec.Command(output, args...)
	cmd.Stdout, cmd.Stderr, cmd.Stdin = os.Stdout, os.Stderr, os.Stdin
	return cmd.Run()
}

func canonicalAMDAL() string {
	binary := "sawit"
	if runtime.GOOS == "windows" {
		binary = "sawit.exe"
	}
	return `cmake_minimum_required(VERSION 3.20)
project(SawitProject C)

set(SAWIT_EXECUTABLE ${CMAKE_CURRENT_SOURCE_DIR}/` + binary + `)
set(SAWIT_SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/src/main.sawit)
set(SAWIT_GENERATED ${CMAKE_CURRENT_BINARY_DIR}/main.c)

add_custom_command(
    OUTPUT ${SAWIT_GENERATED}
    COMMAND ${SAWIT_EXECUTABLE} transpile ${SAWIT_SOURCE} -o ${SAWIT_GENERATED}
    DEPENDS ${SAWIT_SOURCE} ${SAWIT_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/sawit_runtime.h
    VERBATIM
)
add_executable(panen ${SAWIT_GENERATED})
target_include_directories(panen PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
`
}

func initProject(dir string, force bool) error {
	if dir == "" {
		dir = "."
	}
	dir, _ = filepath.Abs(dir)
	marker := filepath.Join(dir, ".sawit-project")
	if _, err := os.Stat(marker); err == nil && !force {
		return errors.New("proyek Sawit sudah ada; gunakan --force")
	}
	for _, sub := range []string{"src", "build"} {
		if err := os.MkdirAll(filepath.Join(dir, sub), 0755); err != nil {
			return err
		}
	}
	mainSource := "imporBibit <stdio.h>\n\ntandan panenUtama() {\n    buzzer(\"Halo dari proyek Sawit!\\n\");\n    setor 0;\n}\n"
	if err := os.WriteFile(filepath.Join(dir, "src", "main.sawit"), []byte(mainSource), 0644); err != nil {
		return err
	}
	if err := os.WriteFile(filepath.Join(dir, "sawit_runtime.h"), runtimeHeader, 0644); err != nil {
		return err
	}
	self, err := os.Executable()
	if err == nil {
		binary := "sawit"
		if runtime.GOOS == "windows" {
			binary = "sawit.exe"
		}
		_ = copyFile(self, filepath.Join(dir, binary))
	}
	if err := os.WriteFile(filepath.Join(dir, "AMDAL.txt"), []byte(canonicalAMDAL()), 0644); err != nil {
		return err
	}
	shim := "cmake_minimum_required(VERSION 3.20)\nproject(SawitProject C)\ninclude(${CMAKE_CURRENT_LIST_DIR}/AMDAL.txt)\n"
	if err := os.WriteFile(filepath.Join(dir, "CMakeLists.txt"), []byte(shim), 0644); err != nil {
		return err
	}
	return os.WriteFile(marker, []byte("Sawit project v0.2\n"), 0644)
}

func copyFile(from, to string) error {
	in, err := os.Open(from)
	if err != nil {
		return err
	}
	defer in.Close()
	out, err := os.Create(to)
	if err != nil {
		return err
	}
	defer out.Close()
	_, err = io.Copy(out, in)
	return err
}

func audit(path string, fix bool) error {
	if path == "" {
		path = "AMDAL.txt"
	}
	data, err := os.ReadFile(path)
	if err != nil {
		return err
	}
	required := []string{"cmake_minimum_required", "project(", "add_custom_command", "add_executable", "target_include_directories"}
	missing := []string{}
	text := string(data)
	for _, item := range required {
		if !strings.Contains(text, item) {
			missing = append(missing, item)
		}
	}
	if len(missing) == 0 {
		fmt.Println("AMDAL.txt: struktur valid.")
	} else {
		fmt.Printf("AMDAL.txt: bagian kurang: %s\n", strings.Join(missing, ", "))
	}
	if fix {
		backup := path + ".bak"
		if err := os.WriteFile(backup, data, 0644); err != nil {
			return err
		}
		if err := os.WriteFile(path, []byte(canonicalAMDAL()), 0644); err != nil {
			return err
		}
		fmt.Printf("AMDAL.txt dirapikan; cadangan: %s\n", backup)
	}
	if len(missing) > 0 && !fix {
		return errors.New("audit menemukan struktur AMDAL yang belum lengkap")
	}
	return nil
}

func option(args []string, name string) string {
	for i := 0; i+1 < len(args); i++ {
		if args[i] == name {
			return args[i+1]
		}
	}
	return ""
}

func sourceArg(args []string) string {
	for i := 0; i < len(args); i++ {
		arg := args[i]
		if arg == "-o" || arg == "--compiler" {
			i++ // lewati nilai opsi
			continue
		}
		if strings.HasPrefix(arg, "-") {
			continue
		}
		return arg
	}
	return ""
}

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: sawit <transpile|build|run|init|audit> ...")
		os.Exit(2)
	}
	command, args := os.Args[1], os.Args[2:]
	var err error
	switch command {
	case "transpile":
		source := sourceArg(args)
		if source == "" {
			err = errors.New("source .sawit wajib diisi")
		} else {
			data, e := os.ReadFile(source)
			err = e
			if err == nil {
				result := transpile(string(data))
				if output := option(args, "-o"); output != "" {
					err = os.WriteFile(output, []byte(result), 0644)
				} else {
					fmt.Print(result)
				}
			}
		}
	case "build":
		source := sourceArg(args)
		if source == "" {
			err = errors.New("source .sawit wajib diisi")
		} else {
			err = compile(source, option(args, "-o"), option(args, "--compiler"), contains(args, "--keep-generated"))
		}
	case "run":
		source := sourceArg(args)
		if source == "" {
			err = errors.New("source .sawit wajib diisi")
		} else {
			programArgs := []string{}
			for i, arg := range args {
				if arg == "--" {
					programArgs = args[i+1:]
					break
				}
			}
			err = runProgram(source, option(args, "--compiler"), programArgs)
		}
	case "init":
		dir := sourceArg(args)
		err = initProject(dir, contains(args, "--force"))
		if err == nil {
			fmt.Printf("Proyek Sawit dibuat di %s\n", dir)
		}
	case "audit":
		path := sourceArg(args)
		err = audit(path, contains(args, "--fix"))
	default:
		err = fmt.Errorf("perintah tidak dikenal: %s", command)
	}
	if err != nil {
		fmt.Fprintln(os.Stderr, "sawit:", err)
		os.Exit(1)
	}
}

func contains(args []string, wanted string) bool {
	for _, arg := range args {
		if arg == wanted {
			return true
		}
	}
	return false
}
