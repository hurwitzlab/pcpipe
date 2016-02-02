FROM perl:latest

MAINTAINER Ken Youens-Clark <kyclark@email.arizona.edu>

RUN apt-get update && apt-get install libdb-dev -y

RUN cpanm --force Capture::Tiny

RUN cpanm --force BioPerl

COPY bin /usr/local/bin/

COPY scripts /usr/local/bin/pcpipe/

ENV PATH=$PATH:/usr/local/bin/pcpipe

ENTRYPOINT ["run-pcpipe.sh"]
