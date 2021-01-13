FROM ubuntu:20.04

RUN apt-get update && apt-get install -y wget git gcc

# place to keep our app and the data
RUN mkdir -p /app /app/tails /app/models /data /data/logs /_tmp

# install miniconda
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh && \
    mkdir -p /opt && \
    sh miniconda.sh -b -p /opt/conda && \
    rm miniconda.sh && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc && \
    find /opt/conda/ -follow -type f -name '*.a' -delete && \
    find /opt/conda/ -follow -type f -name '*.js.map' -delete && \
    /opt/conda/bin/conda clean -afy && \
    apt-get clean

# copy over the config and the code
COPY ["config.yaml", "setup.py", "ztf-watchdog-service/", "ztf-watchdog-service/tests/", "/app/"]
COPY ["tails", "/app/tails"]
COPY ["models", "/app/models"]

WORKDIR /app

# install service requirements, swarp, and tails; generate supervisord conf file
RUN /opt/conda/bin/conda install -c conda-forge astromatic-swarp && \
    /opt/conda/bin/pip install -U pip && \
    /opt/conda/bin/python setup.py install && \
    /opt/conda/bin/pip install -r requirements.txt --no-cache-dir && \
    /opt/conda/bin/python generate_supervisor_conf.py watcher

RUN ln -s /opt/conda/bin/swarp /bin/swarp

# run container
#RUN touch /app/1.txt
#CMD tail -f 1.txt
CMD /opt/conda/bin/supervisord -n -c supervisord_watcher.conf
