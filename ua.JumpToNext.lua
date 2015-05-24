-- This is meant to get you to the "next sign" in the subtitle grid. (or previous)
-- When mocha-tracking over 1000 lines, it can be a pain in the ass to find where one sign ends and another begins.
-- Select lines that belong to the current "sign", i.e. all different layers/masks/texts.
-- The script will search from there for the first line in the grid that doesn't match any of the selected ones with "text" or "style". (see options)
-- If you set the effect of the first selected line to "st", the marker will be set to style for that run.

script_name="Jump to Next"
script_description="Jumps to next 'sign' in the subtitle grid"
script_author="unanimated"
script_version="1.3"
script_namespace="ua.JumpToNext"

local haveDepCtrl,DependencyControl,depRec=pcall(require,"l0.DependencyControl")
if haveDepCtrl then
  script_version="1.3.0"
  depRec=DependencyControl{feed="https://raw.githubusercontent.com/TypesettingTools/unanimated-Aegisub-Scripts/master/DependencyControl.json"}
end

--OPTIONS--
default_marker="text"	-- "text" looks for text (without tags/comments) / "style" looks for style
--THE END--

function nextsel(subs,sel)
getinfo(subs,sel)
if j==#subs then aegisub.cancel() end
count=1
repeat
  line=subs[j+count]
  markers()
  ch=0
  for m=1,#marks do if marks[m]==hit then ch=1 end end
  if ch==0 or j+count==#subs then sel={j+count} end
  count=count+1
until ch==0 or hit==nil or j+count>#subs
return sel
end

function prevsel(subs,sel)
getinfo(subs,sel)
if subs[i-1].class~="dialogue" then aegisub.cancel() end
count=1
repeat
  line=subs[i-count]
  markers()
  ch=0
  for m=1,#marks do if marks[m]==hit then ch=1 end end
  if ch==0 or subs[i-count-1].class~="dialogue" then sel={i-count} end
  count=count+1
until ch==0 or hit==nil or subs[i-count].class~="dialogue"
return sel
end

function getinfo(subs,sel)
marker=default_marker
lm=nil
i=sel[1]
j=sel[#sel]
marks={}
 for z,i in ipairs(sel) do
  rine=subs[i]
  txt=rine.text:gsub("{[^}]-}","")
  sty=rine.style
  act=rine.actor
  eff=rine.effect
  if z==1 and rine.effect=="st" then marker="style" rine.effect="" subs[i]=rine end
  if marker=="text" then mark=txt end
  if marker=="style" then mark=sty end
  if marker=="actor" then mark=act end
  if marker=="effect" then mark=eff end
  if mark~=lm then table.insert(marks,mark) end
  lm=mark
 end
end

function markers()
  if marker=="text" then hit=line.text:gsub("{[^}]-}","") end
  if marker=="style" then hit=line.style end
  if marker=="actor" then hit=line.actor end
  if marker=="effect" then hit=line.effect end
end

if haveDepCtrl then
  depRec:registerMacros({
    {script_name,script_description,nextsel},
    {"Jump to Previous","Jumps to previous 'sign' in the subtitle grid",prevsel}
  },false)
else
  aegisub.register_macro(script_name,script_description,nextsel)
  aegisub.register_macro("Jump to Previous","Jumps to previous 'sign' in the subtitle grid",prevsel)
end