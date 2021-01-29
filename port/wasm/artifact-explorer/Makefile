MAKEFLAGS += -j4

.PHONY: all init dist html wasm webpack postcss static clean serve

all: dist

init:
	yarn install

dist: html static
	../_tools/build.py dist --additional static

html: webpack postcss
	cp -f "$$(go env GOROOT)/misc/wasm/wasm_exec.js" dist
	../_tools/build.py html

wasm:
	../_tools/build.py wasm

webpack: wasm
	yarn webpack

postcss:
	yarn postcss --env=production src/app.css -o dist/app.css

static:
	rm -rf dist/static
	mkdir -p dist/static
	ln ../../../static/egginc/afx_*.png ../../../static/egginc/icon_help.png dist/static

clean:
	@$(RM) -r dist/index.html dist/*.*.js dist/wasm_exec.js dist/*.*.css dist/*.*.wasm dist/manifest.*.json static

serve:
	cd dist && npx serve