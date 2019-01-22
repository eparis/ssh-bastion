FROM fedora
RUN yum update -y && yum install -y openssh-server openssh-clients jq origin-clients && yum clean all

COPY launch.sh /bin/
RUN chmod +x /bin/launch.sh

CMD /bin/launch.sh
