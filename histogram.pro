;+
; Plots histograms of the sph_data available.
;-
;
;PARAMETERS
;sph_data = structure with the info of the pfss-model
;refangle = reference angle, the longitude of the flare site or
;such. in dergrees.
;linekind = an array describing the type of fieldlines, 2 meand open
;fieldline, we use those.

;Calling sequence: histogram, sph_data, flaresite=flaresite, linekind=linekind, time=time, before=before, after=after, date=date

pro histogram, sph_data, flaresite=flaresite,linekind=linekind, time=time, before=before, after=after, name=name, directory=directory, Dphi, count

  ;which data to use, ruling out closed fieldlines:
  openlinesindex = where(linekind eq 2, count)
  numberoflines = n_elements(*sph_data.nstep)
  print, numberoflines, " fieldlines."
  print, count, " open fieldlines."
  print, count, ' /', numberoflines

  ;Data from the structure: 
  nstep = *sph_data.nstep
  ptph = *sph_data.ptph
  ptth = *sph_data.ptth

  ;Last point of each line.
  latitudes = fltarr(numberoflines)
  longitudes = fltarr(numberoflines)
  for i=0, numberoflines-1 do begin
     latitudes[i] = 90 - (180/!pi)* ptth[nstep[i]-1,i]
     longitudes[i] = (180/!pi)* ptph[nstep[i]-1,i]
  end  
  
  ;an array for the angle data:
  Dphi = fltarr(count)
  j = 0
  for i=0 , numberoflines-1 do begin
     if linekind[i] eq 2 then begin
        Dphi[j] = (180/!pi)* acos( cos(!dtor*latitudes[i]) $
                                   *cos(!dtor*(flaresite[1])) $
                                   *cos(!dtor*(longitudes[i]-flaresite[0])) $
                                   + sin(!dtor*latitudes[i]) $
                                   *sin(!dtor*flaresite[1]) )
        j = j +1
     endif
  endfor

  if before eq 1 then begin
     title = time + ' before, '+ strtrim(string(count),1) + ' field lines. Traced from the solar surface.'
  endif
  if after eq 1 then begin
     title = time + ' after, '+ strtrim(string(count),1) + ' field lines. Traced from the solar surface.'
  endif
  
  binsize = 1
  hist = HISTOGRAM(Dphi, binsize=binsize)
  xaxis = FINDGEN(N_ELEMENTS(hist))*binsize + MIN(Dphi)
  p = barplot(xaxis, hist, color="blue", $
              xrange=[0, max(xaxis)+binsize], $
              yrange=[0, MAX(hist)+1], title=title, ytitle='Number of lines', $
              xtitle='$\Delta \phi$  [degrees]')

   ;save histogram
   if before eq 1 then begin
      filename =directory+'/barplot_'+name+'_before.png'
   endif
   if after eq 1 then begin
      filename =directory+'/barplot_'+name+'_after.png'
   endif
   p.save, filename
   
   ;save histogram_data
   if before eq 1 then begin
      filename = directory+'/Dphi_'+name+'_before.sav'
   endif
   if after eq 1 then begin
      filename = directory+'/Dphi_'+name+'_after.sav'
   endif
   save, Dphi, filename=filename

   print, "Max angle:", max(Dphi)
   
 return

end
