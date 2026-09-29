ARG DEBIAN_DIST=bookworm
FROM debian:$DEBIAN_DIST

ARG DEBIAN_DIST
ARG mitmproxy_VERSION
ARG BUILD_VERSION
ARG FULL_VERSION
ARG ARCH
ARG MP_RELEASE

RUN mkdir -p /output/usr/bin
RUN mkdir -p /output/usr/share/doc/mitmproxy
RUN mkdir -p /output/DEBIAN

# Upstream publishes no shell completions or man pages; the three standalone
# binaries are the whole payload.
COPY ${MP_RELEASE}/mitmproxy /output/usr/bin/mitmproxy
COPY ${MP_RELEASE}/mitmdump /output/usr/bin/mitmdump
COPY ${MP_RELEASE}/mitmweb /output/usr/bin/mitmweb
RUN chmod 755 /output/usr/bin/mitmproxy /output/usr/bin/mitmdump /output/usr/bin/mitmweb
COPY output/DEBIAN/control /output/DEBIAN/
COPY output/DEBIAN/postinst /output/DEBIAN/postinst
RUN chmod 755 /output/DEBIAN/postinst
COPY output/copyright /output/usr/share/doc/mitmproxy/
COPY output/changelog.Debian /output/usr/share/doc/mitmproxy/
COPY output/README.md /output/usr/share/doc/mitmproxy/
RUN chmod 644 /output/usr/share/doc/mitmproxy/*

RUN sed -i "s/DIST/$DEBIAN_DIST/" /output/usr/share/doc/mitmproxy/changelog.Debian
RUN sed -i "s/FULL_VERSION/$FULL_VERSION/" /output/usr/share/doc/mitmproxy/changelog.Debian
RUN sed -i "s/DIST/$DEBIAN_DIST/" /output/DEBIAN/control
RUN sed -i "s/mitmproxy_VERSION/$mitmproxy_VERSION/" /output/DEBIAN/control
RUN sed -i "s/BUILD_VERSION/$BUILD_VERSION/" /output/DEBIAN/control
RUN sed -i "s/SUPPORTED_ARCHITECTURES/$ARCH/" /output/DEBIAN/control

RUN dpkg-deb --build /output /mitmproxy_${FULL_VERSION}.deb
