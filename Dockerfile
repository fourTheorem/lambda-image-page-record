FROM 628053151772.dkr.ecr.sa-east-1.amazonaws.com/awslambda/nodejs12.x-runtime:beta

RUN yum update -y && \
    yum install -y tar bzip2 gtk3 dbus-glib libXt xorg-x11-server-Xvfb ImageMagick xz procps

WORKDIR /opt

RUN curl -L "https://download.mozilla.org/?product=firefox-latest-ssl&os=linux64&lang=en-US" > firefox.tar.bz2 && \
    tar xf firefox.tar.bz2 && \
    rm firefox.tar.bz2

WORKDIR /opt/firefox
RUN curl -L "https://github.com/mozilla/geckodriver/releases/download/v0.28.0/geckodriver-v0.28.0-linux64.tar.gz" > geckodriver.tar.gz && \
    tar xf geckodriver.tar.gz && \
    rm geckodriver.tar.gz

RUN curl -o ffmpeg.tar.xz https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz && \
    tar xf ffmpeg.tar.xz && \
    mv ffmpeg*/ffmpeg /usr/local/bin && \
    rm ffmpeg.tar.xz

RUN mkdir /app
WORKDIR /app
COPY app/package*.json /app/

RUN npm install
COPY app/* /app/

ENV PATH="/opt/firefox:${PATH}"
ENV DISPLAY=":19"

CMD ["/app/handler.handleEvent"]
