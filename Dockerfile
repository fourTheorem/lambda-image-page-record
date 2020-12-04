FROM public.ecr.aws/lambda/nodejs:12

RUN yum update -y && \
    yum install -y tar bzip2 gtk3 dbus-glib libXt xorg-x11-server-Xvfb ImageMagick xz procps

WORKDIR /opt

RUN curl -o ffmpeg.tar.xz https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz && \
    tar xf ffmpeg.tar.xz && \
    mv ffmpeg*/ffmpeg /usr/local/bin && \
    rm ffmpeg.tar.xz

RUN curl -o chrome.rpm https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
RUN yum install -y chrome.rpm

RUN mkdir /app
WORKDIR /app
COPY app/package*.json /app/
#RUN yum install -y make gcc-c++
RUN npm install
COPY app/ /app/

ENV DISPLAY=":19"

CMD ["/app/handler.handleEvent"]
