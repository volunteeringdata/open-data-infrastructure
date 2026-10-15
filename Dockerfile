ARG JAVA_VERSION=25
ARG ALPINE_VERSION=3
ARG JENA_VERSION=6.2.0
ARG FUSEKI_SHA1=d3490295a2b95677c1227d25bca8564d40f993a7


# Internal, passed between stages.
## Fuseki
ARG FUSEKI_DIR=/fuseki
ARG FUSEKI_JAR=jena-fuseki-server-${JENA_VERSION}.jar
## Java
ARG JAVA_MINIMAL=/opt/java-minimal


## ---- Stage: download Fuseki JAR
FROM alpine:${ALPINE_VERSION} AS fuseki-download

ARG JENA_VERSION
ARG FUSEKI_DIR
ARG FUSEKI_SHA1
ARG FUSEKI_JAR
ARG REPO=https://repo1.maven.org/maven2
ARG FUSEKI_JAR_URL=${REPO}/org/apache/jena/jena-fuseki-server/${JENA_VERSION}/${FUSEKI_JAR}

RUN apk add --no-cache curl

WORKDIR ${FUSEKI_DIR}

RUN curl -fsSL "$FUSEKI_JAR_URL" -o "$FUSEKI_JAR" && \
    echo "${FUSEKI_SHA1}  ${FUSEKI_JAR}" | sha1sum -c -


## ---- Stage: build minimal Java runtime
FROM eclipse-temurin:${JAVA_VERSION}-alpine AS jre

ARG JAVA_MINIMAL
ARG FUSEKI_DIR
ARG FUSEKI_JAR

# Alpine: objcopy is needed by jlink --strip-debug
RUN apk add --no-cache binutils

WORKDIR ${FUSEKI_DIR}
COPY --from=fuseki-download ${FUSEKI_DIR}/${FUSEKI_JAR} ./

ARG JDEPS_EXTRA="jdk.incubator.vector"
RUN JDEPS="$(jdeps --multi-release base --print-module-deps --ignore-missing-deps "${FUSEKI_JAR}")" && \
    jlink \
        --compress=zip-6 --strip-debug --no-header-files --no-man-pages --generate-cds-archive \
        --output "${JAVA_MINIMAL}" \
        --add-modules "${JDEPS},${JDEPS_EXTRA}"


## ---- Stage: load data and build text index
FROM jre AS loader

ARG JAVA_MINIMAL
ARG FUSEKI_DIR
ARG FUSEKI_JAR
ARG DATABASE=./db

ENV JAVA_HOME=${JAVA_MINIMAL}

WORKDIR ${FUSEKI_DIR}

# Load data
COPY ./data/*.ttl ./data/
RUN "$JAVA_HOME/bin/java" --add-modules jdk.incubator.vector \
        -cp "${FUSEKI_DIR}/${FUSEKI_JAR}" \
        tdb2.tdbloader --loader=parallel --loc "$DATABASE" ./data/*.ttl

COPY ./fuseki/config.ttl ./config.ttl

RUN "$JAVA_HOME/bin/java" --add-modules jdk.incubator.vector \
        -cp "${FUSEKI_DIR}/${FUSEKI_JAR}" \
        jena.textindexer --desc config.ttl


## ---- Stage: runtime
FROM alpine:${ALPINE_VERSION}

ARG JENA_VERSION
ARG JAVA_MINIMAL
ARG FUSEKI_DIR
ARG FUSEKI_JAR
ARG JENA_USER=fuseki
ARG JENA_GROUP=$JENA_USER
ARG JENA_GID=1000
ARG JENA_UID=1000

WORKDIR ${FUSEKI_DIR}

# -H : no home directory, -D : no password
RUN addgroup -g "${JENA_GID}" "${JENA_GROUP}" && \
    adduser "${JENA_USER}" -G "${JENA_GROUP}" -s /bin/ash -u "${JENA_UID}" -H -D && \
    mkdir -p run && \
    chown "${JENA_USER}:${JENA_GROUP}" run

# Least-frequently changing layers first; data last.
# JRE, JAR and config stay root-owned (read-only for the service user).
COPY --from=jre ${JAVA_MINIMAL} ${JAVA_MINIMAL}
COPY --from=fuseki-download ${FUSEKI_DIR}/${FUSEKI_JAR} ./
COPY ./fuseki/config.ttl ./fuseki/log4j2.properties ./
COPY --from=loader --chown=${JENA_USER}:${JENA_GROUP} ${FUSEKI_DIR}/db/ ./db/
COPY --from=loader --chown=${JENA_USER}:${JENA_GROUP} ${FUSEKI_DIR}/fts-index/ ./fts-index/

USER ${JENA_USER}

# Heap sized from the container memory limit. TDB2 uses memory-mapped files
# outside the heap, so leave headroom rather than giving the heap everything.
ENV \
    JAVA_HOME=${JAVA_MINIMAL} \
    JAVA_OPTIONS="--enable-native-access=ALL-UNNAMED --add-modules=jdk.incubator.vector -XX:MaxRAMPercentage=50 -XX:InitialRAMPercentage=50" \
    JENA_VERSION=${JENA_VERSION} \
    FUSEKI_JAR="${FUSEKI_JAR}" \
    FUSEKI_DIR="${FUSEKI_DIR}"

EXPOSE 3030

ENTRYPOINT ["/bin/sh", "-c", "exec \"$JAVA_HOME/bin/java\" $JAVA_OPTIONS -jar \"$FUSEKI_DIR/$FUSEKI_JAR\" \"$@\"", "--"]

CMD ["--conf", "./config.ttl"]
