FROM stackbrew/debian:7.3
MAINTAINER drew

RUN apt-get update
#enable i386 packages
RUN echo `dpkg --version`
RUN echo `dpkg --add-architecture i386`
RUN apt-get update
#JRE 32-bit
#We use 32-bit JRE because it uses substantially less memory than 64-bit (like half)
RUN apt-get install -y wget openjdk-7-jre-headless:i386
RUN update-java-alternatives -s java-1.7.0-openjdk-i386

ADD buildAgent buildAgent

ADD start_agent.sh /start_agent.sh

EXPOSE 9000

ENTRYPOINT ["/bin/bash","/start_agent.sh"]