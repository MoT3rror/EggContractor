MAKEFLAGS += -j4

BUILD = $(shell date -u +%Y-%m-%d).$(shell git rev-parse --short=8 HEAD 2>/dev/null || echo 'snapshot')
GITCOMMIT = $(shell git rev-parse HEAD 2>/dev/null || echo 'master')

.PHONY: all dev go protobuf webpack webpack-dev postcss postcss-dev fmt serve serve-prod docker clean

all: go webpack postcss

dev: go webpack-dev postcss-dev
	rm -f public/egginc public/egginc-extras
	ln -sf ../static/egginc public/egginc
	ln -sf ../static/egginc-extras public/egginc-extras

go: protobuf
	GOFLAGS=-trimpath go build -ldflags "-X github.com/fanaticscripter/EggContractor/web.AppBuild=$(BUILD) -X github.com/fanaticscripter/EggContractor/web.GitCommit=$(GITCOMMIT)"

protobuf:
	protoc --proto_path=. --go_out=paths=source_relative:. api/egginc.proto
	protoc --proto_path=. --go_out=paths=source_relative:. solo/pb/solo.proto
	gofumpt -w api/egginc.pb.go solo/pb/solo.pb.go

webpack:
	yarn webpack --config webpack.prod.js

webpack-dev:
	yarn webpack --config webpack.dev.js

postcss:
	yarn postcss --env=production css/app.css -o static/app.css

postcss-dev:
	yarn postcss --env=development css/app.css -o public/app.css

fmt:
	gofumpt -w .
	clang-format -i api/egginc.proto solo/pb/solo.proto
	yarn prettier -w $$(git ls-files | grep -E '(\.html|\.js|\.css|\.vue)$$' | grep -Ev '(templates|demo)/')

fmt-changed:
	yarn prettier -w $$(git diff --diff-filter=AM --name-only HEAD | grep -E '(\.html|\.js|\.css|\.vue)$$' | grep -Ev '(templates|demo)/')

# Hot-reloading server based on entr(1).
serve:
	while true; do { echo EggContractor; find templates; find static; } | entr -dr ./EggContractor serve --dev; [ $$? = 2 ] || break; done

# Same as serve, except serving the production version.
serve-prod:
	while true; do { echo EggContractor; find templates; find static; } | entr -dr ./EggContractor serve; [ $$? = 2 ] || break; done

docker:
	docker build -t fanaticscripter/eggcontractor --build-arg BUILD=$(BUILD) --build-arg GIT_COMMIT=$(GITCOMMIT) .

clean:
	@$(RM) EggContractor static/*.*.js static/*.*.css static/manifest.*.json
	@$(RM) -r node_modules/.cache/webpack
