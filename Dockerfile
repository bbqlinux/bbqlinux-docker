FROM scratch
ADD bbqlinux.tar /
ENV LANG=en_US.UTF-8
CMD ["/usr/bin/bash"]
