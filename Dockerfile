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

#supervisor
#supervisor
RUN apt-get install -y supervisor
RUN mkdir -p /var/log/supervisor
ADD supervisord.conf /etc/supervisor/supervisor.conf
RUN apt-get install -y python-pip && pip install supervisor-stdout

ADD buildAgent buildAgent

ADD start_agent.sh /start_agent.sh

EXPOSE 9000

CMD ["-c", "/etc/supervisor/supervisor.conf"]
ENTRYPOINT ["/usr/bin/supervisord"]

#sup dawg
RUN apt-get install -qqy iptables ca-certificates lxc
ADD https://get.docker.io/builds/Linux/x86_64/docker-latest /usr/local/bin/docker
RUN chmod +x /usr/local/bin/docker
VOLUME /var/lib/docker
ADD dockerprep.sh /dockerprep.sh
RUN echo "docker=0.7.5" >> buildAgent/bin/conf/buildAgent.properties