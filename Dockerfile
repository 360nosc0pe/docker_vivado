FROM ubuntu:16.04
MAINTAINER Andreas Galauner <andreas@galauner.de>

#Dockerfile variable definitions
ARG VIVADO_VERSION=2018.2
ARG VIVADO_SETUP=Xilinx_Vivado_SDK_2018.2_0614_1954.tar.gz
ARG VIVADO_SETUP_CONFIG=install_config_$VIVADO_VERSION.txt
ARG DOCKERHOST_IP=172.17.0.1

#Set debian frontend to noninteractive
ENV DEBIAN_FRONTEND noninteractive

#Add i386 architecture
RUN dpkg --add-architecture i386

#Update stuff
RUN apt-get update
RUN apt-get -y upgrade

#Use bash - not dash
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

#Install typical utilities
RUN apt-get install -y git vim curl locales

#Install Yocto dependencies
RUN apt-get install -y gawk wget git-core diffstat unzip texinfo gcc-multilib \
	build-essential chrpath libsdl1.2-dev xterm python3 cpio inetutils-ping 
RUN apt-get install -y parted dosfstools mtools syslinux lsb-release

#Install Xilinx SDK dependencies
RUN apt-get install -y libgtk2.0-0 xvfb

#Install i386 dependencies for SDK
RUN apt-get install -y zlib1g:i386 libstdc++6:i386

#Install Vivado HLS dependencies
RUN apt-get install -y libtiff5-dev libjpeg8-dev
#YOLO
RUN ln -s /usr/lib/x86_64-linux-gnu/libtiff.so.5 /usr/lib/x86_64-linux-gnu/libtiff.so.3
RUN ln -s /usr/lib/x86_64-linux-gnu/libjpeg.so.8 /usr/lib/x86_64-linux-gnu/libjpeg.so.62

#Link make to gmake to make the Xilinx tools happy
RUN ln -s /usr/bin/make /usr/bin/gmake

#Set the locale to en_US.UTF-8
ADD files/locale /etc/default/locale
RUN locale-gen en_US.UTF-8 &&\
  DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales

#Create an unprivileged user
RUN useradd -m -G users --shell /bin/bash build
RUN mkdir -p /home/build
RUN chown -R build /home/build

#Setup a project environment
RUN mkdir -p /project && \
	chown build:users /project
VOLUME /project
WORKDIR /project


####### Vivado Setup #######
#generate install_config.txt with
#./xsetup -b ConfigGen
#run setup with
#./xsetup --agree XilinxEULA,3rdPartyEULA,WebTalkTerms --batch Install --config install_config.txt

#Add batch installation config
ADD files/$VIVADO_SETUP_CONFIG /tmp/install_config.txt

#Run setup
RUN mkdir -p /tmp && \
    wget http://$DOCKERHOST_IP:8000/files/$VIVADO_SETUP -O /tmp/xilinx_vivado.tar.gz -c \
    --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 -t 0 && \
	mkdir -p /tmp/vivado && \
	tar xzf /tmp/xilinx_vivado.tar.gz --strip 1 -C /tmp/vivado && \
	rm /tmp/xilinx_vivado.tar.gz && \
	/tmp/vivado/xsetup --agree XilinxEULA,3rdPartyEULA,WebTalkTerms --batch Install --config /tmp/install_config.txt && \
	rm -rf /tmp/vivado

#Source settings in .bashrc of build-user
RUN echo "source /opt/Xilinx/Vivado/$VIVADO_VERSION/settings64.sh" >> /home/build/.bashrc

#Add license
RUN mkdir -p /home/build/.Xilinx
ADD files/Xilinx.lic /home/build/.Xilinx/Xilinx.lic
RUN chown -R build:build /home/build/.Xilinx

#Fix gcc in Vivado_HLS
#FIXME: doesn't work in 2017.3 anymore. Not necessary anymore?
#RUN cp /usr/lib/x86_64-linux-gnu/crt?.o /opt/Xilinx/Vivado_HLS/$VIVADO_VERSION/lnx64/tools/gcc/lib/gcc/x86_64-unknown-linux-gnu/*/

#Fix Vivado SDK in headless mode
RUN sed -i -e "s:xlsclients  > /dev/null 2>\&1:/usr/bin/xlsclients  > /dev/null 2>\&1:g" /opt/Xilinx/SDK/$VIVADO_VERSION/bin/xsct

#entrypoint script
ADD files/entrypoint.sh /bin/entrypoint.sh
RUN chmod +x /bin/entrypoint.sh

#Start init system on entry
ENTRYPOINT ["/bin/entrypoint.sh"]
