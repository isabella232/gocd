# Copyright ${copyrightYear} Thoughtworks, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

###############################################################################################
# This file is autogenerated by the repository at https://github.com/gocd/gocd.
# Please file any issues or PRs at https://github.com/gocd/gocd
###############################################################################################

FROM curlimages/curl:latest as gocd-agent-unzip
USER root
ARG UID=1000
<#if useFromArtifact >
COPY go-agent-${fullVersion}.zip /tmp/go-agent-${fullVersion}.zip
RUN \
<#else>
RUN curl --fail --location --silent --show-error "https://download.gocd.org/binaries/${fullVersion}/generic/go-agent-${fullVersion}.zip" > /tmp/go-agent-${fullVersion}.zip && \
</#if>
    unzip /tmp/go-agent-${fullVersion}.zip -d / && \
    mv /go-agent-${goVersion} /go-agent && \
    chown -R ${r"${UID}"}:0 /go-agent && \
    chmod -R g=u /go-agent

FROM ${distro.getBaseImageLocation(distroVersion)}

LABEL gocd.version="${goVersion}" \
  description="GoCD agent based on ${distro.getBaseImageLocation(distroVersion)}" \
  maintainer="GoCD Team <go-cd-dev@googlegroups.com>" \
  url="https://www.gocd.org" \
  gocd.full.version="${fullVersion}" \
  gocd.git.sha="${gitRevision}"

<#list additionalFiles as filePath, fileDescriptor>
ADD ${fileDescriptor.url} ${filePath}
</#list>

# force encoding
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8
<#list distro.getEnvironmentVariables(distroVersion) as key, value>
ENV ${key}="${value}"
</#list>

ARG UID=1000
ARG GID=1000

RUN \
<#if additionalFiles?size != 0>
# add mode and permissions for files we added above
  <#list additionalFiles as filePath, fileDescriptor>
  chmod ${fileDescriptor.mode} ${filePath} && \
  chown ${fileDescriptor.owner}:${fileDescriptor.group} ${filePath} && \
  </#list>
</#if>
# add our user and group first to make sure their IDs get assigned consistently,
# regardless of whatever dependencies get added
# add user to root group for GoCD to work on openshift
<#list distro.createUserAndGroupCommands as command>
  ${command} && \
</#list>
<#list distroVersion.installPrerequisitesCommands as command>
    ${command} && \
</#list>
<#list distro.getInstallPrerequisitesCommands(distroVersion) as command>
  ${command} && \
</#list>
<#list distro.getInstallJavaCommands(project) as command>
  ${command} && \
</#list>
  mkdir -p /go-agent /docker-entrypoint.d /go /godata

ADD docker-entrypoint.sh /


COPY --from=gocd-agent-unzip /go-agent /go-agent
# ensure that logs are printed to console output
COPY --chown=go:root agent-bootstrapper-logback-include.xml agent-launcher-logback-include.xml agent-logback-include.xml /go-agent/config/
<#if distro.name() == "docker">
COPY --chown=root:root dockerd-sudo /etc/sudoers.d/dockerd-sudo
</#if>

RUN chown -R go:root /docker-entrypoint.d /go /godata /docker-entrypoint.sh && \
    chmod -R g=u /docker-entrypoint.d /go /godata /docker-entrypoint.sh

<#if distro.name() == "docker">
  COPY --chown=root:root run-docker-daemon.sh /
</#if>

ENTRYPOINT ["/docker-entrypoint.sh"]

USER go
