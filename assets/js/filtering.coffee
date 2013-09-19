# 
#  Spatial Frequency Filtering
#  High-pass/Low-pass/Band-pass Filter
#  Windowing using hamming window
# 

  FrequencyFilter = null # top-level namespace
  _root = this # reference to 'window' or 'global'

  if(typeof exports != 'undefined')
    FrequencyFilter = exports;  # for CommonJS
  else
    FrequencyFilter = _root.FrequencyFilter = {};
  

  # core operations
  _n = 0;
  core =
    init : (n) ->
      if(n != 0 && (n & (n - 1)) == 0)
        _n = n;
      else
        throw new Error("init: radix-2 required");
    
    ,
    # swaps quadrant
    swap : (re, im) ->
      len = _n >> 1;
      for y in [0...len]
        yn = y + len;
        for x in [0...len]
          xn = x + len;
          i = x + y*_n;
          j = xn + yn*_n;
          k = x + yn*_n;
          l = xn + y*_n;
          tmp = re[i];
          re[i] = re[j];
          re[j] = tmp;
          tmp = re[k];
          re[k] = re[l];
          re[l] = tmp;
          tmp = im[i];
          im[i] = im[j];
          im[j] = tmp;
          tmp = im[k];
          im[k] = im[l];
          im[l] = tmp;
    ,
    # Analytic part filtering
    APF : (re,im,center,radius) ->
      n2 = _n >> 1
      sqrt = Math.sqrt
      for y in [-n2...n2]
        i = n2 + (y + n2)*_n;
        for x in [-n2...n2]
          r = sqrt((center.x-x)*(center.x-x) + (center.y-y)*(center.y-y))
          p = x + i
          if(r > radius)
            re[p] = im[p] = 0;
    ,

    # applies High-Pass Filter
    HPF : (re, im, radius) ->
      n2 = _n >> 1
      sqrt = Math.sqrt

      for y in [-n2...n2]
        i = n2 + (y + n2)*_n;
        for x in [-n2...n2]
          r = sqrt(x*x + y*y);
          p = x + i;
          if(r < radius)
            re[p] = im[p] = 0;
    ,
    # applies Low-Pass Filter
    LPF : (re, im, radius) ->
      n2 = _n >> 1
      sqrt = Math.sqrt
      for y in [-n2...n2]
        i = n2 + (y + n2)*_n;
        for x in [-n2...n2]
          r = sqrt(x*x + y*y);
          p = x + i;
          if(r > radius)
            re[p] = im[p] = 0;
    ,
    # applies Band-Pass Filter
    BPF : (re, im, radius, bandwidth) ->
      n2 = _n >> 1
      sqrt = Math.sqrt
      for y in [-n2...n2]
        i = n2 + (y + n2)*_n;
        for x in [-n2...n2]
          r = sqrt(x*x + y*y);
          p = x + i;
          if(r < radius || r > (radius + bandwidth))
            re[p] = im[p] = 0
    ,
    # windowing using hamming window
    windowing : (data, inv) ->
      len = data.length
      pi = Math.PI
      cos = Math.cos
      for i in [0...len]
        if(inv == 1)
          data[i] *= 0.54 - 0.46*cos(2*pi*i/(len - 1));
        else
          data[i] /= 0.54 - 0.46*cos(2*pi*i/(len - 1));
 
  # aliases (public APIs)
  apis = ['init', 'swap', 'HPF', 'LPF', 'APF', 'BPF', 'windowing']
  for i in [0...apis.length]
    FrequencyFilter[apis[i]] = core[apis[i]];
