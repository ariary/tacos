before.build:
	go mod download && go mod vendor

build.tacos:
	@echo "build in ${PWD}";go build cmd/tacos/tacos.go

build.tacos.windows:
	@echo "build in ${PWD}";GOOS=windows go build cmd/tacos/tacos.go
	
build.tacos.image:
	docker build . -t ariary/tacos