BASE := $(subst -, ,$(notdir ${CURDIR}))
ORG  := $(word 1, ${BASE})
REPO := $(word 2, ${BASE})
IMG  := quay.io/${ORG}/${REPO}
GEOMESA_VERSION := 1.2.5
GEOMESA_DIST_TARBALL := geomesa-dist-${GEOMESA_VERSION}-bin.tar.gz
GEOMESA_RUNTIME := geomesa-accumulo-distributed-runtime-${GEOMESA_VERSION}.jar

.cache/${GEOMESA_DIST_TARBALL}:
	mkdir -p .cache
&& cd .cache \
&& curl -L -C - -O "http://repo.locationtech.org/content/repositories/geomesa-releases/org/locationtech/geomesa/geomesa-dist/${GEOMESA_VERSION}/${GEOMESA_DIST_TARBALL}"

${GEOMESA_RUNTIME}: .cache/${GEOMESA_DIST_TARBALL}
	tar -zx --strip-components=3 \
		-f .cache/${GEOMESA_DIST_TARBALL} \
    geomesa-${GEOMESA_VERSION}/dist/accumulo/${GEOMESA_RUNTIME}
	@touch -am ${GEOMESA_RUNTIME}

build: ${GEOMESA_RUNTIME}
	docker build -t ${IMG}:latest	.

publish: build
	docker push ${IMG}:latest
	if [ "${TAG}" != "" -a "${TAG}" != "latest" ]; then docker tag ${IMG}:latest ${IMG}:${TAG} && docker push ${IMG}:${TAG}; fi

test: build
	echo "TODO: make test for the container"
