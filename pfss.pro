;+
;Draw the PFSS modeled magnetic field starting from a circular area with radius
;D around the flare site. Save an image as seen from Earth and solar
;north.
;Save the sph_data structure in a .sav-file.
;-

;PARAMETERS:
; name = time of the associated SEP event.
; flaretime = 'year-mm-dd_hh:mm'
; spacing = controls density of points, does different things depending on 
;           fieldtype
; flaresite = Coordinates of the flare. [lon,lat] as seen from earth.
; time = tutkittava pvm ja aika: string: 'vvvv-mm-dd_hh:mm'
; D = angular distance from the flaresite taken into consideration.
; before after = which magnetogram to use, choose 1 for the previous
; one before the flare.
; solwind = solar wind speed in km/s, to calculate the nominal
; Parker spiral.
; directory = Where the data will be saved.

;Calls for: histogram.pro, reddot.pro, greendot.pro, bluedot.pro,
;transfcoord.pro

;Calling sequence: pfss,sph_data,name='testing',flaretime='2010-08-14_10:01',spacing=100000,flaresite=[-152,17],rad=10,before=1,solwind=428,directory='~/final_gradu/data'


pro pfss, sph_data,name=name,flaretime=flaretime, spacing=spacing, flaresite=flaresite, rad=rad, before=before, solwind=solwind, directory=directory

  after=0
  if before eq 0 then begin
     after = 1
  endif
  D=rad
  solarwind = solwind
  time=flaretime
  
  print, ''
  print, "Time must be given as: 'year-mm-dd_hh:mm'. Is this correct: ",$
         time, "?"
  print, ''
  
  @pfss_data_block
  
  ;Retrieve the data based on the given (flare)time, before or after.
  if before eq 1 then begin
     pfss_restore,pfss_time2file(time,/SSW_CAT,/URL,/BEFORE)
  endif
  if after eq 1 then begin
     pfss_restore,pfss_time2file(time,/SSW_CAT,/URL,/AFTER)
  endif
  
  ;Nominal Parker spiral on the source surface, Carrington coords
  parkerlon = (360/(25.38*24*60*60))*147.9e+06*cos(!dtor*b0)/(solarwind) +l0
 
   ;print out:
  print, 'Time: ', NOW, ' Is this the time that was wanted?'
  print, 'Carrington longitude:', l0
  print, 'Carrington latitude:', b0
  print, 'Parker longitude:', parkerlon -l0
  print, ''


  ;Flaresite to carrington
  flaresite = [flaresite[0]+l0,flaresite[1]]
  
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
  ;           fieldtypes 2,3,5,6,7) defining bounding box (in degrees) outside
  ;           of which no fieldline starting points lie
  ; radstart = a scalar equal to the radius at which all fieldlines should
  ;            start (default=minimum radius in the domain)
  lon1 = flaresite[0] - D 
  lon2 = flaresite[0] + D 
  if lon1 gt 360 then begin lon1 = lon1 -360
  endif
  if lon1 lt 0 then begin lon1 = lon1 +360
  endif
  if lon2 gt 360 then begin lon2 = lon2 -360
  endif
  if lon2 lt 0 then begin lon2 = lon2 +360
  endif
  lat1 = flaresite[1] - D 
  lat2 = flaresite[1] + D
  if lat1 gt 90 then begin lat1 = 90
  endif
  if lat1 lt -90 then begin lat1 = -90
  endif
  if lat2 gt 90 then begin lat2 = 90
  endif
  if lat2 lt -90 then begin lat2 = -90
  endif
  
  bbox = [lon1,lat1,lon2,lat2]
  spherical_field_start_coord, sph_data, 3, spacing, bbox=bbox,$
                               radstart=1.0

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
  endfor

  ;which lines start within D from the flare site.
  touse = fltarr(alllines)
  for i=0, alllines-1 do begin
     alpha = (180/!pi)* acos( cos(!dtor*latitudes[i]) $
                            *cos(!dtor*(flaresite[1])) $
                            *cos(!dtor*(longitudes[i]-flaresite[0])) $
                            + sin(!dtor*latitudes[i]) $
                            *sin(!dtor*flaresite[1]) )
     if alpha lt D then begin
        touse[i] = 1
     endif
  endfor

  tmp = where(touse eq 1, chosenlines)
  if chosenlines eq 0 then begin
     print, ''
     print, 'No lines inside the circle. Draw more or try a larger D.'
     print, ''
     stop
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

  ;trace the field
  ; linekind = on output, contains kind of fieldline:
  ;                      -1=line starting point out of bounds
  ;                       0=error of some sort?
  ;                       1=maximum step limit reached
  ;                       2=line intersects inner and outer boundaries, 
  ;                       3=both endpoints of line lie on inner boundary, 
  ;                       4=both endpoints of line lie on outer boundary,
  ;                       5=line intersects inner and side boundaries,
  ;                       6=line intersects outer and side boundaries,
  ;                       7=both endpoints of line lie on side boundary/ies
  ;                       8=one of the endpoints is a null
  spherical_trace_field, sph_data, linekind=linekind, /noreverse

  linekind = linekind

  tmp = where(linekind eq 2, countopenlines)
  if countopenlines gt 0 then begin
   
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
     
     if flaresite[0]-l0 gt 90 or flaresite[0]-l0 lt -90 then begin
        greendot, outim=outim, x=x, y=y, greenoutim
        outim = greenoutim
     endif
     if flaresite[0]-l0 le 90 and flaresite[0]-l0 ge -90 then begin
        reddot, outim=outim, x=x, y=y, redoutim
        outim = redoutim
     endif
         
     ;Marking parkerlongitude
     transfcoord, start=[parkerlon, 0, 250], newzero=[l0,0], result, xyz
     x = 256 + xyz[1]
     y = 256 + xyz[2]
        
     bluedot, outim=outim, x=x, y=y, blueoutim
   
     tv,blueoutim,/true
     if before eq 1 then begin
        filename = directory+'/pic_earth_'+name+'_before.png'
     endif
     if after eq 1 then begin
        filename = directory+'/pic_earth_'+name+'_after.png'
     endif
     write_png, filename, outim
   
    ;image as from north
     WINDOW, 1
     spherical_draw_field, sph_data, outim=outim, /drawopen, lcent=l0,$
                           bcent=90+b0

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
    
     histogram, sph_data, flaresite=flaresite,linekind=linekind, time=time, before=before, after=after, name=name, directory=directory, Dphi, count


  ;Find the end longitudes and latitudes:
  nstep=*sph_data.nstep
  ptph = *sph_data.ptph
  ptth = *sph_data.ptth
  openlinesindex = where(linekind eq 2, count)
  numberoflines = n_elements(nstep)
  
  longitudes = fltarr(count)
  latitudes = fltarr(count)
  j=0
  for i=0, numberoflines-1 do begin
     if linekind[i] eq 2 then begin
        longitudes[j] = (180/!pi)* ptph[nstep[i]-1,i] -l0
        latitudes[j] = 90 - (180/!pi)* ptth[nstep[i]-1,i]
        if longitudes[j] lt -180 then begin
           longitudes[j] = longitudes[j] +360
        endif
        if longitudes[j] gt 180 then begin
           longitudes[j] = longitudes[j] -360
        endif
        j=j+1
     endif
  end

  ;Find the longitudinal width:
  max = max(longitudes) 
  min = min(longitudes)
  longwidth = max-min

  print, ''
  print, 'longwidth', longwidth
  

  ;Minimum angular distance between the fieldlines and the parkerpoint:
  Dlinesparker = fltarr(count)
  i = 0
  for i=0 , count-1 do begin
        Dlinesparker[i] = (180/!pi)* acos( cos(!dtor*latitudes[i]) $
                                   *cos(!dtor*b0) $
                                   *cos(!dtor*(longitudes[i]-(parkerlon-l0))) $
                                   + sin(!dtor*latitudes[i]) $
                                   *sin(!dtor*b0) )
  endfor

  smallestfromparker = min(Dlinesparker)
  
  print, ''
  print, 'smallest angle from parker', smallestfromparker
 
  ang_parkerjaflare =(180/!pi)* acos( cos(0)*cos(!dtor*flaresite[1]) $
                      *cos(!dtor*(parkerlon-flaresite[0])) + $
                      sin(0)*sin(!dtor*flaresite[1]) )


     
     print, 'time   D   open_lines   before   parker_lon   parker_lat   no_PFSS   lambda   alpha   longwidth   flare_lon'
     print, name, ',', D, ',', count,'/',numberoflines, ',', before, ',', parkerlon-l0,',',   b0,',', ang_parkerjaflare,',', smallestfromparker,',', max(Dphi),',',longwidth, ',', flaresite[0]-l0
     
  endif
  
   

if countopenlines eq 0 then begin
   print, '--------------------------------'
   print, '| All field lines were closed! |'
   print, '--------------------------------'
end

 END
