# Copyright 2018 AgID - Agenzia per l'Italia Digitale
#
# Licensed under the EUPL, Version 1.2 or - as soon they will be approved by
# the European Commission - subsequent versions of the EUPL (the "Licence").
#
# You may not use this work except in compliance with the Licence.
#
# You may obtain a copy of the Licence at:
#
#    https://joinup.ec.europa.eu/software/page/eupl
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the Licence is distributed on an "AS IS" basis, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# Licence for the specific language governing permissions and limitations
# under the Licence.

FROM centos/httpd-24-centos7

LABEL maintainer="AgID - Agenzia per l'Italia Digitale" \
      maintainer.email="spid.tech@agid.gov.it"

USER root

# add Shibboleth repo
COPY ./etc/yum.repos.d/shibboleth.repo /etc/yum.repos.d/

# install dependencies
RUN yum install -y \
        java-1.8.0-openjdk-headless \
        shibboleth.x86_64 \
        unzip \
    && yum -y clean all

# install xmlsectools
WORKDIR /tmp
RUN curl https://shibboleth.net/downloads/PGP_KEYS 2>/dev/null | gpg --import \
    && curl http://shibboleth.net/downloads/tools/xmlsectool/latest/xmlsectool-2.0.0-bin.zip > xmlsectool.zip \
    && curl http://shibboleth.net/downloads/tools/xmlsectool/latest/xmlsectool-2.0.0-bin.zip.asc > xmlsectool.zip.asc \
    && gpg --verify xmlsectool.zip.asc xmlsectool.zip \
    && unzip xmlsectool.zip \
    && mv xmlsectool-2.0.0 /opt/xmlsectool \
    && rm -f \
        xmlsectool.zip \
        xmlsectool.zip.asc \
    && yum remove -y \
        unzip

# add static pages
COPY ./var/www/html/access /var/www/html/access
COPY ./var/www/html/whoami /var/www/html/whoami

# add application paths
COPY ./opt/shibboleth-sp /opt/shibboleth-sp
COPY ./opt/spid-metadata /opt/spid-metadata

# add configurations
COPY ./etc/shibboleth/ /etc/shibboleth/
COPY ./etc/httpd/conf.d/ /etc/httpd/conf.d/

# copy bootstrap script
COPY ./usr/local/bin/ /usr/local/bin/
RUN chmod +x \
    /usr/local/bin/docker-bootstrap.sh \
    /usr/local/bin/metagen.sh


RUN chmod -R g+rx /opt/xmlsectool \
    && chmod -R g+rw /var/www/html \ 
    && chmod -R g+rw /opt/shibboleth-sp \
    && chmod -R g+rw /opt/spid-metadata \
    && chmod -R g+rw /etc/shibboleth \
    && chmod -R g+rw /etc/httpd/conf.d \
    && chmod -R g+rw /etc/pki/tls/private \
    && chmod -R g+rw /etc/pki/tls/certs \
    && chown -R default:root /var/run/shibboleth \
    && chown -R default:root /var/log/shibboleth \
    && chmod -R a+rw /var/run/shibboleth \
    && chmod -R a+rw /var/log/shibboleth \
    && chmod g+rx /usr/local/bin/docker-bootstrap.sh \
    && chmod g+rx /usr/local/bin/metagen.sh


USER default

# run it
CMD ["docker-bootstrap.sh"]