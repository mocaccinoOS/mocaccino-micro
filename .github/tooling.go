package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"strings"
	"sync"

	"github.com/google/go-containerregistry/pkg/crane"
)

type opData struct {
	FinalRepo string
}

type resultData struct {
	Package Package
	Exists  bool
}

func metaWorker(i int, wg *sync.WaitGroup, c <-chan Package, o opData) error {
	defer wg.Done()

	for p := range c {
		tmpdir, err := ioutil.TempDir(os.TempDir(), "ci")
		checkErr(err)
		unpackdir, err := ioutil.TempDir(os.TempDir(), "ci")
		checkErr(err)
		RunSH("unpack", fmt.Sprintf("TMPDIR=%s XDG_RUNTIME_DIR=%s luet util unpack %s %s", tmpdir, tmpdir, p.ImageMetadata(o.FinalRepo), unpackdir))
		RunSH("move", fmt.Sprintf("mv %s/* build/", unpackdir))
		checkErr(err)
		os.RemoveAll(tmpdir)
		os.RemoveAll(unpackdir)
	}
	return nil
}

func buildWorker(i int, wg *sync.WaitGroup, c <-chan Package, o opData, results chan<- resultData) error {
	defer wg.Done()

	for p := range c {
		fmt.Println("Checking", p)
		results <- resultData{Package: p, Exists: p.ImageAvailable(o.FinalRepo)}
	}
	return nil
}

func main() {
	finalRepo := os.Getenv("FINAL_REPO")
	packs, err := TreePackages("./packages")
	checkErr(err)

	currentPackage := os.Getenv("CURRENT_PACKAGE")

	if currentPackage != "" {
		for _, p := range packs.Packages {
			if p.EqualSV(currentPackage) && !p.ImageAvailable(finalRepo) {
				fmt.Println("Building", p.String())
				checkErr(RunSH("build", fmt.Sprintf("./.github/build.sh %s", p.String())))
			}
		}
		os.Exit(0)
	}

	all := make(chan Package)
	wg := new(sync.WaitGroup)

	for i := 0; i < 1; i++ {
		wg.Add(1)
		go metaWorker(i, wg, all, opData{FinalRepo: finalRepo})
	}

	for _, p := range packs.Packages {
		all <- p
	}
	close(all)
	wg.Wait()
}

func checkErr(err error) {
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}

func RunSHOUT(stepName, bashFragment string) ([]byte, error) {
	cmd := exec.Command("sh", "-s")
	cmd.Stdin = strings.NewReader(bashWrap(bashFragment))

	cmd.Env = os.Environ()
	//	log.Printf("Running in background: %v", stepName)

	return cmd.CombinedOutput()
}

func RunSH(stepName, bashFragment string) error {
	cmd := exec.Command("sh", "-s")
	cmd.Stdin = strings.NewReader(bashWrap(bashFragment))
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Env = os.Environ()
	log.Printf("Running: %v (%v)", stepName, bashFragment)

	return cmd.Run()
}

func bashWrap(cmd string) string {
	return `
set -o errexit
set -o nounset
` + cmd + `
`
}

type SearchResult struct {
	Packages []Package
}

type Package struct {
	Name, Category, Version, Path string
}

func TreePackages(treedir string) (searchResult SearchResult, err error) {
	var res []byte
	res, err = RunSHOUT("tree", fmt.Sprintf("luet tree pkglist --tree %s --output json", treedir))
	if err != nil {
		fmt.Println(string(res))
		return
	}
	json.Unmarshal(res, &searchResult)
	return
}

func imageAvailable(image string) bool {
	_, err := crane.Digest(image)
	return err == nil
}

func (p Package) String() string {
	return fmt.Sprintf("%s/%s@%s", p.Category, p.Name, p.Version)
}

func (p Package) Image(repository string) string {
	// ${name}-${category}-${version//+/-}
	return fmt.Sprintf("%s:%s-%s-%s", repository, p.Name, p.Category, strings.ReplaceAll(p.Version, "+", "-"))
}

func (p Package) ImageMetadata(repository string) string {
	// ${name}-${category}-${version//+/-}
	return fmt.Sprintf("%s.metadata.yaml", p.Image(repository))
}

func (p Package) ImageAvailable(repository string) bool {
	return imageAvailable(p.Image(repository))
}

func (p Package) Equal(pp Package) bool {
	if p.Name == pp.Name && p.Category == pp.Category && p.Version == pp.Version {
		return true
	}
	return false
}

func (p Package) EqualS(s string) bool {
	if s == fmt.Sprintf("%s/%s", p.Category, p.Name) {
		return true
	}
	return false
}

func (p Package) EqualSV(s string) bool {
	if s == fmt.Sprintf("%s/%s@%s", p.Category, p.Name, p.Version) {
		return true
	}
	return false
}

func (p Package) EqualNoV(pp Package) bool {
	if p.Name == pp.Name && p.Category == pp.Category {
		return true
	}
	return false
}

func (s SearchResult) FilterByCategory(cat string) SearchResult {
	new := SearchResult{Packages: []Package{}}

	for _, r := range s.Packages {
		if r.Category == cat {
			new.Packages = append(new.Packages, r)
		}
	}
	return new
}

func (s SearchResult) FilterByName(name string) SearchResult {
	new := SearchResult{Packages: []Package{}}

	for _, r := range s.Packages {
		if !strings.Contains(r.Name, name) {
			new.Packages = append(new.Packages, r)
		}
	}
	return new
}
