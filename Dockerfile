## Licensed to the Apache Software Foundation (ASF) under one or more
## contributor license agreements.  See the NOTICE file distributed with
## this work for additional information regarding copyright ownership.
## The ASF licenses this file to You under the Apache License, Version 2.0
## (the "License"); you may not use this file except in compliance with
## the License.  You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.

## Apache Jena Fuseki server Dockerfile.

## This Dockefile builds a reduced footprint container.

ARG JAVA_VERSION=21
ARG ALPINE_VERSION=3
ARG JENA_VERSION=6.0.0

# Internal, passed between stages.
## Fuseki
ARG FUSEKI_DIR=/fuseki
ARG FUSEKI_JAR=jena-fuseki-server-${JENA_VERSION}.jar
## Jena (for TDB2 CLI tools)
ARG JENA_DIR=/apache-jena-${JENA_VERSION}
ARG JENA_TAR=apache-jena-${JENA_VERSION}.tar.gz
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
ARG JENA_DOWNLOAD=https://dlcdn.apache.org/jena/binaries/
ARG JENA_DIR
ARG JENA_TAR
ARG JENA_TAR_URL=${JENA_DOWNLOAD}${JENA_TAR}

RUN [ "${JENA_VERSION}" != "" ] || { echo -e '\n**** Set JENA_VERSION ****\n' ; exit 1 ; }
RUN echo && echo "==== Docker build for Apache Jena Fuseki ${JENA_VERSION} ====" && echo

# Alpine: For objcopy used in jlink
RUN apk add --no-cache curl binutils

## -- Fuseki installed and runs in /fuseki.
WORKDIR $FUSEKI_DIR

## -- Download the jar file.
ADD ./fuseki/download.sh .
RUN chmod a+x download.sh

# Download, with check of the SHA1 checksum.
RUN ./download.sh --chksum sha1 "$FUSEKI_JAR_URL"

## -- Make reduced Java JDK
ARG JDEPS_EXTRA="jdk.crypto.cryptoki,jdk.crypto.ec"
RUN \
  JDEPS="$(jdeps --multi-release base --print-module-deps --ignore-missing-deps ${FUSEKI_JAR})"  && \
  jlink \
        --compress 2 --strip-debug --no-header-files --no-man-pages \
        --output "${JAVA_MINIMAL}" \
        --add-modules "${JDEPS},${JDEPS_EXTRA}"

ADD ./fuseki/entrypoint.sh .
ADD ./fuseki/log4j2.properties .

# Download Jena, with check of the SHA512 checksum.
RUN ./download.sh --chksum sha512 "$JENA_TAR_URL"

# Untar
RUN tar -xvzf "$JENA_TAR" --directory /

# Cleanup
RUN rm download.sh
RUN rm apache-jena*

## ---- Stage: Build runtime
FROM alpine:${ALPINE_VERSION}

## Import ARGs
ARG JENA_VERSION
ARG JAVA_MINIMAL
ARG FUSEKI_DIR
ARG FUSEKI_JAR
ARG JENA_DIR

COPY --from=base /opt/java-minimal /opt/java-minimal
COPY --from=base ${FUSEKI_DIR} ${FUSEKI_DIR}
COPY --from=base ${JENA_DIR} ${JENA_DIR}

WORKDIR $FUSEKI_DIR

ARG LOGS=${FUSEKI_DIR}/logs
ARG DATABASE=./db

RUN mkdir -p $DATABASE

ARG JENA_USER=fuseki
ARG JENA_GROUP=$JENA_USER
ARG JENA_GID=1000
ARG JENA_UID=1000

# Run as this user
# -H : no home directory
# -D : no password
RUN addgroup -g "${JENA_GID}" "${JENA_GROUP}" && \
    adduser "${JENA_USER}" -G "${JENA_GROUP}" -s /bin/ash -u "${JENA_UID}" -H -D

RUN mkdir --parents "${FUSEKI_DIR}" && \
    chown -R $JENA_USER ${FUSEKI_DIR}

USER $JENA_USER

RUN \
    mkdir -p $LOGS && \
    chmod a+x entrypoint.sh

## Default environment variables.
ENV \
    JAVA_HOME=${JAVA_MINIMAL}           \
    JAVA_OPTIONS="-Xmx2048m -Xms2048m"  \
    JENA_VERSION=${JENA_VERSION}        \
    FUSEKI_JAR="${FUSEKI_JAR}"          \
    FUSEKI_DIR="${FUSEKI_DIR}"          \
    JENA_HOME="${JENA_DIR}"

ADD ./data/teamkinetic/organisations.jsonld .

RUN $JENA_HOME/bin/tdb2.tdbloader --loc $DATABASE organisations.jsonld

ADD ./data/teamkinetic/activities.jsonld .

RUN $JENA_HOME/bin/tdb2.tdbloader --loc $DATABASE activities.jsonld

ADD ./data/doit/data.ttl .

RUN $JENA_HOME/bin/tdb2.tdbloader --loc $DATABASE data.ttl

ADD ./vocabulary/vocabulary.ttl .
ADD ./vocabulary/organisation.ttl .
ADD ./vocabulary/time.ttl .

RUN $JENA_HOME/bin/tdb2.tdbloader --loc $DATABASE vocabulary.ttl
RUN $JENA_HOME/bin/tdb2.tdbloader --loc $DATABASE organisation.ttl
RUN $JENA_HOME/bin/tdb2.tdbloader --loc $DATABASE time.ttl

ADD ./fuseki/config.ttl .

RUN "$JAVA_HOME/bin/java" -cp "${FUSEKI_DIR}/${FUSEKI_JAR}" jena.textindexer --desc config.ttl

EXPOSE 3030

ENTRYPOINT ["./entrypoint.sh" ]

CMD [ "--conf", "./config.ttl" ]
