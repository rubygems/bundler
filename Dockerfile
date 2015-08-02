FROM ruby:2.0.0
MAINTAINER Steven Jack <stevenmajack@gmail.com>

ADD . /app
WORKDIR /app
RUN rake spec:deps

ENTRYPOINT ["rake"]
CMD ["spec"]
