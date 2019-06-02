FROM alpine:latest as builder
MAINTAINER Arne Neumann <nlpbox.programming@arne.cl>

RUN apk update && \
    apk add git wget openjdk8-jre-base py2-pip py2-curl && \
    pip install setuptools

# install geturl script to retrieve the most current download URL of CoreNLP
WORKDIR /opt
RUN git clone https://github.com/arne-cl/grepurl.git
WORKDIR /opt/grepurl
RUN python setup.py install

# install latest CoreNLP release
WORKDIR /opt
RUN wget $(grepurl -r 'zip$' -a http://stanfordnlp.github.io/CoreNLP/) && \
    unzip stanford-corenlp-full-*.zip && \
    mv $(ls -d stanford-corenlp-full-*/) corenlp && rm *.zip

# install latest English language model
#
# Docker can't store the result of a RUN command in an ENV, so we'll have
# to use this workaround.
# This command get's the first model file (at least for English there are two)
# and extracts its property file.
WORKDIR /opt/corenlp
RUN wget $(grepurl -r 'english-corenlp.*jar$' -a https://stanfordnlp.github.io/CoreNLP)
RUN wget $(grepurl -r 'english-kbp-corenlp.*jar$' -a https://stanfordnlp.github.io/CoreNLP)
RUN wget $(grepurl -r 'chinese-corenlp.*jar$' -a https://stanfordnlp.github.io/CoreNLP)


# only keep the things we need to run and test CoreNLP
FROM alpine:latest

RUN apk update && apk add openjdk8-jre-base py3-pip && \
    pip3 install pytest pexpect requests

WORKDIR /opt/corenlp
COPY --from=builder /opt/corenlp .

ADD test_api.py .

ENV JAVA_XMX 8g
ENV PORT 9000
EXPOSE $PORT

CMD java -Xmx$JAVA_XMX -cp "*" edu.stanford.nlp.pipeline.StanfordCoreNLPServer -port 9000 -timeout 15000
