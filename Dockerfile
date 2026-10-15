ARG JAVA_VERSION=21
ARG ALPINE_VERSION=3
ARG JENA_VERSION=6.2.0

# Internal, passed between stages.
## Fuseki
ARG FUSEKI_DIR=/fuseki
ARG FUSEKI_JAR=jena-fuseki-server-${JENA_VERSION}.jar
## Jena (for TDB2 CLI tools)
ARG JENA_DIR=/apache-jena-${JENA_VERSION}
## Java
ARG JAVA_MINIMAL=/opt/java-minimal


## ---- Stage: Download and build java.
FROM eclipse-temurin:${JAVA_VERSION}-alpine AS base

ARG JAVA_MINIMAL
ARG JENA_VERSION
ARG FUSEKI_DIR
ARG FUSEKI_JAR
ARG REPO=https://repo1.maven.org/maven2
ARG FUSEKI_JAR_URL=${REPO}/org/apache/jena/jena-fuseki-server/${JENA_VERSION}/${FUSEKI_JAR}
ARG JENA_TAR=apache-jena-${JENA_VERSION}.tar.gz
ARG JENA_TAR_URL=https://dlcdn.apache.org/jena/binaries/${JENA_TAR}

# Alpine: For objcopy used in jlink
RUN apk add --no-cache curl binutils

## -- Fuseki installed and runs in /fuseki.
WORKDIR $FUSEKI_DIR

## -- Download Fuseki JAR and check SHA1
RUN curl -fsSL "$FUSEKI_JAR_URL" -o "$FUSEKI_JAR" && \
    curl -fsSL "${FUSEKI_JAR_URL}.sha1" -o "${FUSEKI_JAR}.sha1" && \
    printf '%s  %s\n' \
        "$(cut -d' ' -f1 "${FUSEKI_JAR}.sha1")" \
        "$FUSEKI_JAR" | sha1sum -c - && \
    rm "${FUSEKI_JAR}.sha1"

## -- Make reduced Java JDK
ARG JDEPS_EXTRA="jdk.crypto.cryptoki,jdk.crypto.ec,jdk.incubator.vector"
RUN \
  JDEPS="$(jdeps --multi-release base --print-module-deps --ignore-missing-deps ${FUSEKI_JAR})"  && \
  jlink \
        --compress 2 --strip-debug --no-header-files --no-man-pages \
        --output "${JAVA_MINIMAL}" \
        --add-modules "${JDEPS},${JDEPS_EXTRA}"

# Download Jena, with check of the SHA512 checksum.
RUN curl -fsSL "$JENA_TAR_URL" -o "$JENA_TAR" && \
    curl -fsSL "${JENA_TAR_URL}.sha512" -o "${JENA_TAR}.sha512" && \
    printf '%s  %s\n' \
        "$(cut -d' ' -f1 "${JENA_TAR}.sha512")" \
        "$JENA_TAR" | sha512sum -c - && \
    tar -xzf "$JENA_TAR" --directory / && \
    rm "$JENA_TAR" "${JENA_TAR}.sha512"


## ---- Stage: Load data and build index.
FROM base AS base-loaded

ARG JAVA_MINIMAL
ARG JENA_DIR
ARG DATABASE=./db

ENV JAVA_HOME=${JAVA_MINIMAL} \
    JENA_HOME=${JENA_DIR}

WORKDIR ${FUSEKI_DIR}

COPY ./data/*.ttl ./data/
COPY ./fuseki/config.ttl ./config.ttl

# Create database
RUN mkdir -p "$DATABASE" && \
    for file in ./data/*.ttl; do \
        "$JENA_HOME/bin/tdb2.tdbloader" --loc "$DATABASE" "$file" || exit 1; \
    done

# Load indexer config
RUN "$JAVA_HOME/bin/java" --add-modules jdk.incubator.vector \
    -cp "${FUSEKI_DIR}/${FUSEKI_JAR}" jena.textindexer --desc config.ttl


## ---- Stage: Build runtime
FROM alpine:${ALPINE_VERSION}

## Import ARGs
ARG JENA_VERSION
ARG JAVA_MINIMAL
ARG FUSEKI_DIR
ARG FUSEKI_JAR
ARG JENA_USER=fuseki
ARG JENA_GROUP=$JENA_USER
ARG JENA_GID=1000
ARG JENA_UID=1000

WORKDIR $FUSEKI_DIR

# Run as this user
# -H : no home directory
# -D : no password
RUN addgroup -g "${JENA_GID}" "${JENA_GROUP}" && \
    adduser "${JENA_USER}" -G "${JENA_GROUP}" -s /bin/ash -u "${JENA_UID}" -H -D

COPY --from=base /opt/java-minimal /opt/java-minimal
COPY --from=base --chown=${JENA_USER}:${JENA_GROUP} \
    ${FUSEKI_DIR} ${FUSEKI_DIR}
COPY --from=base-loaded --chown=${JENA_USER}:${JENA_GROUP} \
    ${FUSEKI_DIR}/db/ ${FUSEKI_DIR}/db/
COPY --from=base-loaded --chown=${JENA_USER}:${JENA_GROUP} \
    ${FUSEKI_DIR}/fts-index/ ${FUSEKI_DIR}/fts-index/

## Load Fuseki and Log4j config
COPY --chown=${JENA_USER}:${JENA_GROUP} \
    ./fuseki/config.ttl .
COPY --chown=${JENA_USER}:${JENA_GROUP} \
    ./fuseki/log4j2.properties .

RUN mkdir -p "${FUSEKI_DIR}/run" && \
    chown "${JENA_USER}:${JENA_GROUP}" "${FUSEKI_DIR}/run"

USER $JENA_USER

## Default environment variables.
ENV \
    JAVA_HOME=${JAVA_MINIMAL}           \
    JAVA_OPTIONS="--enable-native-access=ALL-UNNAMED --add-modules=jdk.incubator.vector -Xmx2048m -Xms2048m"  \
    JENA_VERSION=${JENA_VERSION}        \
    FUSEKI_JAR="${FUSEKI_JAR}"          \
    FUSEKI_DIR="${FUSEKI_DIR}"

EXPOSE 3030

ENTRYPOINT ["/bin/sh", "-c", "exec \"$JAVA_HOME/bin/java\" $JAVA_OPTIONS -jar \"$FUSEKI_DIR/$FUSEKI_JAR\" \"$@\"", "--"]

CMD ["--conf", "./config.ttl"]
