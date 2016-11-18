FROM ezkrg/alpine-glibc

ENV UID=100 UNAME=plex GID=990 GNAME=plex
ADD start_pms.patch /tmp/start_pms.patch
ADD https://plex.tv/downloads/latest/1?channel=16&build=linux-ubuntu-x86_64&distro=ubuntu /tmp/plexmediaserver.deb

RUN addgroup -S $GNAME \
 && adduser -S -G $GNAME -s /usr/sbin/nologin -h /var/lib/plexmediaserver $UNAME \

 && apk add --no-cache xz binutils patchelf openssl file \

 && cd /tmp \
 && ar x plexmediaserver.deb \
 && tar -xf data.tar.* \

 && find usr/lib/plexmediaserver -type f -perm /0111 -exec sh -c "file --brief \"{}\" | grep -q "ELF" && patchelf --set-interpreter \"$GLIBC_LD_LINUX_SO\" \"{}\" " \; \

 && mv /tmp/start_pms.patch usr/sbin/ \
 && cd usr/sbin/ \
 && patch < start_pms.patch \
 && cd /tmp \
 && sed -i "s|<destdir>|$DESTDIR|" usr/sbin/start_pms \

 && mv usr/sbin/start_pms $DESTDIR/ \
 && mv usr/lib/plexmediaserver $DESTDIR/plexmediaserver \

 && apk del --no-cache xz binutils patchelf file \
 && rm -rf /tmp/*

EXPOSE 32400 1900/udp 3005 5353/udp 8324 32410/udp 32412/udp 32413/udp 32414/udp 32469

USER plex

ENTRYPOINT [ "/glibc/start_pms" ]
