;+
; Plots histograms of the sph_data available.
;-
;sph_data = structure with the info of the pfss-model
;refangle = reference angle, the longitude of the flare site or
;such. in dergrees.
;linekind = an array describing the type of fieldlines, 2 meand open
;fieldline, we use those.

;Calling sequence: histogram2, sph_data, flaresite=flaresite, time=time, before=before, after=after, directory=directory, name=name, beta

pro histogram2, sph_data, flaresite=flaresite, time=time, before=before, after=after, directory=directory, name=name, beta
  
  ;Data from the structure: 
  nstep = *sph_data.nstep
  ptph = *sph_data.ptph
  ptth = *sph_data.ptth

  ; point of each line
  numberoflines = n_elements(nstep)
  latitudes = fltarr(numberoflines)
  longitudes = fltarr(numberoflines)
  for i=0, numberoflines-1 do begin
     latitudes[i] = 90 - (180/!pi)* ptth[0,i]
     longitudes[i] = (180/!pi)* ptph[0,i]
  endfor

  ;an array for the angle data:
  Dphi = fltarr(numberoflines)
  for i=0 , numberoflines-1 do begin
        Dphi[i] = (180/!pi)* acos( cos(!dtor*latitudes[i]) $
                                   *cos(!dtor*(flaresite[1])) $
                                   *cos(!dtor*(longitudes[i]-flaresite[0])) $
                                   + sin(!dtor*latitudes[i]) $
                                   *sin(!dtor*flaresite[1]) )
  endfor
  
  if before eq 1 then begin
     title = time + ' before, '+ strtrim(string(numberoflines),1) + ' field lines. Traced from the source surface.'
  endif
  if after eq 1 then begin
     title = time + ' after, '+ strtrim(string(numberoflines),1) + ' field lines. Traced from the source surface.'
  endif
  
  binsize = 1
  hist = HISTOGRAM(Dphi, binsize=binsize)
  xaxis = FINDGEN(N_ELEMENTS(hist))*binsize + MIN(Dphi)
  p = barplot(xaxis, hist, color="blue", $
              xrange=[0, Max(xaxis)+binsize], $
              yrange=[0, MAX(hist)+1], title=title, ytitle='Number of lines', $
              xtitle='$\Delta \phi$  [degrees]')
  
   ;save histogram
   if before eq 1 then begin
      filename = directory+'/barplot_'+name+'_before.png'
   endif
   if after eq 1 then begin
      filename = directory+'/barplot_'+name+'_after.png'
   endif
   p.save, filename
   
   ;save histogram_data
   if before eq 1 then begin
      filename = directory+'/beta_'+name+'_before.sav'
   endif
   if after eq 1 then begin
      filename = directory+'/beta_'+name+'_after.sav'
   endif
   save, Dphi, filename=filename

   beta = min(Dphi)
   
  
 return

end
