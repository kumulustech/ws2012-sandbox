FROM alpine:latest
RUN apk -v --update add \
        python \
        py-pip \
        groff \
        less \
        mailcap \
        gettext \
        && \
    pip install --upgrade awscli s3cmd python-magic && \
    apk -v --purge del py-pip && \
    rm /var/cache/apk/*
VOLUME /root/.aws
VOLUME /sandbox
ENTRYPOINT ["/bin/sh"]
CMD ["/sandbox/container_depiis.sh"]
