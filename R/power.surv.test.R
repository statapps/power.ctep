power.surv.test=function(n = NULL, sig.level = 0.05, s0 = NULL, s1 = NULL, year = 3,
                         accrual = 3, followup = 3, futile = NULL, futile.prob = 0.01,
                         power = NULL, tol = .Machine$double.eps^0.25){
  if (sum(sapply(list(n, s1, power), is.null)) != 1) 
    stop("exactly one of 'n', 's1', 'power', must be NULL")

  lambda0 = -log(s0)/year
  a = accrual
  b = followup
  dur = a/2+b

  # initial output value for person.year and critical value k
  person.year = 0
  k = 0
  p.body = quote({
    lambda1 = -log(s1)/year
    #person.year = n*(1-exp(-lambda0*followup))/lambda0
    dur = (1-1/(lambda0*a)*exp(-lambda0*b)*(1-exp(-lambda0*a)))/lambda0
    person.year = n*dur
    
    k = qpois(sig.level, person.year*lambda0)
    alpha = ppois(k, person.year*lambda0)

    while(k>0 & alpha > sig.level){
      b = b*1.0001
      dur = (1-1/(lambda0*a)*exp(-lambda0*b)*(1-exp(-lambda0*a)))/lambda0
      person.year = n*dur
      #person.year = n*(1-exp(-lambda0*followup))/lambda0
      alpha =  ppois(k, person.year*lambda0)
    }
    sig.level = alpha

    # lambda*t = n*person.year1*lambda1  
    # get power
    dur1 = 1-1/(lambda1*a)*exp(-lambda1*b)*(1-exp(-lambda1*a))
    #person.year1 = n*dur/lambda1*lambda1
    ppois(k, n*dur1)
  })

  if(is.null(power))
    power = eval(p.body)
  else if (is.null(n))
    n = uniroot(function(n) eval(p.body) - power, c(5 +1e-10, 1e+07), 
                extendInt="upX", tol = tol)$root
  else if (is.null(s1))
    s1 = uniroot(function(s1) eval(p.body) - power, c(s0, 0.99))$root

  n = ceiling(n)
  power = eval(p.body)
  lambda = k/person.year
  crtl.survf= exp(-lambda*year)

  alternative = 'greater'
  NOTE = 'Based on the assumption of Poisson Process'
  METHOD = 'One sample test for survival distribution'

  fit = structure(list(n = n, s0 = s0, s1 = s1, person.year = person.year, median.dur=dur,
     crtl.event = k, crtl.survf = crtl.survf, sig.level = sig.level, 
     power = power, alternative = alternative, 
     note = NOTE, method = METHOD), class = "power.htest")

  if(is.numeric(futile)) {
    lambda1 = -log(s1)/year
    if (futile > 1 | futile < 0) stop("futile shall be between 0 and 1")
    futile.py = person.year*futile
    rate1 = lambda1*futile.py
    futile.event = qpois(1-futile.prob, rate1)
    alpha1 = 1-ppois(futile.event, rate1)
    while(alpha1 < futile.prob*0.995) {
      futile.py = futile.py*1.0001
      rate1 = lambda1*futile.py
      alpha1 = 1-ppois(futile.event, rate1)
    }
    futile.prob = alpha1

    fit = structure(list(n = n, s0 = s0, s1 = s1, person.year = person.year, median.dur = dur,
    crtl.event = k, crtl.survf = crtl.survf, sig.level = sig.level, power = power, 
    futile.pyear = futile.py, futile.event = futile.event, futile.prob = futile.prob, 
    alternative = alternative, note = NOTE, method = METHOD), class = "power.htest")
  }
  return(fit)
}

