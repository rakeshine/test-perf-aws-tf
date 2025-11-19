FROM openjdk:11-jre-slim

# Install dependencies
RUN apt-get update && apt-get install -y wget awscli && rm -rf /var/lib/apt/lists/*

ENV JMETER_VERSION=5.6.3
ENV JMETER_HOME=/opt/apache-jmeter-$JMETER_VERSION
ENV PATH=$JMETER_HOME/bin:$PATH

# Download and extract JMeter
RUN wget https://downloads.apache.org//jmeter/binaries/apache-jmeter-$JMETER_VERSION.tgz && \
    tar -xzf apache-jmeter-$JMETER_VERSION.tgz -C /opt && \
    rm apache-jmeter-$JMETER_VERSION.tgz

WORKDIR /jmeter

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]