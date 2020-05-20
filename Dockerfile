FROM ubi8/ubi-minimal AS stagezero

ENV PATH="/miniconda/bin:$PATH"
ENV JAVA_HOME="/usr/lib/jvm/java-1.8.0-openjdk"

RUN microdnf install wget bzip2 && microdnf clean all

RUN microdnf install maven && microdnf clean all && \
        mvn  --batch-mode dependency:copy -Dartifact=org.mlflow:mlflow-scoring:1.6.0:pom -DoutputDirectory=/opt/java && \
        mvn  --batch-mode dependency:copy -Dartifact=org.mlflow:mlflow-scoring:1.6.0:jar -DoutputDirectory=/opt/java/jars && \
        cp /opt/java/mlflow-scoring-1.6.0.pom /opt/java/pom.xml && \
        cd /opt/java && mvn --batch-mode dependency:copy-dependencies -DoutputDirectory=/opt/java/jars

RUN wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /miniconda.sh && bash /miniconda.sh -b -p /miniconda; rm /miniconda.sh && conda install --yes nomkl && conda clean -afy

FROM ubi8/ubi-minimal

COPY --from=stagezero /opt /opt
COPY --from=stagezero /miniconda /miniconda

LABEL maintainer="Gleb Mitin glmitin@gmail.com"

ENV PATH="/miniconda/bin:$PATH"
ENV JAVA_HOME="/usr/lib/jvm/java-1.8.0-openjdk"
ENV GUNICORN_CMD_ARGS="--timeout 60 -k gevent"
ENV DISABLE_NGINX="true"

RUN microdnf --nodocs update -y && microdnf --nodocs install wget bzip2 shadow-utils && rm -rf /var/cache/yum && microdnf clean all

RUN useradd runner -u 1001 -g 0 -N

WORKDIR /opt/mlflow

RUN chmod -R g+w /opt && chmod -R g+u /miniconda

USER 1001

RUN pip install --no-cache-dir mlflow==1.6.0 boto3

EXPOSE 8000
