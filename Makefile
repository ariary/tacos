before.build:
	go mod download && go mod vendor

build.tacos:
	@echo "build in ${PWD}";go build cmd/tacos/tacos.go

build.tacos.static:
	@echo "build in ${PWD}";CGO_ENABLED=0 go build cmd/tacos/tacos.go

build.tacos.32bit:
	@echo "build in ${PWD}";GOARCH=386 go build cmd/tacos/tacos.go

build.tacos.windows:
	@echo "build in ${PWD}";GOOS=windows go build cmd/tacos/tacos.go
	
build.tacos.image:
	docker build -f ./Dockerfiles/Dockerfile-tacos -t ariary/tacos ./Dockerfiles

build.tacos-reverse.image:
	docker build -f ./Dockerfiles/Dockerfile-reverse -t ariary/tacos-reverse .