$ ->

  # for HTML5 Canvas
  spectrum = document.querySelector('#Spectrum').getContext('2d')
  result = document.querySelector('#Result').getContext('2d')
  spectrum.fillStyle = '#ffffff';
  spectrum.fillRect(0, 0, spectrum.canvas.width, spectrum.canvas.height);
  result.fillStyle = '#ffffff';
  result.fillRect(0, 0, result.canvas.width, result.canvas.height);
  last_filter = $('input[name=filter]:checked').val()



  # set interaction
  $('#radius-Slider').slider
    step: 1, 
    min: 0, 
    max: 128
    value: 20
  $('#Filter').buttonset();
  $('#background-Slider').slider
    step: 1,
    min: 0,
    max: 100,
    value: 10

  opts_last_filter =
    background_level: $('#background-Slider').slider('option', 'value')

  # Load image
  init_image = (image) ->
    image.addEventListener 'load', (e) ->
      w = image.width
      h = image.height # w == h
      w = 256
      h = 256
      re = []
      im = []  

      try
        # initialize, radix-2 required
        FFT.init(w)
        FrequencyFilter.init(w)
        SpectrumViewer.init(spectrum)
      catch e
        alert e


      $('#Filter').change (e) ->  
        last_filter = e.target.value
        apply(e.target.value)
      $('#radius-Slider').slider
        change: (e, ui) -> apply last_filter, opts_last_filter
      $('#background-Slider').slider
        change: (e, ui) -> 
          opts_last_filter.background_level = $('#background-Slider').slider('option', 'value')
          apply last_filter, opts_last_filter
      $('input').change ->
        apply last_filter, opts_last_filter

      apply = (type,opts = {}) ->
        try
          spectrum.drawImage(image, 0, 0)
    
          src = spectrum.getImageData(0, 0, w, h)
          data = src.data
          radius = $('#radius-Slider').slider('option', 'value')

          
          for y in [0...h]
            i = y*w
            for x in [0...w]
              if type == 'WFT'
                dist = Math.sqrt((x-opts.center.x)*(x-opts.center.x)+(y-opts.center.y)*(y-opts.center.y))
                if dist < radius then re[i + x] = data[(i << 2) + (x << 2)] else re[i + x] = 0
              else
                re[i + x] = data[(i << 2) + (x << 2)]
              im[i + x] = 0.0;  

          # 2D-FFT
          FFT.fft2d(re, im);  

          # swap quadrant
          FrequencyFilter.swap(re, im);  

          re_orig = []
          im_orig = [] 
          for y in [0...h]
            i = y*w
            for x in [0...w]
              re_orig[i + x]   = re[i + x] 
              im_orig[i + x]   = im[i + x]          

          switch type     
            # High Pass Filter     
            when 'HPF' then FrequencyFilter.HPF(re, im, radius)  
            # Low Pass Filter
            when 'LPF' then FrequencyFilter.LPF(re, im, radius) 
            # Analytic Part Filtering
            when 'APF' then FrequencyFilter.APF(re,im,opts.center, radius)
       
          # # Band Path Filter
          # FrequencyFilter.BPF(re, im, radius, radius/2);  

          # # pas encore au point...
          # if opts.background_level > 0 && type != 'WFT'
          #   for y in [0...h]
          #     i = y*w
          #     for x in [0...w]
          #       re_orig[i + x]   = re[i + x]*(100-opts.background_level)/100 +  (opts.background_level/100)*re_orig[i + x]
          #       im_orig[i + x]   = im[i + x]*(100-opts.background_level)/100 +  (opts.background_level/100)*im_orig[i + x]   



          # render spectrum
          if $('#view-type').is(':checked')
            SpectrumViewer.render re, im, true  
          else
            SpectrumViewer.render re, im, false

          # swap quadrant
          FrequencyFilter.swap(re, im);  

          # 2D-IFFT
          FFT.ifft2d(re, im)

          switch $('input[name=filtered-view]:checked').val()
            # when "real-part" # nothing to do
            when "modulus-part"
              for y in [0...h]
                i = y*w
                for x in [0...w]
                  re[i+x] = Math.sqrt(re[i+x]*re[i+x]+im[i+x]*im[i+x])


          if opts.background_level > 0 
            for y in [0...h]
              i = y*w
              for x in [0...w]
                re_orig[i + x]   = data[(i << 2) + (x << 2)]


          if $('#normalize-filtered').is(':checked')
          # normalisation si desiré
            max = re[0]
            min = re[0]
            for y in [0...h]
              i = y*w
              for x in [0...w]
                val = re[i + x]
                max = val if val > max
                min = val if val < min

            for y in [0...h]
              i = y*w
              for x in [0...w]
                val = re[i + x];
                p = (i << 2) + (x << 2);
                data[p] = data[p + 1] = data[p + 2] = (val-min)/(max-min)*255  
          else
            for y in [0...h]
              i = y*w
              for x in [0...w]
                val = re[i + x];
                p = (i << 2) + (x << 2);
                data[p] = data[p + 1] = data[p + 2] = val  

          # ajout du background
          if opts.background_level > 0 && type == 'WFT'
            for y in [0...h]
              i = y*w
              for x in [0...w]
                val = re[i + x] * (100-opts.background_level)/100 + opts.background_level/100*re_orig[i + x]
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

          last_filter = 'APF'
          opts_last_filter.center = 
            x: x_pos
            y: y_pos
          apply 'APF', opts_last_filter

      $("#Result").on 'click', (e) ->
          p = $(this).offset()
          x_pos = e.pageX-p.left
          y_pos = e.pageY-p.top
          $("#im-xposition").html(x_pos)
          $("#im-yposition").html(y_pos)

          last_filter = 'WFT'
          opts_last_filter.center=
            x: x_pos
            y: y_pos
          apply 'WFT', opts_last_filter

      apply last_filter, opts_last_filter

    , false


  image = new Image()  
  image.src = 'images/motobecane.jpg'
  init_image image

  $('#load-image-form').submit (e) ->
    e.preventDefault()
    image = new Image()  
    image.src = $(this).find('input').val()
    $('#Original')[0].src = image.src
    $('#image-name').html image.src


    
    init_image image
    




