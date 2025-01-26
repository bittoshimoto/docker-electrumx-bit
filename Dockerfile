FROM python:3.8

WORKDIR /root/

# Install necessary dependencies
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y libleveldb-dev curl gpg ca-certificates tar dirmngr && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Download and verify Bit binaries
RUN curl -Lk -o bit-v.1.2.7.tar.gz https://github.com/bittoshimoto/Bit/releases/download/v.1.2.7/bit-v.1.2.7.tar.gz && \
    mkdir -p bit-v.1.2.7 && \
    tar -xvf bit-v.1.2.7.tar.gz -C bit-v.1.2.7 && \
    rm bit-v.1.2.7.tar.gz && \
    install -m 0755 -o root -g root -t /usr/local/bin bit-v.1.2.7/* && \
    rm -rf bit-v.1.2.7

# Install Python modules
RUN pip install uvloop

# Clone the specific version of the ElectrumX server repository and install
RUN git clone --branch main https://github.com/bittoshimoto/electrumx-bit.git && \
    cd electrumx-bit && \
    pip3 install .

# Copy the entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Prepare Bit configuration
RUN mkdir -p /root/.bit
COPY bit.conf /root/.bit/bit.conf

# Generate placeholder SSL certificates (replace with real ones in production)
RUN mkdir -p /data && \
    openssl req -x509 -newkey rsa:2048 -keyout /data/electrumx-bit.key -out /data/electrumx-bit.crt -days 365 -nodes -subj "/CN=localhost"

# Define persistent storage volume
VOLUME ["/data"]

# Define environment variables
ENV HOME /data
ENV ALLOW_ROOT 1
ENV COIN=Shibacoin
ENV DAEMON_URL=http://shibacoin:noicabihs@127.0.0.1:22555
ENV EVENT_LOOP_POLICY uvloop
ENV DB_DIRECTORY /data
ENV SERVICES=tcp://:50001,ssl://:50002,wss://:50004,rpc://0.0.0.0:8000
ENV SSL_CERTFILE=${DB_DIRECTORY}/electrumx-shibacoin.crt
ENV SSL_KEYFILE=${DB_DIRECTORY}/electrumx-shibacoin.key
ENV HOST ""

WORKDIR /data

# Expose necessary ports
EXPOSE 50001 50002 50004 8000

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
