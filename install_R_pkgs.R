# install R packages for sc-tutorial
install.packages(c('devtools', 'gam', 'RColorBrewer', 'BiocManager'), repos='http://cran.us.r-project.org')
update.packages(ask=F, repos='http://cran.us.r-project.org')
BiocManager::install(c('scran','MAST','monocle','ComplexHeatmap','slingshot'), version='3.8')