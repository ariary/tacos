before.build:
	go mod download && go mod vendor

build.tacos:
	@echo "build in ${PWD}";go build cmd/tacos/tacos.go