-- This is meant to get you to the "next sign" in the subtitle grid. (or previous)
-- When mocha-tracking over 1000 lines, it can be a pain in the ass to find where one sign ends and another begins.
-- Select lines that belong to the current "sign", i.e. all different layers/masks/texts.
-- The script will search from there for the first line in the grid that doesn't match any of the selected ones with "text", "style", etc.

script_name="Jump to Next"
script_description="Jumps to next 'sign' in the subtitle grid"
script_description2="Jumps to previous 'sign' in the subtitle grid"
script_author="unanimated"
script_version="2.0"
script_namespace="ua.JumpToNext"

local haveDepCtrl,DependencyControl,depRec=pcall(require,"l0.DependencyControl")
if haveDepCtrl then
  script_version="2.0.0"
  depRec=DependencyControl{feed="https://raw.githubusercontent.com/TypesettingTools/unanimated-Aegisub-Scripts/master/DependencyControl.json"}
end

ak=aegisub.cancel

function nextsel(subs,sel)
getinfo(subs,sel)
if j==#subs then ak() end
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
if subs[i-1].class~="dialogue" then ak() end
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
lm=nil
i=sel[1]
j=sel[#sel]
marks={}
 for z,i in ipairs(sel) do
  rine=subs[i]
  if marker=="text" then mark=rine.text:gsub("%b{}","") end
  if marker=="style" then mark=rine.style end
  if marker=="actor" then mark=rine.actor end
  if marker=="effect" then mark=rine.effect end
  if marker=="layer" then mark=rine.layer end
  if mark~=lm then table.insert(marks,mark) end
  lm=mark
 end
end

function markers()
  if marker=="text" then hit=line.text:gsub("%b{}","") end
  if marker=="style" then hit=line.style end
  if marker=="actor" then hit=line.actor end
  if marker=="effect" then hit=line.effect end
  if marker=="layer" then hit=line.layer end
end

function nextcom(subs,sel)
j=sel[#sel]
if j==#subs then ak() end
repeat
  j=j+1
  line=subs[j]
  if j==#subs then sel={j} end
  if line.comment then sel={j} end
until line.comment or j==#subs
return sel
end

function prevcom(subs,sel)
i=sel[1]
repeat
  i=i-1
  line=subs[i]
  if line.class~="dialogue" then sel={i+1} end
  if line.comment then sel={i} end
until line.comment or line.class~="dialogue"
return sel
end

function logg(m) m=m or "nil" aegisub.log("\n "..m) end

function nextT(subs,sel) marker="text" sel=nextsel(subs,sel) return sel end
function nextS(subs,sel) marker="style" sel=nextsel(subs,sel) return sel end
function nextA(subs,sel) marker="actor" sel=nextsel(subs,sel) return sel end
function nextE(subs,sel) marker="effect" sel=nextsel(subs,sel) return sel end
function nextL(subs,sel) marker="layer" sel=nextsel(subs,sel) return sel end
function nextC(subs,sel) sel=nextcom(subs,sel) return sel end

function prevT(subs,sel) marker="text" sel=prevsel(subs,sel) return sel end
function prevS(subs,sel) marker="style" sel=prevsel(subs,sel) return sel end
function prevA(subs,sel) marker="actor" sel=prevsel(subs,sel) return sel end
function prevE(subs,sel) marker="effect" sel=prevsel(subs,sel) return sel end
function prevL(subs,sel) marker="layer" sel=prevsel(subs,sel) return sel end
function prevC(subs,sel) sel=prevcom(subs,sel) return sel end

function nextG(subs,sel)
GUI={{class="label",label="Jump to Next..."},{x=1,class="checkbox",name="prev",label="Jump to Previous"}}
P,res=aegisub.dialog.display(GUI,{"Text","Style","Actor","Effect","Layer","Comment","X"},{ok='Text',close='X'})
if P=="X" then ak() end
if res.prev then
	if P=="Text" then marker="text" sel=prevsel(subs,sel) end
	if P=="Style" then marker="style" sel=prevsel(subs,sel) end
	if P=="Actor" then marker="actor" sel=prevsel(subs,sel) end
	if P=="Effect" then marker="effect" sel=prevsel(subs,sel) end
	if P=="Layer" then marker="layer" sel=prevsel(subs,sel) end
	if P=="Comment" then sel=prevcom(subs,sel) end
else
	if P=="Text" then marker="text" sel=nextsel(subs,sel) end
	if P=="Style" then marker="style" sel=nextsel(subs,sel) end
	if P=="Actor" then marker="actor" sel=nextsel(subs,sel) end
	if P=="Effect" then marker="effect" sel=nextsel(subs,sel) end
	if P=="Layer" then marker="layer" sel=nextsel(subs,sel) end
	if P=="Comment" then sel=nextcom(subs,sel) end
end
return sel
end

if haveDepCtrl then
   depRec:registerMacros({
	{"Jump to Next/_GUI",script_description,nextG},
	{"Jump to Next/Text",script_description,nextT},
	{"Jump to Next/Style",script_description,nextS},
	{"Jump to Next/Actor",script_description,nextA},
	{"Jump to Next/Effect",script_description,nextE},
	{"Jump to Next/Layer",script_description,nextL},
	{"Jump to Next/Commented Line",script_description,nextC},
	{"Jump to Previous/Text",script_description2,prevT},
	{"Jump to Previous/Style",script_description2,prevS},
	{"Jump to Previous/Actor",script_description2,prevA},
	{"Jump to Previous/Effect",script_description2,prevE},
	{"Jump to Previous/Layer",script_description2,prevL},
	{"Jump to Previous/Commented Line",script_description2,prevC},
   },false)
else
	aegisub.register_macro("Jump to Next/_GUI",script_description,nextG)
	aegisub.register_macro("Jump to Next/Text",script_description,nextT)
	aegisub.register_macro("Jump to Next/Style",script_description,nextS)
	aegisub.register_macro("Jump to Next/Actor",script_description,nextA)
	aegisub.register_macro("Jump to Next/Effect",script_description,nextE)
	aegisub.register_macro("Jump to Next/Layer",script_description,nextL)
	aegisub.register_macro("Jump to Next/Commented Line",script_description,nextC)
	aegisub.register_macro("Jump to Previous/Text",script_description2,prevT)
	aegisub.register_macro("Jump to Previous/Style",script_description2,prevS)
	aegisub.register_macro("Jump to Previous/Actor",script_description2,prevA)
	aegisub.register_macro("Jump to Previous/Effect",script_description2,prevE)
	aegisub.register_macro("Jump to Previous/Layer",script_description2,prevL)
	aegisub.register_macro("Jump to Previous/Commented Line",script_description2,prevC)
end