FROM fedora
RUN yum update -y && yum install -y openssh-server openssh-clients jq origin-clients && yum clean all

RUN echo "%wheel  ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers

COPY launch.sh /bin/
RUN chmod +x /bin/launch.sh

CMD /bin/launch.sh
