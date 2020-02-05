;+
;Draw the PFSS modeled magnetic field starting from a circular area with radius
;10 deg around the nominal Parker spiral on the source surface.
;Save an image as seen from Earth and solar north.
;Save the sph_data structure in a .sav-file.
;-

;PARAMETERS:
; name = time of the associated SEP event.
; flaretime = 'year-mm-dd_hh:mm'
; spacing = controls density of points, does different things depending on 
;           fieldtype
; flaresite = Coordinates of the flare. [lon,lat] as seen from earth.
; name = time of the SEP event
; flaretime = tutkittava pvm ja aika, flaren aika: string: 'vvvv-mm-dd_hh:mm'
; lambda = How far from the ecliptica do we want the fieldlines to
;          end (histogram.pro)
; D = radius of the circle around the Parker spiral.
; solwind = Solarwind speed at the time [km/s].
; directory = where to save the data

;Calls for: histogram2.pro, reddot.pro, greendot.pro, bluedot.pro,
;transfcoord.pro

;Calling sequence: pfss2,sph_data,name='name',flaretime='2016-03-16_06:39',rad=10,spacing=100,flaresite=[88,12],before=1,solwind=300,directory='reference_events'

pro pfss2, sph_data, name=name, flaretime=flaretime, rad=rad, spacing=spacing, flaresite=flaresite, before=before, solwind=solwind, directory=directory

  after=0
  if before eq 0 then begin
     after = 1
  endif
  D=rad
  solarwind = solwind
  time = flaretime
  
  print, ''
  print, "Time must be given as: 'year-mm-dd_hh:mm'. Is this correct: ",$
         time, "?"
  
  @pfss_data_block
  
  ;Hakee datan päivämäärän ja kellonajan perusteella.
  if before eq 1 then begin
     pfss_restore, pfss_time2file(time, /ssw_cat, /url, /BEFORE)
  endif
  if after eq 1 then begin
     pfss_restore, pfss_time2file(time, /ssw_cat, /url, /AFTER)
  endif

  ;kentän kiinnittymispaikka, Carrington coords
  parkerlon = (360/(25.38*24*60*60))*147.9e+06*cos(!dtor*b0)/(solarwind) +l0

  ;Flaresite to carrington
  flaresite = [flaresite[0]+l0,flaresite[1]]
  
  ;print out:
  print, ''
  print, 'Time: ', NOW
  print, 'Carrington longitude:', l0
  print, 'Carrington latitude:', b0
  print, 'Parker longitude:', parkerlon -l0
  print, ''
  
  ;  store in spherical_field_data structure
  pfss_to_spherical, sph_data

  ; fieldtype = 1 = starting points fall along the equator
  ;             2 = uniform grid, with a random offset
  ;             3 = points are distributed randomly in latitude and longitude
  ;             4 = read in from a file (not implemented)
  ;             5 = uniform grid (default)
  ;             6 = points are weighted by radial flux at the start radius
  ;             7 = rectangular grid
  ; spacing = controls density of points, does different things depending on 
  ;           fieldtype
  ; bbox = either [lon1,lon2] (for fieldtype1) or [lon1,lat1,lon2,lat2] (for
  ;            fieldtypes 2,3,5,6,7) defining bounding box (in degrees) outside
  ;            of which no fieldline starting points lie
  ; radstart = a scalar equal to the radius at which all fieldlines should
  ;            start (default=minimum radius in the domain)

  lon1 = parkerlon - D 
  lon2 = parkerlon + D
  if lon1 gt 360 then begin lon1 = lon1 -360
  endif
  if lon1 lt 0 then begin lon1 = lon1 +360
  endif
  if lon2 gt 360 then begin lon2 = lon2 -360
  endif
  if lon2 lt 0 then begin lon2 = lon2 +360
  endif
  lat1 = b0 - D 
  lat2 = b0 + D 
  if lat1 gt 90 then begin lat1 = 90
  endif
  if lat1 lt -90 then begin lat1 = -90
  flaresite = [result[0], 90-result[1]]
  endif
  if lat2 gt 90 then begin lat2 = 90
  endif
  if lat2 lt -90 then begin lat2 = -90
  endif

  bbox=[lon1,lat1,lon2,lat2]
  spherical_field_start_coord, sph_data, 3, spacing, $
                               bbox=bbox, radstart=2.5

  ;Data from the structure, so we can choose the ones falling into the circle.
  stph = *sph_data.stph
  stth = *sph_data.stth
  str = *sph_data.str
  alllines = n_elements(stph)
  latitudes = fltarr(alllines)
  longitudes = fltarr(alllines)
  for i=0, alllines-1 do begin
     latitudes[i] = 90 - (180/!pi)* stth[i]
     longitudes[i] = (180/!pi)* stph[i]
  end

  ;which lines to use:
  touse = fltarr(alllines)
  for i=0, alllines-1 do begin
     alpha = (180/!pi)* acos( cos(!dtor*latitudes[i]) $
                              *cos(!dtor*0) $
                              *cos(!dtor*(longitudes[i]-parkerlon)) $
                              + sin(!dtor*latitudes[i]) $
                              *sin(!dtor*0) )
     if alpha lt D then begin
        touse[i] = 1
     endif
  endfor 

  tmp = where(touse eq 1, chosenlines)
  if chosenlines eq 0 then begin
     print, ''
     print, 'No lines inside the circle. Draw more.'
     print, ''
     return
  endif

 ;changing chosen lines into structure
  newstth = fltarr(chosenlines)
  newstph = fltarr(chosenlines)
  newstr = fltarr(chosenlines)
  j = 0
  for i=0, alllines-1 do begin
     if touse[i] eq 1 then begin
        newstph[j] = stph[i]
        newstth[j] = stth[i]
        newstr[j] = str[i]
        j = j +1  
     endif
  endfor
  sph_data.stph = ptr_new(newstph)
  sph_data.stth = ptr_new(newstth)
  sph_data.str = ptr_new(newstr)

  ; linekind = on output, contains kind of fieldline:
  ;                      -1=line starting point out of bounds
  ;                       0=error of some sort?
  ;                       1=maximum step limit reached
  ;                       2=line intersects inner and outer boundaries, 
  ;                       3=both endpoints of line lie on inner boundary, 
  ;                       4=both endpoints of line lie on outer boundary,
  ;                       5=line intersects inner and side boundaries,
  ;                       6=line intersects outer and side boundaries,
  ;                       7=both endpoints of line lie on side
  ;                       boundary/ies
  ;                       8=one of the endpoints is a null
  spherical_trace_field, sph_data, linekind=linekind, /noreverse

  print, ''
  print, "Draw and save an image with just the open fieldlines."
  print, ''

  ;image as from earth
  WINDOW, 0
  spherical_draw_field, sph_data, outim=outim, /drawopen, lcent=l0, bcent=b0

  ;Marking flare location
  transfcoord, start=[flaresite,100], newzero=[l0,0], result, xyz
  x = 256 + xyz[1]
  y = 256 + xyz[2]
  
  if flaresite[0]-l0 gt 90 then begin
     greendot, outim=outim, x=x, y=y, greenoutim
     outim = greenoutim
  endif
  if flaresite[0]-l0 le 90 then begin
     reddot, outim=outim, x=x, y=y, redoutim
     outim = redoutim
  endif
  
  ;Marking parkerlongitude
  transfcoord, start=[parkerlon, 0, 250], newzero=[l0,0], result, xyz
  x = 256 + xyz[1]
  y = 256 + xyz[2]
  
  bluedot, outim=outim, x=x, y=y, blueoutim
     
  tv, blueoutim, /true
  if before eq 1 then begin
     filename = directory+'/pic_earth_'+name+'_before.png'
  endif
  if after eq 1 then begin
     filename = directory+'/pic_earth_'+name+'_after.png'
  endif
  write_png, filename, outim
  
  ;image as from north
  WINDOW, 1
  spherical_draw_field, sph_data, outim=outim, /drawopen, lcent=l0, bcent=90+b0
   
  ;Marking flare location
  transfcoord, start=[flaresite,100], newzero=[l0,90], result, xyz
  x = 256 + xyz[1]
  y = 256 - xyz[2]
  
  if flaresite[1] lt 0 then begin
     greendot, outim=outim, x=x, y=y, greenoutim
     outim = greenoutim
  endif
  if flaresite[1] ge 0 then begin
     reddot, outim=outim, x=x, y=y, redoutim
     outim = redoutim
  endif
  
  ;Marking parkerlongitude
  transfcoord, start=[parkerlon, 0, 250], newzero=[l0,90], result, xyz
  x = 256 + xyz[1]
  y = 256 - xyz[2]
  
  bluedot, outim=outim, x=x, y=y, blueoutim
   
  tv, blueoutim, /true
  
  if before eq 1 then begin
     filename = directory+'/pic_north_'+name+'_before.png'
  endif
  if after eq 1 then begin
     filename = directory+'/pic_north_'+name+'_after.png'
  endif
  write_png, filename, outim
   
  ;save sph_data
  if before eq 1 then begin
     filename = directory+'/sph_data_'+name+'_before.sav'
  endif
  if after eq 1 then begin
     filename = directory+'/sph_data_'+name+'_after.sav'
  endif
  save, sph_data, l0, b0, linekind, solarwind, D, filename=filename
     
  print, 'Making the histogram.'
  histogram2, sph_data, flaresite=flaresite, time=time, before=before, $
              after=after, directory=directory, name=name, beta

  print, 'time_of_SEP   D   lines   before   Parker_lon   Parker_lat   flare_lon   flare_lat   beta'
  print, name, ',', D, ',', n_elements(*sph_data.nstep), ',', before, ',', parkerlon -l0, ',', b0, ',', flaresite[0]-l0, ',', flaresite[1], ',', beta
     
return

 END
