FROM ubuntu:14.04.2

MAINTAINER khiraiwa

# input-cloudwatch plugin don'tstill support 2.0.0
ENV LOGSTASH_VERSION 1.5.5

# Install Java
RUN \
  apt-get update && \
  apt-get install software-properties-common python-software-properties wget unzip -y && \
  echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get update && \
  apt-get install -y oracle-java8-installer && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /var/cache/oracle-jdk8-installer
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

# Add logstash user
RUN \
  mkdir -p /home/logstash/ && \
  groupadd -r logstash && useradd -r -d /home/logstash -s /bin/bash -g logstash logstash && \
  echo 'logstash ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Install Logstash
RUN \
  cd /home/logstash && \
  wget https://download.elastic.co/logstash/logstash/logstash-${LOGSTASH_VERSION}.zip && \
  unzip logstash-${LOGSTASH_VERSION}.zip && \
  rm -f logstash-${LOGSTASH_VERSION}.zip

ADD logstash.conf /home/logstash/logstash-${LOGSTASH_VERSION}/logstash.conf

# Install plugin
RUN /home/logstash/logstash-${LOGSTASH_VERSION}/bin/plugin install logstash-input-cloudwatch

RUN mkdir -p /data_logstash/
VOLUME ["/data_logstash/"]

# Mount data dir and setup home dir
RUN \
  chown -R logstash:logstash /data_logstash && \
  chown -R logstash:logstash /home/logstash

USER logstash
WORKDIR /home/logstash/logstash-${LOGSTASH_VERSION}

CMD \
  sudo chown -R logstash:logstash /data_logstash && \
  cp /home/logstash/logstash-${LOGSTASH_VERSION}/logstash.conf /data_logstash/logstash.conf && \
  /home/logstash/logstash-${LOGSTASH_VERSION}/bin/logstash agent -f /data_logstash/logstash.conf
