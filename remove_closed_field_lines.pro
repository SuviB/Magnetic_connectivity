pro remove_closed_field_lines, sph_data, linekind

  STR = *sph_data.str
  STPH = *sph_data.stph
  STTH = *sph_data.stth
  PTR = *sph_data.ptr
  PTPH = *sph_data.ptph
  PTTH = *sph_data.ptth
  NSTEP = *sph_data.nstep
  
  tmp = where(linekind eq 2, countopenlines)

  NSTEP_max = MAX(NSTEP)
  STR_new = fltarr(countopenlines) 
  STPH_new = fltarr(countopenlines)
  STTH_new = fltarr(countopenlines)
  PTR_new = fltarr(NSTEP_max, countopenlines) 
  PTPH_new = fltarr(NSTEP_max, countopenlines) 
  PTTH_new = fltarr(NSTEP_max, countopenlines) 
  NSTEP_new = fltarr(countopenlines)
  linekind_new = fltarr(countopenlines)

  ;Go through the lines.
  print, 'Removing closed fieldlines.'
  j = 0
  for i=0, n_elements(linekind)-1 do begin
     ;Field line is open:
     if linekind[i] eq 2 then begin
        linekind_new[j] = linekind[i]
        NSTEP_new[j] = NSTEP[i]
        STR_new[j] = STR[i]
        STPH_new[j] = STPH[i]
        STTH_new[j] = STTH[i]
        PTR_new[*,j] = PTR[*,i]
        PTPH_new[*,j] = PTPH[*,i]
        PTTH_new[*,j] = PTTH[*,i]  
        j = j+1
     endif 
     ;laskuri:
     pros = (i*1.0/(n_elements(linekind)-1))*100
     esc = string(27B)
     print, esc + '[24D' + esc + '[K', format='(A, $)'
     print, pros, format='(I3, "%", $)'
  endfor
  print, ''

  sph_data.str = ptr_new(STR_new)
  sph_data.stph = ptr_new(STPH_new)
  sph_data.stth = ptr_new(STTH_new)
  sph_data.ptr = ptr_new(PTR_new)
  sph_data.ptph = ptr_new(PTPH_new)
  sph_data.ptth = ptr_new(PTTH_new)
  sph_data.nstep = ptr_new(NSTEP_new)
  linekind = linekind_new
  
end
