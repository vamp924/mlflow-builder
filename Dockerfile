FROM debian:sid-slim

ARG CRAN_URL="https://cran.cmm.msu.ru/"

ENV MLFLOW_DISABLE_ENV_CREATION=true MLFLOW_PYTHON_BIN=/usr/bin/python3 MLFLOW_BIN=/usr/local/bin/mlflow

# install mlflow + python3 backend (without conda)
RUN apt-get update && \
    apt-get install -y --no-install-recommends python3 python3-pip curl && \
    rm -rf /var/lib/apt/lists/*
RUN pip3 install --no-cache-dir setuptools && \
    pip3 install --no-cache-dir mlflow==1.9.0 boto3 && \
    chmod 4755 ${MLFLOW_BIN} && \
    chmod -R 777 /usr/local/lib/python3.8/dist-packages

# install R backend and compilers
RUN apt-get update && \
    apt-get install -y --no-install-recommends r-base libcurl4-openssl-dev libssl-dev libxml2-dev zlib1g-dev gcc make g++ gfortran && \
    rm -rf /var/lib/apt/lists/* && \
    chmod -R 777 /usr/local/lib/R/site-library
RUN R --vanilla -e "install.packages('mlflow', repo='${CRAN_URL}', clean=TRUE, quiet=TRUE)"

# add user
RUN useradd runner -u 1001 -g 0 -N && \
    mkdir /opt/model && chmod -R 777 /opt/model && \
    mkdir /opt/mlflow && chmod -R 777 /opt/mlflow

# add 'yq' utility for convenience
RUN curl -o /usr/local/bin/yq -L https://github.com/mikefarah/yq/releases/download/3.3.2/yq_linux_amd64 && \
    chmod 777 /usr/local/bin/yq

USER 1001
WORKDIR /opt/model
CMD mlflow models serve -m /opt/model -h 0.0.0.0 -p 8000 --no-conda
