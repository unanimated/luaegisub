-- This is meant to get you to the "next sign" in the subtitle grid.
-- When mocha-tracking over 1000 lines, it can be a pain in the ass to find where the sign ends and another begins.
-- Select lines that belong to the current "sign", ie. different layers/masks/texts.
-- The script will search for the first line in the grid that doesn't match any of the selected ones with "text" or "style". (see options)

script_name="Jump to Next"
script_description="Jumps to next 'sign' in the subtitle grid"
script_author="unanimated"
script_version="1.01"

--OPTIONS--
marker="text"	-- "text" looks for text (without tags/comments) / "style" looks for style
--THE END--

function nextsel(subs, sel)
lm=nil
i=sel[1]
marks={}
for x,i in ipairs(sel) do
  rine=subs[i]
  txt=rine.text:gsub("{[^}]-}","")
  sty=rine.style
  if marker=="text" then mark=txt end
  if marker=="style" then mark=sty end
  if mark~=lm then table.insert(marks,mark) end
  lm=mark
end
count=1
repeat
  line=subs[i+count]
  txt2=line.text:gsub("{[^}]-}","")
  sty2=line.style
  if marker=="text" then hit=txt2 end
  if marker=="style" then hit=sty2 end
  ch=0
  for m=1,#marks do if marks[m]==hit then ch=1 end end
  if ch==0 or i+count==#subs then sel={i+count} end
  count=count+1
until ch==0 or hit==nil or i+count>#subs
return sel
end

aegisub.register_macro(script_name, script_description, nextsel)