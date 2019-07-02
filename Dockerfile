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
RUN echo "source activate sc-tutorial" > ~/.bashrc
ENV PATH /home/ubuntu/anaconda3/envs/sc-tutorial/bin:$PATH

# install missing R packages
RUN echo "install.packages(c('devtools', 'gam', 'RColorBrewer', 'BiocManager'), repos='http://cran.us.r-project.org')\n\
update.packages(ask=F, repos='http://cran.us.r-project.org')\n\
BiocManager::install(c('scran','MAST','monocle','ComplexHeatmap','slingshot'), version='3.8')" > install_R_pkgs.Rscript
RUN bash -c "Rscript install_R_pkgs.Rscript"

# Configuring access to Jupyter (pw="root")
RUN mkdir /home/ubuntu/notebooks
RUN jupyter notebook --generate-config --allow-root
RUN echo "c.NotebookApp.password = u'sha1:6a3f528eec40:6e896b6e4828f525a6e20e5411cd1c8075d68619'" >> /home/ubuntu/.jupyter/jupyter_notebook_config.py

# Jupyter listens port: 8888
EXPOSE 8888

# Run Jupyter notebook as Docker main process
CMD jupyter notebook --ip=0.0.0.0 --port=8888 --no-browser