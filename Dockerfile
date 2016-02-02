FROM perl:latest

MAINTAINER Ken Youens-Clark <kyclark@email.arizona.edu>

RUN apt-get update && apt-get install libdb-dev -y

RUN cpanm --force Capture::Tiny

RUN cpanm --force BioPerl

RUN cpanm DBI

RUN cpanm DBD::SQLite

RUN cpanm Text::RecordParser

RUN cpanm File::Find::Rule

RUN cpanm Readonly

COPY bin /usr/local/bin/

COPY scripts /usr/local/bin/pcpipe/

ENV PATH=$PATH:/usr/local/bin/pcpipe

ENTRYPOINT ["run-pcpipe.sh"]
