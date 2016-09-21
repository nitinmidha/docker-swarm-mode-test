FROM ubuntu:trusty
RUN apt-get update -qq && \
    apt-get install -y curl openssh-client uuid-runtime && \ 
    mkdir -p /usr/local/swarm-test && \
    mkdir -p /etc/shh-keys && \
    mkdir -p /var/log/swarm-test
VOLUME ["/var/log/swarm-test"]
WORKDIR /usr/local/swarm-test

COPY ./Scripts/*.sh /usr/local/swarm-test/
WORKDIR /usr/local/swarm-test/
RUN sudo chmod 666 *.sh \
    && sudo chmod +x swarm-test.sh \
    && sudo chmod +x container-setup.sh 
ENTRYPOINT ["./container-setup.sh"]
