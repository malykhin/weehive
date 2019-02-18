# split downloads so the layers are cached independently, and the .tar.gzs aren't included in the final image (reducing the size)
# https://medium.com/@tonistiigi/advanced-multi-stage-build-patterns-6f741b852fae

FROM alpine as hadoop

ARG HADOOP_VERSION=3.2.0

# download remotely
RUN wget http://apache.osuosl.org/hadoop/common/stable/hadoop-$HADOOP_VERSION.tar.gz
RUN tar -xzf hadoop-$HADOOP_VERSION.tar.gz

# copy from local
# ADD hadoop-$HADOOP_VERSION.tar.gz .

RUN mv hadoop-$HADOOP_VERSION hadoop


FROM alpine as hive

ARG HIVE_VERSION=3.1.1

# download remotely
RUN wget http://mirrors.advancedhosters.com/apache/hive/hive-$HIVE_VERSION/apache-hive-$HIVE_VERSION-bin.tar.gz
RUN tar -xzf apache-hive-$HIVE_VERSION-bin.tar.gz

# copy from local
# ADD apache-hive-$HIVE_VERSION-bin.tar.gz .

RUN mv apache-hive-$HIVE_VERSION-bin hive
# https://stackoverflow.com/a/41789082/358804
RUN rm hive/lib/log4j-slf4j-impl-2.10.0.jar


# https://www.digitalocean.com/community/tutorials/how-to-install-hadoop-in-stand-alone-mode-on-ubuntu-18-04

FROM ubuntu:bionic

WORKDIR /usr/local/hadoop

RUN apt-get update && apt-get install -y openjdk-8-jdk
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/

COPY --from=hadoop /hadoop hadoop
ENV HADOOP_HOME /usr/local/hadoop/hadoop
ENV PATH="${HADOOP_HOME}/bin:${PATH}"

COPY --from=hive /hive hive
ENV HIVE_HOME /usr/local/hadoop/hive
ENV PATH="${HIVE_HOME}/bin:${PATH}"
COPY hive-site.xml $HIVE_HOME/conf/

# https://cwiki.apache.org/confluence/display/Hive/GettingStarted#GettingStarted-RunningHive
RUN hadoop fs -mkdir -p /tmp
RUN hadoop fs -mkdir -p /user/hive/warehouse
RUN hadoop fs -chmod g+w /tmp
RUN hadoop fs -chmod g+w /user/hive/warehouse

# https://cwiki.apache.org/confluence/display/Hive/GettingStarted#GettingStarted-RunningHiveServer2andBeeline.1
RUN schematool -dbType derby -initSchema
CMD beeline -u jdbc:hive2://
