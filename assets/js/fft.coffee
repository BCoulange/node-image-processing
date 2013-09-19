$ ->

  # for HTML5 Canvas
  spectrum = document.querySelector('#Spectrum').getContext('2d')
  result = document.querySelector('#Result').getContext('2d')
  spectrum.fillStyle = '#ffffff';
  spectrum.fillRect(0, 0, spectrum.canvas.width, spectrum.canvas.height);
  result.fillStyle = '#ffffff';
  result.fillRect(0, 0, result.canvas.width, result.canvas.height);

  # set interaction
  $('#Slider').slider
    step: 1, 
    min: 0, 
    max: 128
  $('#Filter').buttonset();

  # Load image
  image = new Image()  

  image.src = 'images/motobecane.jpg'
  image.addEventListener 'load', (e) ->
    w = image.width
    h = image.height # w == h
    re = []
    im = []  

    try
      # initialize, radix-2 required
      FFT.init(w)
      FrequencyFilter.init(w)
      SpectrumViewer.init(spectrum)
    catch e
      alert e


    $('#Filter').change (e) ->  apply(e.target.value)
    $('#Slider').slider
      change: (e, ui) -> apply($('input[name=filter]:checked').val())

   
    apply = (type,opts = {}) ->
      try
        spectrum.drawImage(image, 0, 0)
    
        src = spectrum.getImageData(0, 0, w, h)
        data = src.data
        radius = $('#Slider').slider('option', 'value')
        viewtype = $('input[name=view]:checked').val()
        
        for y in [0...h]
          i = y*w
          for x in [0...w]
            re[i + x] = data[(i << 2) + (x << 2)]
            im[i + x] = 0.0;  

        # 2D-FFT
        FFT.fft2d(re, im);  

        # swap quadrant
        FrequencyFilter.swap(re, im);  

        switch type     
          # High Pass Filter     
          when 'HPF' then FrequencyFilter.HPF(re, im, radius)  
          # Low Pass Filter
          when 'LPF' then FrequencyFilter.LPF(re, im, radius) 
          # Analytic Part Filtering
          when 'APF' then FrequencyFilter.APF(re,im,opts.center, radius)
     
        # # Band Path Filter
        # FrequencyFilter.BPF(re, im, radius, radius/2);  

        # render spectrum
        if viewtype == "0"
          SpectrumViewer.render re, im, true  
        else
          SpectrumViewer.render re, im, false

        # swap quadrant
        FrequencyFilter.swap(re, im);  

        # 2D-IFFT
        FFT.ifft2d(re, im)
        for y in [0...h]
          i = y*w
          for x in [0...w]
            val = re[i + x];
            p = (i << 2) + (x << 2);
            data[p] = data[p + 1] = data[p + 2] = val  

        # put result image on the canvas
        result.putImageData(src, 0, 0);
      catch e
        alert e

    checkTypedArray = ->
      try
        u8 = new Uint8Array(1)
        f64 = new Float64Array(1)
      catch e
        console.log(e);

    $("#Spectrum").on 'click', (e) ->
        p = $(this).offset()
        x_pos = e.pageX-p.left-$(this).width()/2
        y_pos = e.pageY-p.top-$(this).height()/2
        $("#xposition").html(x_pos)
        $("#yposition").html(y_pos)

        apply 'APF',
          center:
            x: x_pos
            y: y_pos
        

  , false








