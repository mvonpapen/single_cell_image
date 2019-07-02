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

# Configuring access to Jupyter (pw="root")
RUN mkdir /home/ubuntu/notebooks
RUN jupyter notebook --generate-config
RUN echo 'c.NotebookApp.token = ""' >> /home/ubuntu/.jupyter/jupyter_notebook_config.py

# Jupyter listens port: 8888
EXPOSE 8888

# # Download Haber 2017 data
# RUN mkdir -p /home/ubuntu/single-cell-tutorial/data/Haber-et-al_mouse-intestinal-epithelium/
# RUN mkdir -p /home/ubuntu/single-cell-tutorial/data/Haber-et-al_mouse-intestinal-epithelium/GSE92332_RAW
# RUN wget ftp://ftp.ncbi.nlm.nih.gov/geo/series/GSE92nnn/GSE92332/suppl/GSE92332_RAW.tar
# RUN tar -C /home/ubuntu/single-cell-tutorial/data/Haber-et-al_mouse-intestinal-epithelium/GSE92332_RAW -xvf GSE92332_RAW.tar
# RUN cd /home/ubuntu/single-cell-tutorial/data/Haber-et-al_mouse-intestinal-epithelium && gunzip GSE92332_RAW/*_Regional_*

CMD jupyter nbconvert --ExecutePreprocessor.timeout=None --to notebook --execute /home/ubuntu/single-cell-tutorial/latest_notebook/Case-study_Mouse-intestinal-epithelium_1906.ipynb && jupyter nbconvert /home/ubuntu/single-cell-tutorial/latest_notebook/Case-study_Mouse-intestinal-epithelium_1906.ipynb