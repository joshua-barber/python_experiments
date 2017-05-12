FROM debian:jessie-slim
MAINTAINER Joshua Barber "j.barber501@gmail.com"

USER root

# Install basic system packages and add /bin/bash as default shell
RUN apt-get update  && \
	apt-get install -yq --no-install-recommends \
		python3-pip \
		python3-dev \
		python3-wheel \
		build-essential \
		wget \
		git \
		uwsgi-emperor \
		uwsgi-plugin-python3 \
		nginx-full \
		bzip2 \
		ca-certificates \
    		sudo \
    		locales \
		pandoc \
		libsm6 \
		libxrender1 \
		libpq-dev \
		swig && \
	rm /bin/sh && ln -s /bin/bash /bin/sh

# Install Tini
RUN wget --quiet https://github.com/krallin/tini/releases/download/v0.10.0/tini && \
    echo "1361527f39190a7338a0b434bd8c88ff7233ce7b9a4876f3315c22fce7eca1b0 *tini" | sha256sum -c - && \
    mv tini /usr/local/bin/tini && \
    chmod +x /usr/local/bin/tini

# Set environment variables
ENV CONDA_DIR=/opt/conda
ENV PATH=/$CONDA_DIR/bin:${PATH}
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV NB_USER jeb
ENV NB_UID 1000
ENV HOME /home/$NB_USER
ENV APP_ACTIVATE="flask run"
ENV ENV_NAME=app-env
ENV FLASK_CONFIG=development
ENV FLASK_APP=run.py

# Create jeb user
RUN useradd -m -s /bin/bash -N -u $NB_UID $NB_USER && \
    mkdir -p $CONDA_DIR && \
    chown $NB_USER $CONDA_DIR
    
USER $NB_USER

# Setup jeb home directory
RUN mkdir /home/$NB_USER/work && \
    mkdir /home/$NB_USER/.jupyter && \
    echo "cacert=/etc/ssl/certs/ca-certificates.crt" > /home/$NB_USER/.curlrc

# Miniconda installation
RUN cd /tmp && \
    mkdir -p $CONDA_DIR && \
    wget --quiet https://repo.continuum.io/miniconda/Miniconda3-4.2.12-Linux-x86_64.sh && \
    /bin/bash Miniconda3-4.2.12-Linux-x86_64.sh -f -b -p $CONDA_DIR && \
    rm Miniconda3-4.2.12-Linux-x86_64.sh && \
    $CONDA_DIR/bin/conda config --system --add channels conda-forge && \
    $CONDA_DIR/bin/conda config --system --set auto_update_conda false && \
    conda clean -tipsy
 
# Install Jupyter Notebook and Hub
RUN conda install -c conda-forge --quiet --yes \
    'notebook=4.3*' \
    'jupyterhub=0.7.2' \
    && conda clean -tipsy
 
# Add shortcuts to distinguish python3 pip env
RUN ln -s $CONDA_DIR/bin/pip $CONDA_DIR/bin/pip3 && \
    pip3 install --upgrade pip
    
# Install Python 3 packages
RUN conda install --quiet --yes \
    'nomkl' \
    'ipywidgets=5.2*' \
    'numpy=1.12*' \
    'protobuf' \
    'pandas=0.19*' \
    'numexpr=2.6*' \
    'matplotlib=1.5*' \
    'scipy=0.18*' \
    'seaborn=0.7*' \
    'scikit-learn=0.18*' \
    'scikit-image=0.12*' \
    'sympy=1.0*' \
    'cython=0.23*' \
    'patsy=0.4*' \
    'statsmodels=0.6*' \
    'cloudpickle=0.1*' \
    'dill=0.2*' \
    'numba=0.31*' \
    'bokeh=0.11*' \
    'sqlalchemy=1.1*' \
    'hdf5=1.8.17' \
    'h5py=2.6*' \
    'vincent=0.4.*' \
    'beautifulsoup4=4.5.*' \
    'datashader=0.4*' \
    'Flask=0.11.1' \
    'psycopg2=2.6.2' \
    'Flask-Login=0.4.0' \
    'Flask-Script=2.0.5' \
    'Flask-SQLAlchemy=2.1' \
    'Flask-Testing=0.6.1' \
    'Flask-WTF=0.14.2' \
    'uwsgi' \
    'xlrd'  && \
    conda remove --quiet --yes --force qt pyqt && \
    conda clean -tipsy

#Add Tensorflow
RUN pip3 install https://storage.googleapis.com/tensorflow/linux/cpu/tensorflow-1.0.0-cp35-cp35m-linux_x86_64.whl \
    'Flask-Bootstrap==3.3.7' \
    'Flask-Migrate==2.0.2'


#Configure PGA4, example at https://github.com/fenglc/dockercloud-pgAdmin4
RUN pip3 install https://ftp.postgresql.org/pub/pgadmin3/pgadmin4/v1.2/pip/pgadmin4-1.2-py3-none-any.whl

WORKDIR /home/$NB_USER

USER root
