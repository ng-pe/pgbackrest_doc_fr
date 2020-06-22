FROM centos:7

ENV container docker

        COPY resource/fake-cert/ca.crt /etc/pki/ca-trust/source/anchors/pgbackrest-ca.crt

        RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == \
            systemd-tmpfiles-setup.service ] || rm -f $i; done); \
            rm -f /lib/systemd/system/multi-user.target.wants/*;\
            rm -f /etc/systemd/system/*.wants/*;\
            rm -f /lib/systemd/system/local-fs.target.wants/*; \
            rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
            rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
            rm -f /lib/systemd/system/basic.target.wants/*;\
            rm -f /lib/systemd/system/anaconda.target.wants/*;

        VOLUME [ "/sys/fs/cgroup" ]

        # Install packages
        RUN yum install -y openssh-server openssh-clients sudo wget vim 2>&1

        # Install CA certificate
        RUN update-ca-trust extract

        # Regenerate SSH keys
        RUN rm -f /etc/ssh/ssh_host_rsa_key* && \
            ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key && \
            rm -f /etc/ssh/ssh_host_dsa_key* && \
            ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key

        # Install PostgreSQL
        RUN rpm --import http://yum.postgresql.org/RPM-GPG-KEY-PGDG-10 && \
            rpm -ivh https://download.postgresql.org/pub/repos/yum/11/redhat/rhel-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm  && \
            yum install -y postgresql96-server postgresql10-server

        # Create an ssh key for root so all hosts can ssh to each other as root
        RUN \ 
            mkdir -p -m 700 /root/.ssh && \
            echo '-----BEGIN RSA PRIVATE KEY-----' > /root/.ssh/id_rsa && \
            echo 'MIICXwIBAAKBgQDR0yJsZW5d5LcqteiOtv8d+FFeFFHDPI0VTcTOdMn1iDiIP1ou' >> /root/.ssh/id_rsa && \
            echo 'X3Q2OyNjsBaDbsRJd+sp9IRq1LKX3zsBcgGZANwm0zduuNEPEU94ajS/uRoejIqY' >> /root/.ssh/id_rsa && \
            echo '/XkKOpnEF6ZbQ2S7TaE4sWeGLvba7kUFs0QTOO+N+nV2dMbdqZf6C8lazwIDAQAB' >> /root/.ssh/id_rsa && \
            echo 'AoGBAJXa6xzrnFVmwgK5BKzYuX/YF5TPgk2j80ch0ct50buQXH/Cb0/rUH5i4jWS' >> /root/.ssh/id_rsa && \
            echo 'T6Hy/DFUehnuzpvV6O9auTOhDs3BhEKFRuRLn1nBwTtZny5Hh+cw7azUCEHFCJlz' >> /root/.ssh/id_rsa && \
            echo 'makCrVbgawtno6oU/pFgQm1FcxD0f+Me5ruNcLHqUZsPQwkRAkEA+8pG+ckOlz6R' >> /root/.ssh/id_rsa && \
            echo 'AJLIHedmfcrEY9T7sfdo83bzMOz8H5soUUP4aOTLJYCla1LO7JdDnXMGo0KxaHBP' >> /root/.ssh/id_rsa && \
            echo 'l8j5zDmVewJBANVVPDJr1w37m0FBi37QgUOAijVfLXgyPMxYp2uc9ddjncif0063' >> /root/.ssh/id_rsa && \
            echo '0Wc0FQefoPszf3CDrHv/RHvhHq97jXDwTb0CQQDgH83NygoS1r57pCw9chzpG/R0' >> /root/.ssh/id_rsa && \
            echo 'aMEiSPhCvz757fj+qT3aGIal2AJ7/2c/gRZvwrWNETZ3XIZOUKqIkXzJLPjBAkEA' >> /root/.ssh/id_rsa && \
            echo 'wnP799W2Y8d4/+VX2pMBkF7lG7sSviHEq1sP2BZtPBRQKSQNvw3scM7XcGh/mxmY' >> /root/.ssh/id_rsa && \
            echo 'yx0qpqfKa8SKbNgI1+4iXQJBAOlg8MJLwkUtrG+p8wf69oCuZsnyv0K6UMDxm6/8' >> /root/.ssh/id_rsa && \
            echo 'cbvfmvODulYFaIahaqHWEZoRo5CLYZ7gN43WHPOrKxdDL78=' >> /root/.ssh/id_rsa && \
            echo '-----END RSA PRIVATE KEY-----' >> /root/.ssh/id_rsa && \
            echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDR0yJsZW5d5LcqteiOtv8d+FFeFFHDPI0VTcTOdMn1iDiIP1ouX3Q2OyNjsBaDbsRJd+sp9IRq1LKX3zsBcgGZANwm0zduuNEPEU94ajS/uRoejIqY/XkKOpnEF6ZbQ2S7TaE4sWeGLvba7kUFs0QTOO+N+nV2dMbdqZf6C8lazw== root@pgbackrest-doc' > /root/.ssh/authorized_keys && \
            echo 'Host *' > /root/.ssh/config && \
            echo '    StrictHostKeyChecking no' >> /root/.ssh/config && \
            chmod 600 /root/.ssh/*
        

        # Add doc user with sudo privileges
        RUN adduser -n vagrant && \
            echo 'vagrant        ALL=(ALL)       NOPASSWD: ALL' > /etc/sudoers.d/vagrant

        # Enable the user session service so logons are allowed
        RUN systemctl enable systemd-user-sessions.service && \
            ln -s /usr/lib/systemd/system/systemd-user-sessions.service \
                /etc/systemd/system/default.target.wants/systemd-user-sessions.service

        CMD ["/usr/sbin/init"]
