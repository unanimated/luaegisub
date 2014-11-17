-- This is meant to get you to the "next sign" in the subtitle grid.
-- When mocha-tracking over 1000 lines, it can be a pain in the ass to find where the sign ends and another begins.
-- Select lines that belong to the current "sign", ie. different layers/masks/texts.
-- The script will search for the first line in the grid that doesn't match any of the selected ones with "text" or "style". (see options)
-- If you set the effect of the first selected line to "st", the marker is set to style for that run

script_name="Jump to Next"
script_description="Jumps to next 'sign' in the subtitle grid"
script_author="unanimated"
script_version="1.21"

--OPTIONS--
default_marker="text"	-- "text" looks for text (without tags/comments) / "style" looks for style
--THE END--

function nextsel(subs, sel)
marker=default_marker
lm=nil
i=sel[1]
j=sel[#sel]
marks={}
for x,i in ipairs(sel) do
  rine=subs[i]
  txt=rine.text:gsub("{[^}]-}","")
  sty=rine.style
  act=rine.actor
  eff=rine.effect
  if x==1 and rine.effect=="st" then marker="style" rine.effect="" subs[i]=rine end
  if marker=="text" then mark=txt end
  if marker=="style" then mark=sty end
  if marker=="actor" then mark=act end
  if marker=="effect" then mark=eff end
  if mark~=lm then table.insert(marks,mark) end
  lm=mark
end
count=1
repeat
  line=subs[j+count]
  txt2=line.text:gsub("{[^}]-}","")
  sty2=line.style
  act2=line.actor
  eff2=line.effect
  if marker=="text" then hit=txt2 end
  if marker=="style" then hit=sty2 end
  if marker=="actor" then hit=act2 end
  if marker=="effect" then hit=eff2 end
  ch=0
  for m=1,#marks do if marks[m]==hit then ch=1 end end
  if ch==0 or j+count==#subs then sel={j+count} end
  count=count+1
until ch==0 or hit==nil or j+count>#subs
return sel
end

aegisub.register_macro(script_name,script_description,nextsel)