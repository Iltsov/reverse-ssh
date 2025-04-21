ifdef RS_SHELL
LDFLAGS := $(LDFLAGS) -X 'main.defaultShell=$(RS_SHELL)'
endif

ifdef RS_PUB
PUB_KEY := $(shell cat $(RS_PUB))
LDFLAGS := $(LDFLAGS) -X 'main.authorizedKey=$(PUB_KEY)'
endif

ifdef PRIV_KEY
PRIVATE_KEY := $(shell cat $(PRIV_KEY) | sed -e 's/$$/\\n/' | tr -d '\n')
LDFLAGS := $(LDFLAGS) -X 'main.privateKey=$(PRIVATE_KEY)'
endif

RS_PASS ?= $(shell hexdump -n 8 -e '2/4 "%08x"' /dev/urandom)
LDFLAGS := $(LDFLAGS) -X 'main.localPassword=$(RS_PASS)'

ifdef LUSER
LDFLAGS := $(LDFLAGS) -X 'main.LUSER=$(LUSER)'
endif

ifdef LHOST
LDFLAGS := $(LDFLAGS) -X 'main.LHOST=$(LHOST)'
endif

ifdef LPORT
LDFLAGS := $(LDFLAGS) -X 'main.LPORT=$(LPORT)'
endif

ifdef BPORT
LDFLAGS := $(LDFLAGS) -X 'main.BPORT=$(BPORT)'
endif

ifdef NOCLI
LDFLAGS := $(LDFLAGS) -X 'main.NOCLI=$(NOCLI)'
endif

.PHONY: clean
clean:
	rm -f bin/*reverse-ssh*

.PHONY: build
build: clean
	CGO_ENABLED=0 					go build -ldflags="$(LDFLAGS) -s -w" -o bin/ .

.PHONY: build-all
build-all: clean
	CGO_ENABLED=0 GOARCH=arm64	GOOS=linux	go build -ldflags="$(LDFLAGS) -s -w" -o bin/reverse-ssh-armv8-x64 .
	CGO_ENABLED=0 GOARCH=arm	GOOS=linux	go build -ldflags="$(LDFLAGS) -s -w" -o bin/reverse-ssh-armv7-x86 .
	CGO_ENABLED=0 GOARCH=amd64	GOOS=linux	go build -ldflags="$(LDFLAGS) -s -w" -o bin/reverse-sshx64 .
	CGO_ENABLED=0 GOARCH=386	GOOS=linux	go build -ldflags="$(LDFLAGS) -s -w" -o bin/reverse-sshx86 .
	CGO_ENABLED=0 GOARCH=amd64	GOOS=windows	go build -ldflags="$(LDFLAGS) -s -w" -o bin/reverse-sshx64.exe .
	CGO_ENABLED=0 GOARCH=386	GOOS=windows	go build -ldflags="$(LDFLAGS) -s -w" -o bin/reverse-sshx86.exe .

.PHONY: compressed
compressed: build
	@for f in $(shell ls bin); do upx -o "bin/upx_$${f}" "bin/$${f}"; done

.PHONY: compressed-all
compressed-all: build-all
	@for f in $(shell ls bin); do upx -o "bin/upx_$${f}" "bin/$${f}"; done
