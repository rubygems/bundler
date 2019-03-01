FROM ruby:2.3

RUN apt-get update -qq && \
    apt-get install -y build-essential \
                       graphviz \
                       groff-base \
                       bsdmainutils \
                       git

WORKDIR /home

CMD ["sh", "/home/bin/dockerstart"]
