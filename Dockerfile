FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# 1. Instalar dependencias
RUN apt-get update && apt-get install -y software-properties-common && \
    add-apt-repository universe && \
    apt-get update && apt-get install -y \
    build-essential wget libedit-dev libsqlite3-dev libxml2-dev uuid-dev libssl-dev libsrtp2-dev tzdata aptitude sudo

# 2. Descargar y extraer código fuente
WORKDIR /usr/src
RUN wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-20-current.tar.gz && \
    tar -zxvf asterisk-20-current.tar.gz && \
    mv asterisk-20.* asterisk-20

WORKDIR /usr/src/asterisk-20

# 3. Configurar y habilitar módulos
RUN contrib/scripts/install_prereq install
RUN ./configure --with-jansson-bundled --with-pjproject-bundled
RUN make menuselect.makeopts && \
    menuselect/menuselect --enable res_srtp menuselect.makeopts && \
    menuselect/menuselect --enable CORE-SOUNDS-EN-WAV menuselect.makeopts && \
    menuselect/menuselect --enable CORE-SOUNDS-EN-ULAW menuselect.makeopts

# 4. Compilar e instalar
RUN make -j$(nproc) && make install && make config && ldconfig

# 5. Crear usuario y permisos
RUN groupadd asterisk && \
    useradd -r -d /var/lib/asterisk -g asterisk asterisk && \
    usermod -aG audio,dialout asterisk && \
    chown -R asterisk:asterisk /var/lib/asterisk /var/log/asterisk /var/spool/asterisk /usr/lib/asterisk

# 6. Iniciar Asterisk en primer plano
CMD ["asterisk", "-f"]
