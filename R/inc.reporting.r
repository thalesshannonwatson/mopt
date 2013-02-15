plot.mopt_config <- function(mopt,what='all',pd=NA,taildata=0,filename=mopt$file_chain) {

  graphs = c('pdistr','ptime','mdistr','pmpoints','pmreg','vtime','mtime','all','mtable')

  if (length(setdiff(what,graphs))>0) {
    cat("what should be 'all' or a subset of ", paste(graphs,collapse=','), '\n')
    return(NULL)
  }

  if ('all' %in% what) what = graphs;

  source('~/git/Utils/R/ggtable2.r')

  load(filename)

  mnames = grep('submoments.',names(param_data),value=TRUE)
  datamnames = grep('submoments.data',names(param_data),value=TRUE)
  mnames = setdiff(mnames, datamnames)

  if ( taildata>0 )  param_data = tail(param_data,taildata);

  # reporting the distributions of the parameters
  if ('pdistr' %in% what) {
    quartz()
    # we also want to append the best param value
    I = which(param_data$value == min(param_data$value,na.rm=TRUE))
    best_data = param_data[I,]

    gp <- ggplot(melt(subset(param_data,chain==min(param_data$chain)),measure.vars=mopt$params_to_sample,id=c()),aes(x=value)) +
        geom_vline(aes(xintercept=value),data = melt(best_data,measure.vars=mopt$params_to_sample,id=c()),color='blue',linetype=2,size=0.3) +
        stat_density(fill='blue',alpha=0.5) + facet_wrap(~variable,scales='free')
    print(gp)
  }

  # reporting the evolution of the objective value
  if ('vtime' %in% what) {
    param_data$iter = 1:nrow(param_data)
    gp <- ggplot(param_data,aes(x=iter,y=value,color=chain)) + geom_line()
    print(gp)
  }

  # graph all moments
  if ('mdistr' %in% what) {
    quartz()
    gdata = melt(rename(param_data,c(value='objvalue')),measure.vars=mnames,id=c('objvalue'))
    gdata$variable = gsub('submoments.','',gdata$variable)
    save(gdata,file='tmp.dat')
    gp <- ggplot(gdata,aes(x=value)) + 
          geom_density(fill='blue',alpha=0.4,size=0) + 
          geom_vline(aes(xintercept=value),
                     data=data.frame(variable=mopt$data.moments$moment,
                                     value   =mopt$data.moments$value),
                     linetype=2,color='red')+
          facet_wrap(~variable,scales='free')
    print(gp)
  }

  # graph link between parameters and moments
  if ('pmpoints' %in% what) {
    quartz()
    gdata = melt(rename(param_data,c(value='objvalue')),measure.vars=mopt$params_all,id=c('objvalue'))
    gp <- ggplot(gdata,aes(x=value,y=objvalue)) + geom_point() + facet_wrap(~variable,scales='free')
    print(gp)
  }

  # link between submoments and parameters
  if ('pmreg' %in% what) {
    RHS = paste('log(',mopt$params_to_sample,')',sep= '',collapse=' + ')
    rr = data.frame()
    # we also want to weight the observations by how close they are to the optimal
    param_data$lmw = 1/(0.01+(param_data$value - min(param_data$value)))

    for ( ms in c(mnames,'log(value)') ) {
      fit = lm(paste(ms,'~',RHS),param_data,weights=lmw)
      r = model2frame(fit)
      r$dep = ms
      rr = rbind(rr,r)
    }
    rr = subset(rr,!variable %in% c('BIC','(Intercept)'))
    rr$dep = gsub('submoments.','',rr$dep)

    ggt <- ggtable(dep ~ variable) + ggt_cell_regression(rr,list(value='value',sd='sd',pval='pval')) +
           ggt_order('variable',mopt$params_to_sample) +
           ggt_order('dep',gsub('submoments.','',mnames))
    ggt$params$resize=0.7
    print(ggt);
  }

  # moment table 
  if ('pmreg' %in% what) {
    RHS = paste('log(',mopt$params_to_sample,')',sep= '',collapse=' + ')
    rr = data.frame()
    # we also want to weight the observations by how close they are to the optimal
    param_data$lmw = 1/(0.01+(param_data$value - min(param_data$value)))

    for ( ms in c(mnames,'log(value)') ) {
      fit = lm(paste(ms,'~',RHS),param_data,weights=lmw)
      r = model2frame(fit)
      r$dep = ms
      rr = rbind(rr,r)
    }
    rr = subset(rr,!variable %in% c('BIC','(Intercept)'))
    rr$dep = gsub('submoments.','',rr$dep)

    ggt <- ggtable(dep ~ variable) + ggt_cell_regression(rr,list(value='value',sd='sd',pval='pval')) +
           ggt_order('variable',mopt$params_to_sample) +
           ggt_order('dep',gsub('submoments.','',mnames))
    ggt$params$resize=0.6
    print(ggt);
  }

  if ('ptime' %in% what) {
    quartz()
    param_data$t = c(1:nrow(param_data))
    gdata = melt(rename(param_data,c(value='objvalue')),measure.vars=mopt$params_to_sample,id=c('t'))
    gp <- ggplot(gdata,aes(x=t,y=value)) + geom_point(size=0.5,color='red') + facet_wrap(~variable,scales='free')
    print(gp)
  }

  if ('mtime' %in% what) {
    quartz()
    param_data$t = c(1:nrow(param_data))
    gdata = melt(rename(param_data,c(value='objvalue')),measure.vars=mnames,id=c('t'))
    gdata$variable = gsub('submoments.','',gdata$variable)
    gp <- ggplot(gdata,aes(x=t,y=value)) + 
          geom_point(size=0.5) + 
          geom_hline(aes(yintercept=value,x=NULL,y=NULL),
                     data=data.frame(value = mopt$moments.data,
                     variable=names(mopt$moments.data)),
                     linetype=2,color='red')+
          facet_wrap(~variable,scales='free')
    print(gp)
  }

  if ('mtable' %in% what) {
    source('~/git/Utils/R/ggtable2.r')
    # get the optimal value of the submoments
    i = which.min(param_data$value)
    rr = t(param_data[i,])
    rr = data.frame(from='model',moment = rownames(rr),value = c(rr),sd=NA)
    rr = subset(rr,str_detect(rr$moment,'submoments.model'))
    rr$moment = str_replace( rr$moment,'submoments\\.model\\.','')
   
    dd = mopt$data.moments
    dd = subset(dd,moment %in% rr$moment)
    dd$from = 'data'
    rr = rbind(rr,dd)

    rownames(rr) <- NULL
    rr$pval=NA

    save(rr,file='tmp2.dat')
    ggt <- ggtable(moment ~ from) + ggt_cell_regression(rr,list(value='value',sd='sd',pval='pval'))
    print(ggt)
  }

}

print.mopt_config <- function(mopt) {

}


mopt.newconf <- function(name) {

filename_make = 'Makefile'

if (file.exists(cf$file_chain)) {
  cat('Makefile already exists in current folder, saving to MakeMpi.inc\n')
  filename_make = 'MakeMpi.inc'
}

# creating and saving the make file
STR = 'runmpi:
	qsub qsub_start_mpi.sh 

clean:
	rm -rf *.out *.rout

tail:
	tail -f ./mpi_PROJECTNAME.out
'  
STR = gsub('PROJECTNAME',name,STR)
cat(STR,file=filename_make)

}

# return some versions of the parameters
predict.mopt_config <- function(cf,what='p.all') {

  # first type, is to return the parameters with the highest value
  load(cf$file_chain)
  I = which(param_data$value == min(param_data$value,na.rm=TRUE))[[1]]

  if (what=='p.all') {
    pres = c(param_data[I,intersect(cf$params_all,names(param_data))])
    pres = c(pres,cf$initial_value[ setdiff(names(cf$initial_value),names(pres)) ])
    return(pres)
  } 
  
  if (what=='p.free') {
    p = c(param_data[I,cf$params_to_sample])
  }

  if (what=='p.sd') {
    VV = sqrt(diag(cov(param_data[param_data$chain==1,cf$params_to_sample])))
    p = c(param_data[I,cf$params_to_sample])
    return(data.frame(name = cf$params_to_sample, value = unlist(p), sd = c(VV)))
  }

  if (what=='moments') {
    mnames = grep('submoments.',names(param_data),value=TRUE)
    datamnames = grep('submoments.data',names(param_data),value=TRUE)
    mnames = setdiff(mnames, datamnames)
    return(param_data[I,mnames])
  }

  return(p)
}


mopt.test <- function() {

  # graph the effect of each paramter on each moment
  





} 