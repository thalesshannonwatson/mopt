% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/fun.slices.r
\name{compute.slices2}
\alias{compute.slices2}
\title{Compute the objective function on a grid of params and show custom model output}
\usage{
compute.slices2(mcf, ns = 30, pad = 0.1, file = "est.slices.RData")
}
\arguments{
\item{mcf}{object of class mopt}

\item{ns}{number of points in each dimension to evaluate}

\item{pad}{from bounds of parameter ranges. e.g. p in [0,1], avoid 0 and 1 with pad>0.}

\item{file}{\code{/path/to/your/file.RData}}
}
\value{
list by paramter name, parameter value index, containing the value of the parameter vector and a list \code{data} containing
your custom model output.
}
\description{
Essentially the same as \code{\link{compute.slices}}, but does not report simulated 
moments but other model output. Useful for model output that is multidimensional. 
It's a simplified version of \code{\link{compute.slices}} in that it does not further
process the model output: it return a list with nests "parameter name", "value of parameter",
"model output".
For example instead of reporting the mean of a certain statistic, this function can
return a matrix or a higher dimensional array. Say you want to return the life-cycle
profile of a certain model variable x. This will be a vector of length N, where N is 
the number of periods in the model. The user has to design the MOPT_OBJ_FUN in such a way
that it returns the required output. There are 2 requirements for what \code{MOPT_OBJ_FUN} has to return.
First it has to be a list, second, the list needs components "status" (indicating whether a particular evaluation
is valid in some sense) and "output", which contains your custom model output.
}
\examples{
# generate custom output for a model
require(mopt)

# let's take a dummy objective function
MOPT_OBJ_FUNC <- objfc.norm2.custom(c(0,0),ns=2000)

# starting parameters
p <- list(x1=0.5,x2=0.5)
MOPT_OBJ_FUNC(p)

# then we want to setup the mopt
mcf                  = mopt_config(p)
mcf$wd               = getwd()
mcf$params_to_sample = c('x1','x2')
mcf$mode             = 'multicore'
mcf$algo             = algo.bgp


# set the parameter bounds
mcf <- mcf + 
  samplep('x1',-1,1) +
  samplep('x2',-1,1)


# prepare to run with OpenMP
require(parallel)
options(mc.cores = detectCores())

# finalize the preparation
mcf <- prepare.mopt_config(mcf)

# compute slices and generate plots
res <- compute.slices2(mcf,ns=30,pad=0.1)


}

