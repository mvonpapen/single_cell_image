# use latest Ubuntu version
FROM ubuntu:latest

MAINTAINER Michael von Papen

# for the sanity of python packages
ENV LC_ALL C.UTF-8
ENV LANG C.UTF-8

# updates and installs
RUN apt-get update -y && apt-get upgrade -y
RUN apt-get install -y emacs \
                       wget \ 
					   bzip2 \
					   git \
					   vim \
					   binutils \
					   libgl1-mesa-glx \
					   sudo \
					   gcc

# Add user ubuntu with no password, add to sudo group
RUN adduser --disabled-password --gecos '' ubuntu
RUN adduser ubuntu sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER ubuntu
WORKDIR /home/ubuntu/
RUN chmod a+rwx /home/ubuntu/

# install Anaconda
RUN wget https://repo.anaconda.com/archive/Anaconda3-2019.03-Linux-x86_64.sh
RUN bash Anaconda3-2019.03-Linux-x86_64.sh -b
RUN rm Anaconda3-2019.03-Linux-x86_64.sh

# Set path to conda
ENV PATH /home/ubuntu/anaconda3/bin:$PATH

# Updating Anaconda packages
RUN conda update conda
RUN conda update anaconda
RUN conda update --all

# Install best practices environment (Luecken & Theis, 2019)
RUN git clone https://github.com/theislab/single-cell-tutorial
RUN conda env create -f single-cell-tutorial/sc_tutorial_environment.yml
RUN cd /home/ubuntu/anaconda3/envs/sc-tutorial && \
    mkdir -p ./etc/conda/activate.d && \
    mkdir -p ./etc/conda/deactivate.d && \
    touch ./etc/conda/activate.d/env_vars.sh && \
    touch ./etc/conda/deactivate.d/env_vars.sh
RUN echo '#!/bin/sh\n\
CFLAGS_OLD=$CFLAGS\n\
export CFLAGS_OLD\n\
export CFLAGS="`gsl-config --cflags` ${CFLAGS_OLD}"\n\
LDFLAGS_OLD=$LDFLAGS\n\
export LDFLAGS_OLD\n\
export LDFLAGS="`gsl-config --libs` ${LDFLAGS_OLD}"' \
>>/home/ubuntu/anaconda3/envs/sc-tutorial/etc/conda/activate.d/env_vars.sh
RUN echo '#!/bin/sh\n\
CFLAGS=$CFLAGS_OLD\n\
export CFLAGS\n\
unset CFLAGS_OLD\n\
LDFLAGS=$LDFLAGS_OLD\n\
export LDFLAGS\n\
unset LDFLAGS_OLD' \
>>/home/ubuntu/anaconda3/envs/sc-tutorial/etc/conda/deactivate.d/env_vars.sh

# automatically start env in bash
SHELL ["/bin/bash", "-c"]
RUN echo "source activate sc-tutorial" > ~/.bashrc
ENV PATH /home/ubuntu/anaconda3/envs/sc-tutorial/bin:$PATH

# install R packages into conda environment
ADD install_R_pkgs.R /tmp/
RUN R -f /tmp/install_R_pkgs.R

# Apply bugfix to anndata's h5sparse.py
# (_set_many function crashes if x is scalar)
RUN wget -O /home/ubuntu/anaconda3/envs/sc-tutorial/lib/python3.7/site-packages/anndata/h5py/h5sparse.py https://raw.githubusercontent.com/theislab/anndata/master/anndata/h5py/h5sparse.py

# install nbextensions for fancy notebook
RUN conda install -y --name sc-tutorial -c conda-forge jupyter_contrib_nbextensions

# Run jupyter notebook and export as html
CMD jupyter notebook --ip=0.0.0.0 --port=8888 --no-browser
