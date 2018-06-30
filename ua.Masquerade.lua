script_name="Masquerade"
script_description="Dark Elves with Blurry Masks Shifting in Motion"
script_author="unanimated"
script_version="3.0"
script_namespace="ua.Masquerade"

local haveDepCtrl,DependencyControl,depRec=pcall(require,"l0.DependencyControl")
if haveDepCtrl then
  script_version="3.0.0"
  depRec=DependencyControl{feed="https://raw.githubusercontent.com/unanimated/luaegisub/master/DependencyControl.json"}
end

hlp=[[	Full manual: http://unanimated.hostfree.pw/ts/scripts-manuals.htm#masquerade

	>> Masquerade
	Creates a mask with the selected shape
	"New Line" creates the mask on a new line and raises the layer of the current line by 1
	"Remask" only changes an existing mask for another shape without changing tags
	"Save/delete mask" lets you save a mask from active line or delete one of your custom masks
	- to save a mask, type a name, and the mask from your active line will be saved
	(appdata/masquerade.masks)
	- to delete a mask, type its name or type 'del', and select the name from the menu on the left

	>> Merge Tags
	Select lines with the SAME TEXT but different tags,
	and they will be merged into one line with tags from all of them.
	For example:
	{\bord2}AB{\shad3}C
	A{\fs55}BC
	-> {\bord2}A{\fs55}B{\shad3}C
	If two lines have the same tag in the same place,
	the value of the later line overrides the earlier one.

	>> an8 / q2
	Adds selected tags.

	>> Motion Blur
	Creates motion blur by duplicating the line and using some alpha.
	You can set a value for blur or keep the existing blur for each line.
	'Dist.' is the distance between the \pos coordinates of the resulting 2 lines.
	If you use 3 lines, the 3rd one will be in the original position, i.e. in the middle.
	The direction is determined from the first 2 points of a vectorial clip.

	>> Shift Tags
	For active line (when only one selected):
		Allows you to shift tags by character or by word.
		For the first block, single tags can be moved right.
		For inline tags, each block can be moved left or right.
		If there are multiple same inline tags, results will be uncertain.
		If a tag is marked with an arrow (>\tag), then one of two things will happen:
		1. if there is {•} in the line, the tag is moved to replace •
		2. otherwise you get to choose where to move that tag
		(Check HYDRA for the usage of Arrow Shifter & Bell Shifter.)
	For selection >1:
		1. If any line contains >\ and {•}, then the arrow-marked tag replaces the bell.
		2. If any line contains >\ and all lines have the same text (and no {•}),
			you get to choose where the tag goes.
			Different lines can have different tags marked by the arrow.
		3. If none of that applies, all inline tags are shifted by one character to the right.
		If line ends with {switch} comment, tags move by 1 character to the left.
		You can shift by more, using the 'Shift by' option.
		(See Cycles script for a macro that adds/removes the {switch} comment.)

	>> Alpha Shift
	Makes text appear letter by letter on frame-by-frame lines using alpha&HFF& like this:
	{alpha&HFF&}text
	t{alpha&HFF&}ext
	te{alpha&HFF&}xt
	tex{alpha&HFF&}t
	text
	'Shift by' can be used here as well.
	If you switch from 'α' to '1a', \alpha tags will be changed into \1a tags instead.

	>> Alpha Time
	Either select lines that are already timed for alpha timing and need alpha tags,
	or just one line that needs to be alpha timed.
	In the GUI, split the line by hitting Enter where you want the alpha tags.
	If you make no line breaks, text will be split by spaces.
	Alpha Text is for when you have the lines already timed and just need the tags.
	Alpha Time is for one line. It will be split to equally long lines with alpha tags added.
	If you add "@" to your line first, alpha tags will replace the @, and no GUI will pop up.
	Example text: This @is @a @test.

	>> StrikeAlpha
	Replaces strikeout or underline tags with \alpha&H00& or \alpha&HFF&. Also @.
	{\s0}	->	{\alpha&HFF&}
	{\s1}	->	{\alpha&H00&}
	{\u1}	->	{\alpha&HFF&}
	{\u0}	->	{\alpha&H00&}
	@	->	{\alpha&HFF&}
	@0	->	{\alpha&H00&}
	@E3@	->	{\alpha&HE3&}
	1@	->	{\1a&HFF&}	(All variations)
	If no replacement is made, it will reorder alpha tags in each block so that all 1a-4a go after alpha.
	
	Also uses the Bell to comment sections of text.
	0	You can comment out parts of this {•}line with StrikeAlpha and {\i1}Bell Shifter{\i0}.
	1	You can comment out parts of this {•line }with StrikeAlpha and {\i1}Bell Shifter{\i0}.
	2	You can comment out parts of this {•line with StrikeAlpha and }{\i1}Bell Shifter{\i0}.
	3	You can comment out parts of this line with StrikeAlpha and {\i1}Bell Shifter{\i0}.
	
	If there's {~} in the line, you'll get a menu with some options, so try that out.

	>> Betastrike
	Switches various parts of the text.
	{\s1}word1 word2 word3 word4{\s0}	-->	word4 word3 word2 word1
	{\u1}some text1 {\u0}other text2	-->	other text2 some text1
	[the space before {\u0} will remain there; \s and \u tags can be part of a larger block]
	{~}{\tags1}abc def {•}{\tags2}ghi	<->	{•}{\tags2}abc def {~}{\tags1}ghi
	{~}word1 word2 word3 {•}word4	<->	{•}word4 word2 word3 {~}word1
	{~}{\tags1}word1 word2 {•}word3	<->	{•}word1 word2 {~}{\tags1}word3

	>> Deltastrike
	Define your own replacements for the 6 listed things when saving config.

	>> Converter (separate macro)
	Define as many conversions as you want for whatever you want.
	These are literal (and case sensitive) and don't check for any syntax errors,
	so be careful with things like {}.
	always/ask - replacements are either made automatically or you get asked which ones you want.
	Only ones that exist in selected lines will be offered (so you won't get asked about irrelevant ones).
	raw/clean - raw converter uses whole "text", whereas the clean one skips stuff in {}.
	If you run Converter and no replacements are made (nothing found or nothing defined),
	the GUI appears and you can add new replacements.
	Converter gives you lots of options, but you need to be careful not to replace things accidentally.
	Converting "bus" to "car" will also convert "busy" to "cary",
	so use the "Whole word only" option for that.
	Some suggestions for usage:
		convert -- to —
			(or whatever else you can't remember how to type)
		convert embarass to embarrass, english to English, didnt to didn't
			(and any other useful corrections)
		convert Dammit to Damn it
			(and other editing preferences)
		convert \xshad0\yshad0 to \xshad1\yshad1
			(if you also convert 1 to 2, they have to be in the list in the opposite order,
			otherwise they will both run in sequence)
	Converting something both ways like \clip to \iclip and \iclip to \clip wouldn't work,
	because the second one would revert the first one, but if you set them to "ask",
	you can then pick the one of the two that you need at the moment.
]]

re=require'aegisub.re'

function addmask(subs,sel)
  nsel={} for z,i in ipairs(sel) do table.insert(nsel,i) end
  for z=#sel,1,-1 do
    i=sel[z]
    l=subs[i]
    text=l.text
    l.layer=l.layer+1
    err=nil
    if res.masknew and not res.remask then
	if res.mask=="from clip" then
		if not text:match("\\clip") then noclip=true err=1
			if text:match("\\iclip") then i_clip=true end
		end
		if not err then l.text=nopar("clip",l.text) end
	end
	if not err then nsel=shiftsel2(nsel,i,1) subs.insert(i+1,l) end
    end
    l.layer=l.layer-1
    if text:match("\\2c") then mcol="\\c"..text:match("\\2c(&H[%x]+&)") else mcol="" end
    
    -- REMASK
    if res.remask then
	if text:match("\\p1") then
		if res.mask=="from clip" then
			if not text:match("\\clip") then noclip=true
			else
				masklip()
				l.text=nopar("clip",l.text)
				nmask=ctext2 l.text=re_mask(l.text)
			end
		else
		    for k=1,#allmasks do
		      if allmasks[k].n==res.mask then
			nmask=allmasks[k].m l.text=re_mask(l.text)
		      end
		    end
		end
	end
    else
	-- STANDARD MASK
	if res.mask=="from clip" then
	  if not err then
	    masklip()
	    l.text="{\\an7\\blur1\\bord0\\shad0\\fscx100\\fscy100"..mcol..mp..pos.."\\p1}"..ctext2
	  end
	else
	atags=""
	org=l.text:match("\\org%b()")		if org then atags=atags..org end
	frz=l.text:match("\\frz[%d%.%-]+")	if frz then atags=atags..frz end
	frx=l.text:match("\\frx[%d%.%-]+")	if frx then atags=atags..frx end
	fry=l.text:match("\\fry[%d%.%-]+")	if fry then atags=atags..fry end
	
	l.text=l.text:gsub(".*(\\pos%([%d%,%.%-]-%)).*","%1")
	if not l.text:match("\\pos") then l.text="" end
	  for k=1,#allmasks do
	    if allmasks[k].n==res.mask then
	      if res.mask:match("alignment grid") then
		l.text="{\\an7\\bord0\\shad0\\blur0.6"..l.text..atags.."\\c&H000000&\\alpha&H80&\\p1}"..allmasks[k].m
	      else
		l.text="{\\an7\\bord0\\shad0\\blur1"..l.text..mcol.."\\p1}"..allmasks[k].m
	      end
	      if res.mask=="square" then l.text=l.text:gsub("\\an7","\\an5") end
	    end
	  end
	if not l.text:match("\\pos") then l.text=l.text:gsub("\\p1","\\pos(640,360)\\p1") end
	end
    end
    subs[i]=l
  end
  if noclip then t_error("Some lines weren't processed - missing \\clip.") noclip=nil end
  if i_clip then t_error("Some lines weren't processed - \\iclip ignored.") i_clip=nil end
  sel=nsel
  return sel
end

function masklip()
	oscf=text:match("\\i?clip%((%d+),m")
	if oscf then
		fact1=2^(oscf-1)
		text=text:gsub("(\\i?clip%()(%d*,?)m ([^%)]+)%)",function(a,b,c)
		return a.."m "..c:gsub("([%d%.%-]+)",function(d) return round(d/fact1) end)..")" end)
	end
		
	text=text:gsub("\\clip%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)","\\clip(m %1 %2 l %3 %2 %3 %4 %1 %4)")
	if text:match("\\move") then text=text:gsub("\\move","\\pos") mp="\\move" else mp="\\pos" end
	ctext=text:match("clip%(m ([%d%.%a%s%-]+)")
	if not ctext then t_error("There's something wrong with the clip here:\n"..text:match("{.-clip.-}"),1) end
	if text:match("\\pos") then
		pos=text:match("\\pos(%([^%)]+%))")
		local xx,yy=text:match("\\pos%(([%d%.%-]+),([%d%.%-]+)")
		xx=round(xx) yy=round(yy)
		ctext2=ctext:gsub("([%d%.%-]+)%s([%d%.%-]+)",function(a,b) return a-xx.." "..b-yy end)
	else pos="(0,0)" ctext2=ctext
	end
	ctext2="m "..ctext2:gsub("([%d%.]+)",function(a) return round(a) end)
end

function re_mask(text)
text=text
:gsub("\\fsc[xy][^}\\]+","")
:gsub("}m [^{]+","\\fscx100\\fscy100}"..nmask)
if res.mask=="square" then text=text:gsub("\\an7","\\an5") end
return text
end

function savemask(subs,sel,act)
masker=ADP("?user").."\\masquerade.masks"
file=io.open(masker)
  if file then masx=file:read("*all") io.close(file) end
  if masx==nil then masx="" end
  mask_name=res.maskname
  masx=masx:gsub(":\n$",":\n\n") :gsub(":$",":\n\n")
  -- delete mask
  deleted=0
    for m=1,#maasks do
      if mask_name=="del" then mask_name=res.mask end
      if maasks[m]==mask_name then
	if m<=10 then t_error("You can't delete a default mask.",1)
	else e_name=esc(mask_name) masx=masx:gsub("mask:"..e_name..":.-:\n\n","") t_error("Mask '"..mask_name.."' deleted",false)
	end
	deleted=1
      end
    end
  -- add new mask
  if deleted==0 then
    text=subs[act].text
    text=text:gsub("{[^}]-}","")
    newmask=text:match("m [%d%s%-mbl]+")
    if not newmask then t_error("No mask detected.",1) end
    newmask=newmask:gsub("%s*$","")
    if newmask==nil then t_error("No mask detected on active line.",1) end
    if mask_name=="mask name here" or mask_name=="" then
	p,rez=ADD({{class="label",label="Enter a proper name for the mask:"},
	{y=1,class="edit",name="mname"},},{"OK","Cancel"},{ok='OK',close='Cancel'})
	if p=="Cancel" then ak() end
	if rez.mname=="" then t_error("Naming fail",1) else mask_name=rez.mname end
      for m=1,#maasks do
        if maasks[m]==mask_name then
	  t_error("Mask '"..mask_name.."' already exists.",1)
        end
      end
    end
    new_mask="mask:"..mask_name..":"..newmask..":\n\n"
    masx=masx..new_mask
  end
  masx=masx:gsub(":\nmask",":\n\nmask")
  file=io.open(masker,"w")
  file:write(masx)
  file:close()
  if deleted==0 then
    ADD({{class="label",label="Mask '"..mask_name.."' saved to:\n"..masker}},{"OK"},{close='OK'})
  end
end



--	Merge tags	--	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function merge(subs,sel,act)
    tk={}
    tg={}
    stg=""
    for z,i in ipairs(sel) do
        progress("Merging "..z.."/"..#sel)
	line=subs[i]
        text=line.text
	text=text:gsub("{\\\\k0}",""):gsub("\\N","{\\N}")
	text=tagmerge(text)
	vis=text:gsub("%b{}","")
	if vis:gsub(" ","")=="" then t_error("No text on line 1.",1) end
	if z==1 then rt=vis
	    C=0
	    repeat
		for ltr in re.gfind(rt,'.') do table.insert(tk,ltr) end
		vis2=table.concat(tk,"")
		C=C+1
	    until vis==vis2 or C==1666
	end
	if vis~=vis2 then t_error("Error. Inconsistent text.\n"..vis.."\n"..vis2,1) end
	if vis~=rt then t_error("Error. Inconsistent text.\nAll selected lines must contain the same text.",1) end
	stags=text:match("^{([^}]-)}") or ""
	stg=stg..stags stg=duplikill(stg)
	repeat stg,r=stg:gsub("(\\[ibusqa]n?%d)(.-)%1","%2%1") until r==0
	text=text:gsub(STAG,"")
	count=0
	for seq in text:gmatch("[^{]-{%*?[^}]-}") do
	    chars,as,tak=seq:match("([^{]-){(%*?)([^}]-)}")
	    pos=re.find(chars,".")
	    if pos==nil then ps=0+count else ps=#pos+count end
	    tgl={p=ps,t=tak,a=as}
	    table.insert(tg,tgl)
	    count=ps
	end
    end
    newline=""
    for i=1,#tk do
	newline=newline..tk[i]
	newt=""
	for n,t in ipairs(tg) do
	    if t.p==i then newt=newt.."{"..t.t.."}"  end
	    newt=tagmerge2(newt)
	    newt=newt:gsub("(\\[^\\})]*)%1","%1"):gsub("(\\[ibusqa]%d)(.-)%1","%2%1")
	end
	if newt~="" then newline=newline..newt end
    end
    repeat newline,r=newline:gsub("{\\N","\\N{") until r==0
    newtext="{"..stg.."}"..newline:gsub("{}","")
    newtext=newtext:gsub("({%*?\\[^}]-})",function(tg) return duplikill(tg) end)
    newtext=extrakill(newtext,2)
    line=subs[sel[1]]
    line.text=newtext
    subs[sel[1]]=line
    for z=#sel,2,-1 do subs.delete(sel[z]) end
    sel={sel[1]}
    act=sel[1]
    return sel, act
end



function add_an8(subs,sel)
	for z,i in ipairs(sel) do
	progress("Alien8ing "..z.."/"..#sel)
	line=subs[i]
	text=line.text
	if res.an8=="q2" then
		if text:match("\\q2") then text=text:gsub("\\q2",""):gsub("{}","")
		else text="{\\q2}"..text	text=text:gsub("\\q2}{\\","\\q2\\") end
	else
		text,r=text:gsub("\\(an%d)","\\"..res.an8)
		if r==0 then
			text="{\\"..res.an8.."}"..text
			text=text:gsub("({\\an%d)}{\\","%1\\")
		end
	end
	line.text=text
	subs[i]=line
	end
end



--	Motion Blur	--	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function motionblur(subs,sel)
mblur=res.mblur mbdist=res.mbdist mbalfa=res.mbalfa mb3=res.mb3 keepblur=res.keepblur
    for z=#sel,1,-1 do
        progress("Blurring "..#sel-z+1 .."/"..#sel)
	i=sel[z]
	line=subs[i]
        text=line.text
	if text:match("clip%(m") then
		if not text:match("\\pos") and not text:match("\\move") then text=getpos(subs,text) end
		if not res.keepblur then text=addtag("\\blur"..mblur,text) end
		text=text:gsub("{%*?\\[^}]-}",function(tg) return duplikill(tg) end)
		c1,c2,c3,c4=text:match("clip%(m ([%-%d%.]+) ([%-%d%.]+) l ([%-%d%.]+) ([%-%d%.]+)")
		if c1==nil then t_error("There seems to be something wrong with your clip.",1) end
		text=text:gsub("\\i?clip%b()","")
		text=addtag3("\\alpha&H"..mbalfa.."&",text)
		cx=c3-c1
		cy=c4-c2
		cdist=math.sqrt(cx^2+cy^2)
		mbratio=cdist/mbdist*2
		mbx=round(cx/mbratio*100)/100
		mby=round(cy/mbratio*100)/100
		text2=text
		:gsub("\\pos%(([%-%d%.]+),([%-%d%.]+)",function(a,b) return "\\pos("..a-mbx..","..b-mby end)
		:gsub("\\move%(([%-%d%.]+),([%-%d%.]+),([%-%d%.]+),([%-%d%.]+)",function(a,b,c,d) return "\\move("..a-mbx..","..b-mby..","..c-mbx..","..d-mby end)
		l2=line
		l2.text=text2
		subs.insert(i+1,l2)
		for s=z+1,#sel do
			sel[s]=sel[s]+1
		end
		table.insert(sel,sel[z]+1)
		if res.mb3 then
			line.text=text
			subs.insert(i+1,line)
			for s=z+1,#sel do
				sel[s]=sel[s]+1
			end
			table.insert(sel,sel[z]+1)
		end
		text=text
		:gsub("\\pos%(([%-%d%.]+),([%-%d%.]+)",function(a,b) return "\\pos("..a+mbx..","..b+mby end)
		:gsub("\\move%(([%-%d%.]+),([%-%d%.]+),([%-%d%.]+),([%-%d%.]+)",function(a,b,c,d) return "\\move("..a+mbx..","..b+mby..","..c+mbx..","..d+mby end)
	else noclip=true
	end
	line.text=text
	subs[i]=line
    end
    if noclip then t_error("Some lines weren't processed - missing clip.\n(2 points of a vectorial clip are needed for motion direction.)") noclip=nil end
end



--	Shift Tags sel	--	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function shitfags(subs,sel)
	local ref=nobra(subs[sel[1]].text)
	sametxt=true
	local arrow,arrow2bell
	for z,i in ipairs(sel) do
		local l=subs[i]
		local t=l.text
		if nobra(t)~=ref then sametxt=false end
		if t:match'>\\' and t:match'{•}' then arrow2bell=true end
		if t:match'>\\' then arrow=true end
	end
	for z,i in ipairs(sel) do
		progress("Shifting "..z.."/"..#sel)
		local l=subs[i]
		local t=l.text
		local stags=t:match(STAG) or ""
		-- arrow to bell
		if arrow2bell then
			local tag=t:match(">(\\[^\\}]*)")
			if tag then
				t=t:gsub(">\\[^\\}]*",""):gsub("{}","")
				repeat t,r=t:gsub("({•})({[^}]*})","%2%1") until r==0
				t=t:gsub("{•}",wrap(tag))
				t=tagmerge(t)
				t=t:gsub(ATAG,function(a) return duplikill(a) end)
			end
		-- arrow to arrow
		elseif arrow and sametxt then
			local tag=t:match(">(\\[^\\}]*)")
			t=t:gsub(">\\[^\\}]*",""):gsub("{}","")
			stags=stags:gsub(">\\[^\\}]*",""):gsub("{}","")
			if z==1 then -- GUI on line 1
				G={
				{x=0,y=0,class="label",label="Tag to shift (on line 1): "..tag:gsub("&","&&")},
				{x=0,y=1,width=16,class="edit",name="shift",value=ref},
				{x=0,y=2,class="label",label="Place a '>' where you want the tag to move. Multiple places are possible."},
				}
				Pr,rez=ADD(G,{"GO","Leave"},{ok='GO',close='Leave'})
				if Pr=="Leave" or not rez.shift:match '>' then ak() end
			end
			if tag then -- shift
				local nvis=rez.shift:gsub(">","")
				if nvis~=ref then t_error("Error: Text has changed.\n<- "..vis.."\n-> "..nvis,1) end
				t=t:gsub("(\\t)(%b())",function(a,b) return a..b:gsub("\\","/") end)
				nt=rez.shift:gsub(">",wrap(tag))
				t2=retextmod(t,nt)
				t2=stags..t2
				t=t2:gsub("(\\t)(%b())",function(a,b) return a..b:gsub("/","\\") end)
				:gsub(ATAG,function(s) return duplikill(s) end)
			end
		-- shift right or left
		else
			t=t:gsub(STAG,"")
			t=tagmerge(t)
			t=t:gsub("\\N","\n"):gsub("}{","_||_")
			local shi=0
			repeat
				if not t:match"{switch}$" then
					-- forward
					t=re.sub(t,"({[^}]*\\\\[^}]*})(\n*.[\n ]*)","\\2\\1")
				else
					-- backward
					t=re.sub(t,"(\n*.[\n ]*)({[^}]*\\\\[^}]*})","\\2\\1")
				end
				shi=shi+1
			until shi==shiftby
			t=stags..t:gsub("_||_","}{"):gsub("\n","\\N")
			t=tagmerge(t):gsub(ATAG.."$","")
			t=t:gsub(STAG,function(s) return duplikill(s) end)
		end
		l.text=t
		subs[i]=l
	end
end



--	Shift Arrow Tag		--	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function shiftarrow(subs,sel,a)
	rine=subs[a]
	local t=rine.text
	local tag=t:match(">(\\[^\\}]*)")
	t=t:gsub(">\\[^\\}]*",""):gsub("{}","")
	if t:match"{•}" then
		t2=t
		repeat t2,r=t2:gsub("({•})({[^}]*})","%2%1") until r==0
		t2=t2:gsub("{•}",wrap(tag))
		t2=tagmerge(t2)
		t2=t2:gsub(ATAG,function(a) return duplikill(a) end)
	else
		t=t:gsub("(\\t)(%b())",function(a,b) return a..b:gsub("\\","/") end)
		local stags=t:match(STAG) or ""
		local vis=t:gsub("%b{}","")
		t=t:gsub(STAG,"")
		G={
		{x=0,y=0,class="label",label="Tag to shift: "..tag:gsub("&","&&")},
		{x=0,y=1,width=16,class="edit",name="shift",value=vis},
		{x=0,y=2,class="label",label="Place a '>' where you want the tag to move. Multiple places are possible."},
		}
		Pr,rez=ADD(G,{"GO","Leave"},{ok='GO',close='Leave'})
		if Pr=="Leave" or not rez.shift:match '>' then ak() end
		
		local nvis=rez.shift:gsub(">","")
		if nvis~=vis then t_error("Error: Text has changed.\n<- "..vis.."\n-> "..nvis,1) end
		nt=rez.shift:gsub(">",wrap(tag))
		t2=retextmod(t,nt)
		t2=stags..t2
		t2=t2:gsub("(\\t)(%b())",function(a,b) return a..b:gsub("/","\\") end)
	end
	rine.text=t2
	subs[a]=rine
	return a
end



--	Shift Tags act	--	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function shiftag(subs,sel,act)
    rine=subs[act]
    tags=rine.text:match(STAG) or ""
    ftags=tags:gsub("[{}]","")
    ftags=ftags:gsub("\\%a+%b()","") :gsub("\\an?%d","")
    cstext=rine.text:gsub(STAG,"")
    if tags:match'\\p1' then t_error("Line contains a drawing.\nYou don't wanna shift tags into that.",1) end
    rept={"drept"}
    -- build GUI
    shiftab={
	{x=0,y=0,width=3,class="label",label="[  Start Tags (Shift Right only)  ]   ",},
	{x=3,y=0,class="label",label="[  Inline Tags  ]   ",},
	}
    ftw=1
    -- regular tags -> GUI
    for f in ftags:gmatch("\\[^\\]+") do lab=f:gsub("&","&&")
	  cb={x=0,y=ftw,width=2,class="checkbox",name="chk"..ftw,label=lab,value=false,realname=f}
	  table.insert(shiftab,cb)	ftw=ftw+1
	  table.insert(rept,f)
    end
    table.insert(shiftab,{x=0,y=ftw+1,class="label",label="Shift by letter /"})
    table.insert(shiftab,{x=1,y=ftw+1,class="checkbox",name="word",label="word"})
    table.insert(shiftab,{x=0,y=ftw+2,width=2,class="intedit",name="rept",value=1,min=1})
    table.insert(shiftab,{x=0,y=ftw+3,width=2,class="checkbox",name="nuke",label="remove selected tags"})
    itw=1
    -- inline tags
    if cstext:match(ATAG) then
      for f in cstext:gmatch(ATAG) do lab=f:gsub("&","&&")
	if itw==31 then lab="Error: 30 tags max" f="" end
	if itw==32 then break end
	  cb={x=3,y=itw,class="checkbox",name="chk2"..itw,label=lab,value=false,realname=f}
	  drept=0 for r=1,#rept do if f==rept[r] then drept=1 end end
	  if drept==0 then
	  table.insert(shiftab,cb)	itw=itw+1
	  table.insert(rept,f)
	  end
      end
    end
	repeat
	    if press=="All Inline Tags" then
		for key,val in ipairs(shiftab) do
		    if val.class=="checkbox" and val.x==3 then val.value=true end
		    if val.class=="checkbox" and val.x<3 then val.value=res[val.name] end
		end
	    end
	press,rez=ADD(shiftab,{"Shift Left","Shift Right","All Inline Tags","Cancel"},{ok='Shift Right',close='Cancel'})
	until press~="All Inline Tags"
	if press=="Cancel" then ak() end
	if press=="Shift Right" then R=true else R=false end
	if press=="Shift Left" then L=true else L=false end
	
	
	-- nuke tags
	if rez.nuke then
	  for key,val in ipairs(shiftab) do
	    if val.class=="checkbox" and rez[val.name] and val.x==0 and val.name~="nuke" then
	      tags=tags:gsub(esc(val.realname),"")
	      rez[val.name]=false
	    end
	    if val.class=="checkbox" and rez[val.name] and val.x==3 then
	      cstext=cstext:gsub(esc(val.realname),"")
	      rez[val.name]=false
	    end
	  end
	end

	-- shift inline tags
	cstext=cstext:gsub("\\N","{\\N}")
	if R then -- RIGHT
	  for s=#shiftab,1,-1 do stab=shiftab[s]
	    if rez[stab.name] and stab.x==3 then stag=stab.realname etag=esc(stag) retag=resc(stag)
	    rep=0
		repeat
		if not rez.word then
			repeat cstext,r=cstext:gsub(etag.."( *%b{} *)","%1"..stag) until r==0
			cstext=re.sub(cstext,retag.."([^ {}] *)","\\1"..retag)
			repeat cstext,r=cstext:gsub(etag.."( *%b{} *)","%1"..stag) until r==0
		else
			repeat cstext,r=cstext:gsub(etag.."(%b{})","%1"..stag) until r==0
			cstext=cstext:gsub(etag.."( *%S+ *)","%1"..stag)
			repeat cstext,r=cstext:gsub(etag.."(%b{})","%1"..stag) until r==0
		end
		rep=rep+1
		until rep==rez.rept
	    end
	  end
	elseif L then -- LEFT
	  for key,val in ipairs(shiftab) do
	    if rez[val.name]==true and val.x==3 then stag=val.realname etag=esc(stag) retag=resc(stag)
	    rep=0
		repeat
		if not rez.word then
			repeat cstext,r=cstext:gsub("(%b{} *)"..etag,stag.."%1") until r==0
			cstext=re.sub(cstext,"([^ {}] *)"..retag,retag.."\\1")
			repeat cstext,r=cstext:gsub("(%b{} *)"..etag,stag.."%1") until r==0
		else
			repeat cstext,r=cstext:gsub("((%b{}) *)"..etag,stag.."%1") until r==0
			cstext=cstext:gsub("(%S+ *)"..etag,stag.."%1")
			repeat cstext,r=cstext:gsub("((%b{}) *)"..etag,stag.."%1") until r==0
		end
		rep=rep+1
		until rep==rez.rept
	    end
	  end
	end
	
	cstext=cstext:gsub("{\\N}","\\N")
	cstext=tagmerge(cstext)
	cstext=cstext:gsub("(%b{})\\N","\\N%1"):gsub(ATAG,function(tg) return duplikill(tg) end)
	
	-- shift start tags
	startags=""
	for key,val in ipairs(shiftab) do
	    if rez[val.name]==true and val.x==0 and val.name~="nuke" then stag=val.realname etag=esc(stag)
		if R then
		startags=startags..stag
		tags=tags:gsub(etag,"")
		end
	    end
	end
	
	if startags~="" and R then
	    cstext="{_T_}"..cstext
	    REP=0
	    if not rez.word then
		repeat
		cstext=re.sub(cstext,"\\{_T_\\}([\\w[:punct:]]\\s*)","\\1\\{_T_\\}")
		cstext=cstext
		:gsub("{_T_}(\\N%s?)","%1{_T_}")
		:gsub("{_T_}(%b{}%s*)","%1{_T_}")
		:gsub("{_T_}(\\N%s?)","%1{_T_}")
		REP=REP+1
		until REP==rez.rept
	    else
		repeat
		cstext=cstext
		:gsub("{_T_}(%s*[^%s]+%s*)","%1{_T_}")
		:gsub("{_T_}(%s?\\N%s?)","%1{_T_}")
		:gsub("{_T_}(%b{})","%1{_T_}")
		:gsub("{_T_}(%s?\\N%s?)","%1{_T_}")
		REP=REP+1
		until REP==rez.rept
	    end
	    cstext=cstext
	    :gsub("_T_",startags)
	    :gsub("{(%*?\\[^}]-)}{(%*?\\[^}]-)}","{%1%2}")
	end
	
	text=tags..cstext
	text=text:gsub("{(%*?\\[^}]-)}{(%*?\\[^}]-)}","{%1%2}")
	:gsub("^{}","")
	:gsub(ATAG,function(tg) return duplikill(tg) end) :gsub("^{%*","{")
	
    rine.text=text
    subs[act]=rine
end



--	Alpha Shift	--	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function alfashift(subs,sel)
	count=0
	for z,i in ipairs(sel) do
	progress("Shifting "..z.."/"..#sel)
	line=subs[i]
	text=line.text
	if z>1 then
		text=text:gsub("^{([^}]*)(\\alpha&HFF&)([^}]*)}","{%1%3}{%2}"):gsub("{}","")
		aa=re.find(text,"{\\\\alpha&HFF&}[^{} ]")
		if not aa then t_error("Line #"..i-line0.." does not appear to have \\alpha&&HFF&&",1) end
		switch=0
		repeat
			repeat text,c=text:gsub("({\\alpha&HFF&})(%b{} ?)","%2%1") until c==0
			text=re.sub(text,"({\\\\alpha&HFF&})([^{} ])","\\2\\1")
			text=text
			:gsub("({\\alpha&HFF&}) "," %1")
			:gsub("({\\alpha&HFF&})\\N","\\N%1")
			:gsub("({\\alpha&HFF&})$","")
			switch=switch+1
		until switch>=count
	end
	count=count+1*shiftby
	line.text=text
	subs[i]=line
	end
end



--	Alpha Shift 2	--	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function alfashift2(subs,sel)
	ash=res.ash
	for z,i in ipairs(sel) do
	progress("Shifting "..z.."/"..#sel)
	line=subs[i]
	text=line.text
	text=text:gsub("\\alpha","\\"..ash)
	line.text=text
	subs[i]=line
	end
end



--	Alfa Time	--	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function alfatime(subs,sel)
    -- collect / check text
    for z,i in ipairs(sel) do
	text=subs[i].text
	if z==1 then alfatext=text:gsub(STAG,"")
	else alfatext2=text:gsub(STAG,"") 
	  if alfatext2~=alfatext then t_error("Text must be the same \nfor all selected lines",1) end
	end
	if text:match'\\p1' then t_error("Line #"..i-line0.." contains a drawing.\nYou can't alpha time that.",1) end
    end
    
    if not alfatext:match("@") then
	-- GUI
	local note=''
	if #sel>1 then note=note..'\n"Alpha Time" will be applined only to first line.' end
	atGUI={{x=0,y=0,width=5,height=8,class="textbox",name="alfa",value=alfatext},
	{x=0,y=8,class="label",label="Break the text with 'Enter' the way it should be alpha-timed. (lines selected: "..#sel..")"..note},}
	ATP,rez=ADD(atGUI,{"Alpha Text","Alpha Time","Cancel"},{ok='Alpha Text',close='Cancel'})
	if ATP=="Cancel" then ak() end
	data=rez.alfa
    else
	data=alfatext:gsub("@","\n")
	ATP="Alpha Time"
    end
	if not data:match("\n") then data=data:gsub(" "," \n") end
	-- sort data into a table
	altab={}	data=data.."\n"
	ac=1
	data2=""
	for al in data:gmatch("(.-\n)") do 
	    al2=al:gsub("\n","{"..ac.."}") ac=ac+1 data2=data2..al2
	    if al~="" then 
	        table.insert(altab,al2) 
	    end
	end
	
    -- apply alpha text
    if ATP=="Alpha Text" then
      if #altab~=#sel then t_error("Mismatch: "..#sel.." selected lines, "..#altab.." alpha text lines",1) end
      for z,i in ipairs(sel) do
        altxt=""
	for a=1,z do altxt=altxt..altab[a] end
	line=subs[i]
	text=line.text
	if altab[z]~=nil then
		tags=text:match(STAG) or ""
		text=data2
		:gsub("\n","")
		:gsub(esc(altxt),altxt.."{\\alpha&HFF&}")
		:gsub("({\\alpha&HFF&}.-){\\alpha&HFF&}","%1")
		:gsub("{\\alpha&HFF&}$","")
		:gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}")
		:gsub("{%d+}","")
		:gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}")
		text=tags..text
	end
	line.text=text
	subs[i]=line
      end
    end
    
    -- apply alpha text + split line
    if ATP=="Alpha Time" then
	line=subs[sel[1]]
	start=line.start_time
	endt=line.end_time
	dur=endt-start
	f=dur/#altab
	for a=#altab,1,-1 do
		altxt=""
		altxt=altxt..altab[a]
		line.text=line.text:gsub("@","")
		line2=line
		tags=line2.text:match(STAG) or ""
		line2.text=data2
		:gsub("\n","")
		:gsub(esc(altxt),altxt.."{\\alpha&HFF&}")
		:gsub("({\\alpha&HFF&}.-){\\alpha&HFF&}","%1")
		:gsub("{\\alpha&HFF&}$","")
		:gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}")
		:gsub("{%d+}","")
		line2.text=tags..line2.text
		line2.start_time=start+f*(a-1)
		line2.end_time=start+f+f*(a-1)
		subs.insert(sel[1]+1,line2)
	end
	subs.delete(sel[1])
    end
end


--	StrikeAlpha	--	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function strikealpha(subs,sel)
	-- GUI for {~}
	local G={
	{x=0,y=0,class="floatedit",name="xx",value=0,hint="main value"},
	{x=1,y=0,class="checkbox",name="Y",label="diff. Y value",hint="Check if you want a different value for yshad or fscy"},
	{x=2,y=0,class="floatedit",name="yy",value=0,hint="optional Y value"},
	{x=0,y=1,width=3,class="label",label="Set a value for tags to replace {~}. Choose which tags to use."},
	}
	local btn={"fscx+fsxy","xshad+yshad","fax","Cancel"}
	local SATAG
	
    for z,i in ipairs(sel) do
        progress("Striking "..z.."/"..#sel)
	l=subs[i]
	t=l.text
	-- {~} replacer
	repeat t,r=t:gsub("{~}(%b{})","%1{~}"):gsub("{~}(\\N)","%1{~}") until r==0
	t=t:gsub("{~}",function(a) if SATAG then return SATAG end
		SAP,sar=ADD(G,btn,{ok='fscx+fsxy',close='Cancel'})
		if SAP=="Cancel" then ak() end
		local xx,yy
		xx=sar.xx
		yy=sar.xx
		if sar.Y then yy=sar.yy end
		if SAP=="fscx+fsxy" then SATAG="{\\fscx"..xx.."\\fscy"..yy.."}" end
		if SAP=="xshad+yshad" then SATAG="{\\xshad"..xx.."\\yshad"..yy.."}" end
		if SAP=="fax" then SATAG="{\\fax"..xx.."}" end
		return SATAG
		end,1)
	
	-- {•} replacer
	repeat t,r=t:gsub("{•}({[^}]*})","%1{•}") until r==0
	t2=t:gsub("{•([^}]+)}$","%1"):gsub("{•([^}]+)}([^}{]*)({?)","{•%1%2}%3"):gsub("{•}([^ {}]+%s*)","{•%1}")
	if t2==t then t=t:gsub("{•([^{}]+)}","%1") else t=t2 end
	
	-- alphas
	t=t
	:gsub("\\s1","\\alpha&H00&")
	:gsub("\\s0","\\alpha&HFF&")
	:gsub("\\u1","\\alpha&HFF&")
	:gsub("\\u0","\\alpha&H00&")
	:gsub("([1234])@(%x%x)@","{\\%1a&H%2&}")
	:gsub("@(%x%x)@","{\\alpha&H%1&}")
	:gsub("([1234])@0","{\\%1a&H00&}")
	:gsub("@0","{\\alpha&H00&}")
	:gsub("([1234])@","{\\%1a&HFF&}")
	:gsub("@","{\\alpha&HFF&}")
	:gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}")
	
	if l.text==t then
		t=t:gsub(ATAG,function(a) repeat a,r=a:gsub("(\\[1234]a%b&&)(.-)(\\alpha%b&&)","%2%3%1") until r==0 return a end)
	end
	
	l.text=t
	subs[i]=l
    end
end



--	SvartAlfa	--	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function svartalfa(subs,sel)
	alv={}
	elf=''
	-- collect tags
	for z,i in ipairs(sel) do
		local l=subs[i]
		local t=l.text
		for tag in t:gmatch("\\%w+a%b&&") do
			if not elf:match(tag) then table.insert(alv,tag) elf=elf..tag end
		end
	end
	if #alv==0 then t_error("No alpha tags found in selected lines.",1) end
	table.sort(alv)
	
	-- GUI
	local G={{x=0,y=0,width=2,class='label',label='Set (hex) values for replacements...'}}
	for i=1,#alv do
		local tg,tp,val
		tg=alv[i]
		tp,val=tg:match("(\\%w+)&H(%x%x)&")
		table.insert(G,{x=0,y=i,class='label',label=tp..': replace '..val..' with:'})
		table.insert(G,{x=1,y=i,class='edit',name=tp..val,value=val})
		if i==smax then table.insert(G,{x=0,y=i+1,width=2,class='label',label='Maximum of '..smax..' items reached. (Total: '..#alv..')'}) break end
	end
	local btn={'OK','Nope'}
	SP,rez=ADD(G,btn,{ok='OK',close='Nope'})
	if SP=='Nope' then ak() end
	
	-- replacements
	for z,i in ipairs(sel) do
		local l=subs[i]
		local t=l.text
		if t:match'\\%w+a%b&&' then
			for a=1,#alv do
				local tg,tp,val,val2
				tg=alv[a]
				tp,val=tg:match("(\\%w+)&H(%x%x)&")
				val2=rez[tp..val]
				if val2 and val2:match"^%x%x$" and val2~=val then
					t=t:gsub(tg,tp.."&H"..val2.."&")
				end
				if a==smax then break end
			end
			l.text=t
			subs[i]=l
		end
	end
	
end



--	Betastrike	--	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function betastrike(subs,sel)
    for z,i in ipairs(sel) do
	progress("Striking "..z.."/"..#sel)
        l=subs[i]
	t=l.text
	-- reverse words \s1 ... \s0
	t,r=t:gsub("({[^}]*\\s1[^}]*} *)(.+ .+)( *{[^}]*\\s0}[^}]*)",function(a,b,c)
		tab={}
		for w in b:gmatch("%S+") do
			table.insert(tab,1,w)
		end
		d=table.concat(tab,' ')
		return a..d..c
		end)
	if r>0 then t=t:gsub("\\s[01]",""):gsub("{}","") end
	
	-- reverse segments \u1 ... \u0 ...
	t,r=t:gsub("(\\u1})(.-)( *)({[^}]*\\u0})(.*)",function(a,b,s,c,d)
		return a..d..s..c..b
		end)
	if r>0 then t=t:gsub("\\u[01]",""):gsub("{}","") end
	
	
	-- flip {~}... / {•}...
	t,r=t:gsub("({•}%b{})(.-)({~}%b{})",function(a,b,c) return c..b..a end)
	if r==0 then t=t:gsub("({~}%b{})(.-)({•}%b{})",function(a,b,c) return c..b..a end) end
	t,r=t:gsub("({•}[%w']+)(.-)({~}[%w']+)",function(a,b,c) return c..b..a end)
	if r==0 then t=t:gsub("({~}[%w']+)(.-)({•}[%w']+)",function(a,b,c) return c..b..a end) end
	t,r=t:gsub("({•}[%w']+)(.-)({~}[%w']+)",function(a,b,c) return c..b..a end)
	if r==0 then t=t:gsub("({~}[%w']+)(.-)({•}[%w']+)",function(a,b,c) return c..b..a end) end
	t,r=t:gsub("({~})([%w']+.-)({•}%b{})",function(a,b,c) return c..b..a end)
	if r==0 then t=t:gsub("({•}%b{})(.-)({~})([%w']+)",function(a,b,c,d) return c..b..a..d end) end
	t,r=t:gsub("({•})([%w']+.-)({~}%b{})",function(a,b,c) return c..b..a end)
	if r==0 then t=t:gsub("({~}%b{})(.-)({•})([%w']+)",function(a,b,c,d) return c..b..a..d end) end
	
	l.text=t
	subs[i]=l
    end
end



--	Deltastrike	--	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function deltastrike(subs,sel)
    for z,i in ipairs(sel) do
        progress("Striking "..z.."/"..#sel)
	l=subs[i]
	t=l.text
	for d=1,#D1 do
		local repl=D2[d] or D1[d]
		t=t:gsub(esc(D1[d]),repl)
	end
	t=tagmerge(t)
	if t~=l.text then
		l.text=t
		subs[i]=l
	end
    end
end



--	Converter	--	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function converter1(subs,sel) konverter(subs,sel,1) end
function converter2(subs,sel) konverter(subs,sel,2) end

function konverter(subs,sel,mode)
	for i=1,#subs do	if subs[i].class=="dialogue" then line0=i-1 break end		end
	ADD=aegisub.dialog.display
	ADP=aegisub.decode_path
	ak=aegisub.cancel
	konvert=ADP("?user").."\\konverter.dat"
	file=io.open(konvert)
	if file==nil then 
		file=io.open(konvert,"w")
		file:close()
		file=io.open(konvert)
	end
	local sett=file:read("*all")
	file:close()
	-- main gui
	if sett=="" then
		addcongui(sett)
	-- check lines
	else 
		lines={} -- collect text
		for z,i in ipairs(sel) do
			l=subs[i]
			table.insert(lines,l.text)
		end
		-- collect things to replace
		convert={}
		convert2={}
		local eword
		for con1,a,k,con2 in sett:gmatch("([^\n]*)_is_?(%u*)_([ck])onverted_to_([^\n]*)") do
			-- loggtab({con1,a,con2})
			if k=='k' then ord=true else ord=false end
			eword=esc(con1)
			for i=1,#lines do
				local t=lines[i]
				if mode==2 then t=nobra(t) end	-- mode 1 or 2 read
				if t:match(eword) and a=="ALWAYS" then table.insert(convert,{con1,con2,ord}) break end
				if t:match(eword) and a=="" and ord==false then table.insert(convert2,{con1,con2,ord}) break end
				if ord and a=="" then
					if re.match(t,'\\b'..resc(con1)..'\\b') then
					table.insert(convert2,{con1,con2,ord}) break end
				end
			end
		end
		-- deal with ASK things
		if #convert2>0 then
			local g={{x=0,y=0,class="label",label="Which should be converted?"}}
			for i=1,#convert2 do
				local k=convert2[i]
				local r={x=0,y=i,class="checkbox",name="k"..i,label=k[1].." --> "..k[2]}
				table.insert(g,r)
			end
			PA,rez=ADD(g,{"Selected","All","None","Cancel"},{close='Cancel'})
			if PA=="Cancel" then ak() end
			for i=1,#convert2 do
				local k=convert2[i]
				if PA=="All" or PA=="Selected" and rez["k"..i] then table.insert(convert,k) end
			end
		end
		-- conversion
		local check=0
		converted=''
		conversions=''
		for z,i in ipairs(sel) do
			l=subs[i]
			t=lines[z]
			t2=t
			for c=1,#convert do
				c1=convert[c][1]
				c2=convert[c][2]
				word=convert[c][3]
				-- mode 1 or 2 write
				if mode==1 then
					if word then	t2=re.sub(t2,'\\b'..resc(c1)..'\\b',c2)
					else		t2=t2:gsub(esc(c1),c2) end
				else
					if word then	t2=vis_replace(t2,'\\b'..resc(c1)..'\\b',c2,word)
					else		t2=vis_replace(t2,esc(c1),c2) end
				end
				if t~=t2 and not conversions:match(esc(c1)..', ') then conversions=conversions..c1..', ' end
			end
			if t~=t2 then check=check+1 converted=converted..'line #'..i-line0..": "..t2..'\n ' end
			l.text=t2
			subs[i]=l
		end
		if check==0 then
			addcongui(sett)
		end
		if mode==2 then converted=converted:gsub("%b{}","") end
		conversions=conversions:gsub(", $","")
		if #sel>20 and check>0 then logg(converted) logg('Lines modified: '..check) logg('Conversions made for: '..conversions) end
	end
end

-- Converter main GUI --
function addcongui(sett)
	local G={
	{x=0,y=0,width=3,class="label",label="No conversion made. You can add a new one.\nItems in the list are taken as literal strings.",},
	{x=0,y=1,width=1,class="label",label="String to be matched:   ",},
	{x=0,y=2,width=3,class="edit",name="r1",value="",hint=""},
	{x=0,y=3,width=3,class="label",label="String to replace it:",},
	{x=0,y=4,width=3,class="edit",name="r2",value="",hint=""},
	{x=1,y=1,width=2,class="checkbox",name="word",label="Whole word only",},
	{x=0,y=5,width=2,class="label",label="When to make the replacement:"},
	{x=2,y=5,class="dropdown",name="when",items={"always","ask"},value="always",hint="Conversion will either be made automatically, \nor you will be asked whether you want it."},
	}
	local B={"Add","Edit List","Cancel"}
	CP,res=ADD(G,B,{close='Cancel'})
	if CP=="Cancel" then ak() end
	if CP=="Add" and res.r1~="" then
		local always,amode,kon
		if res.when=="always" then always="_ALWAYS" amode="ask" else always="" amode="always" end
		kon='converted'
		if res.word then kon='konverted' end
		newc=res.r1.."_is"..always.."_"..kon.."_to_"..res.r2.."\n"
		-- check if entry exists
		local a,check=sett:match(esc(res.r1).."_is(_?%a*)_"..kon.."_to_([^\n]*)\n")
		if check then
			if check==res.r2 and a==res.when then t_error("Given entry already exists.",1) end
			if check==res.r2 and a~=res.when then
				yesno("Entry exists with setting '"..amode.."'.\nReplace with the new one? ("..res.r2..", "..res.when..")")
				if YN=="No" then ak() end
				sett=sett:gsub(esc(res.r1).."_is(_?%a*)_"..kon.."_to_([^\n]*)\n","")
			end
			if check~=res.r2 then
				yesno("Entry '"..res.r1.."' exists with setting '"..amode.."' and converts to '"..check.."'.\nReplace with the new one? ("..res.r2..", "..res.when..")")
				if YN=="No" then ak() end
				sett=sett:gsub(esc(res.r1).."_is(_?%a*)_"..kon.."_to_([^\n]*)\n","")
			end
		end
		-- save
		sett=sett..newc
		file=io.open(konvert,"w")
		file:write(sett)
		file:close()
		t_error('Conversion added. Saved to:\n'..konvert)
	end
	if CP=="Edit List" then
		local g={
		{x=0,y=0,class="label",label="Here you can add or remove as many conversions as you need, as long as you keep the correct format.\nFaulty lines will be discarded. One conversion per line.\nFormat: either 'String1_is_converted_to_String2' or 'String1_is_ALWAYS_converted_to_String2'\n'converted' = regular mode; 'konverted' = whole word only.",},
		{x=0,y=1,height=13,class="textbox",name="set",value=sett},
		}
		repeat
			if PE=="A-Z Sort"then
				local tb={}
				for l in rez.set:gmatch("([^\n]+\n)") do table.insert(tb,l) end
				table.sort(tb)
				nt=""
				for t=1,#tb do
					nt=nt..tb[t]
				end
				g[2].value=nt
			end
		PE,rez=ADD(g,{"Save","A-Z Sort","Cancel"},{ok='Save',close='Cancel'})
		until PE~="A-Z Sort"
		if PE=="Cancel" then ak() end
		
		local set=rez.set:gsub("([^\n])$","%1\n"):gsub("_is_[Aa]lways_([ck])onverted_","_is_ALWAYS_%1onverted_")
		sett2=''
		for con in set:gmatch("[^\n]*_is_?%a*_[ck]onverted_to_[^\n]*\n") do
			sett2=sett2..con
		end
		file=io.open(konvert,"w")
		file:write(sett2)
		file:close()
		t_error('List has been modified. Saved to:\n'..konvert)
	end
end

--	reanimatools -------------------------------------
function esc(str) str=str:gsub("[%%%(%)%[%]%.%-%+%*%?%^%$]","%%%1") return str end
function resc(str) str=str:gsub("[%%%(%)%[%]%.%*%+%?%^%$\\]","\\%1") return str end
function round(n,dec) dec=dec or 0 n=math.floor(n*10^dec+0.5)/10^dec return n end
function wrap(str) return "{"..str.."}" end
function nobra(t) return t:gsub("%b{}","") end
function nobrea(t) return t:gsub("%b{}",""):gsub("\\[Nh]","") end
function nobrea1(t) return t:gsub("%b{}",""):gsub(" *\\[Nh] *"," ") end
function tagmerge(t) repeat t,r=t:gsub("({\\[^}]-)}{(\\[^}]-})","%1%2") until r==0 return t end
function tagmerge2(t) repeat t,s=t:gsub("({\\[^}]-)}({[^\\}]-}){(\\[^}]-})","%2%1%3") t,r=t:gsub("({\\[^}]-)}{(\\[^}]-})","%1%2") until r==0 and s==0 return t end
function logg(m) m=tf(m) or "nil" aegisub.log("\n "..m) end
function logg2(m)
	local lt=type(m)
	aegisub.log("\n >> "..lt)
	if lt=='table' then
		aegisub.log(" (#"..#m..")")
		if not m[1] then
			for k,v in pairs(m) do
				if type(v)=='table' then vvv='[table]' elseif type(v)=='number' then vvv=v..' (n)' else vvv=v end
				aegisub.log("\n	"..k..': '..vvv)
			end
		elseif type(m[1])=='table' then aegisub.log("\n nested table")
		else aegisub.log("\n {"..table.concat(m,', ').."}") end
	else
		m=tf(m) or "nil" aegisub.log("\n "..m)
	end
end
function loggtab(m) m=tf(m) or "nil" aegisub.log("\n {"..table.concat(m,';').."}") end
function progress(msg) if aegisub.progress.is_cancelled() then ak() end aegisub.progress.title(msg) end
function t_error(message,cancel) ADD({{class="label",label=message}},{"OK"},{close='OK'}) if cancel then ak() end end

function tf(val)
	if val==true then ret="true"
	elseif val==false then ret="false"
	else ret=val end
	return ret
end

function detf(txt)
	if txt=="true" then ret=true
	elseif txt=="false" then ret=false
	else ret=txt end
	return ret
end

function yesno(message)
	YN=ADD({{class="label",label=message}},{"Yes","No"},{ok="Yes",close='No'})
end

function addtag(tag,text) text=text:gsub("^({\\[^}]-)}","%1"..tag.."}") return text end

function addtag2(tag,text) 	-- mask version
	tg=tag:match("\\%d?%a+")
	text=text:gsub("^{(\\[^}]-)}","{"..tag.."%1}")
	:gsub("("..tg.."[^\\}]+)([^}]-)("..tg.."[^\\}]+)","%2%1")
	return text 
end

function addtag3(tg,txt)
	no_tf=txt:gsub("\\t%b()","")
	tgt=tg:match("(\\%d?%a+)[%d%-&]") val="[%d%-&]"
	if not tgt then tgt=tg:match("(\\%d?%a+)%b()") val="%b()" end
	if not tgt then tgt=tg:match("\\fn") val="" end
	if not tgt then t_error("adding tag '"..tg.."' failed.") end
	if tgt:match("clip") then txt,r=txt:gsub("^({[^}]-)\\i?clip%b()","%1"..tg)
		if r==0 then txt=txt:gsub("^({\\[^}]-)}","%1"..tg.."}") end
	elseif no_tf:match("^({[^}]-)"..tgt..val) then txt=txt:gsub("^({[^}]-)"..tgt..val.."[^\\}]*","%1"..tg)
	elseif not txt:match("^{\\") then txt="{"..tg.."}"..txt
	elseif txt:match("^{[^}]-\\t") then txt=txt:gsub("^({[^}]-)\\t","%1"..tg.."\\t")
	else txt=txt:gsub("^({\\[^}]-)}","%1"..tg.."}") end
return txt
end


function duplikill(tagz)
	local tags1={"blur","be","bord","shad","xbord","xshad","ybord","yshad","fs","fsp","fscx","fscy","frz","frx","fry","fax","fay"}
	local tags2={"c","2c","3c","4c","1a","2a","3a","4a","alpha"}
	tagz=tagz:gsub("\\t%b()",function(t) return t:gsub("\\","|") end)
	for i=1,#tags1 do
	    tag=tags1[i]
	    repeat tagz,c=tagz:gsub("|"..tag.."[%d%.%-]+([^}]-)(\\"..tag.."[%d%.%-]+)","%1%2") until c==0
	    repeat tagz,c=tagz:gsub("\\"..tag.."[%d%.%-]+([^}]-)(\\"..tag.."[%d%.%-]+)","%2%1") until c==0
	end
	tagz=tagz:gsub("\\1c&","\\c&")
	for i=1,#tags2 do
	    tag=tags2[i]
	    repeat tagz,c=tagz:gsub("|"..tag.."&H%x+&([^}]-)(\\"..tag.."&H%x+&)","%1%2") until c==0
	    repeat tagz,c=tagz:gsub("\\"..tag.."&H%x+&([^}]-)(\\"..tag.."&H%x+&)","%2%1") until c==0
	end
	repeat tagz,c=tagz:gsub("\\fn[^\\}]+([^}]-)(\\fn[^\\}]+)","%2%1") until c==0
	repeat tagz,c=tagz:gsub("(\\[ibusq])%d(.-)(%1%d)","%2%3") until c==0
	repeat tagz,c=tagz:gsub("(\\an)%d(.-)(%1%d)","%3%2") until c==0
	tagz=tagz:gsub("(|i?clip%(%A-%))(.-)(\\i?clip%(%A-%))","%2%3")
	:gsub("(\\i?clip%b())(.-)(\\i?clip%b())",function(a,b,c)
	    if a:match("m") and c:match("m") or not a:match("m") and not c:match("m") then return b..c else return a..b..c end end)
	tagz=tagz:gsub("|","\\"):gsub("\\t%([^\\%)]-%)","")
	return tagz
end

function extrakill(text,o)
	local tags3={"pos","move","org","fad"}
	for i=1,#tags3 do
	    tag=tags3[i]
	    if o==2 then
	    repeat text,c=text:gsub("(\\"..tag.."[^\\}]+)([^}]-)(\\"..tag.."[^\\}]+)","%3%2") until c==0
	    else
	    repeat text,c=text:gsub("(\\"..tag.."[^\\}]+)([^}]-)(\\"..tag.."[^\\}]+)","%1%2") until c==0
	    end
	end
	repeat text,c=text:gsub("(\\pos[^\\}]+)([^}]-)(\\move[^\\}]+)","%1%2") until c==0
	repeat text,c=text:gsub("(\\move[^\\}]+)([^}]-)(\\pos[^\\}]+)","%1%2") until c==0
	return text
end

function retextmod(orig,text)
	local v1,v2,c,t2
	v1=nobrea(orig)
	c=0
	repeat
		t2=textmod(orig,text)
		v2=nobrea(text)
		c=c+1
	until v1==v2 or c==666
	if v1~=v2 then logg("Something went wrong with the text...") logg(v1) logg(v2) end
	return t2
end

function textmod(orig,text)
if text=="" then return orig end
    tk={}
    tg={}
	text=text:gsub("{\\\\k0}","")
	text=tagmerge(text)
	vis=nobra(text)
	ltrmatches=re.find(vis,".")
	if not ltrmatches then logg("text: "..text..'\nvisible: '..vis)
		logg("If you're seeing this, something really weird is happening with the re module.\nTry this again or rescan Autoload.")
	end
	  for l=1,#ltrmatches do
	    table.insert(tk,ltrmatches[l].str)
	  end
	stags=text:match(STAG) or ""
	text=text:gsub(STAG,"") :gsub("{[^\\}]-}","")
	orig=orig:gsub("{([^\\}]+)}",function(c) return wrap("\\\\"..c.."|||") end)
	count=0
	for seq in orig:gmatch("[^{]-{%*?\\[^}]-}") do
	    chars,as,tak=seq:match("([^{]-){(%*?)(\\[^}]-)}")
	    pos=re.find(chars,".")
	    if pos==nil then ps=0+count else ps=#pos+count end
	    tgl={p=ps,t=tak,a=as}
	    table.insert(tg,tgl)
	    count=ps
	end
	count=0
	for seq in text:gmatch("[^{]-{%*?\\[^}]-}") do
	    chars,as,tak=seq:match("([^{]-){(%*?)(\\[^}]-)}")
	    pos=re.find(chars,".")
	    if pos==nil then ps=0+count else ps=#pos+count end
	    tgl={p=ps,t=tak,a=as}
	    table.insert(tg,tgl)
	    count=ps
	end
    newline=""
    for i=1,#tk do
	newline=newline..tk[i]
	newt=""
	for n,t in ipairs(tg) do
	    if t.p==i then newt=newt..t.a..t.t end
	end
	if newt~="" then newline=newline.."{"..as..newt.."}" end
    end
    newtext=stags..newline:gsub("(|||)(\\\\)","%1}{%2"):gsub("({[^}]-)\\\\([^\\}]-)|||","{%2}%1")
    text=newtext:gsub("{}","")
    return text
end

function getpos(subs,text)
    st=nil defst=nil
    for g=1,#subs do
        if subs[g].class=="info" then
		local k=subs[g].key
		local v=subs[g].value
		if k=="PlayResX" then resx=v end
		if k=="PlayResY" then resy=v end
        end
	if resx==nil then resx=0 end
	if resy==nil then resy=0 end
        if subs[g].class=="style" then
		local s=subs[g]
		if s.name==line.style then st=s break end
		if s.name=="Default" then defst=s end
        end
	if subs[g].class=="dialogue" then
		if defst then st=defst else t_error("Style '"..line.style.."' not found.\nStyle 'Default' not found. ",1) end
		break
	end
    end
    if st then
	acleft=st.margin_l	if line.margin_l>0 then acleft=line.margin_l end
	acright=st.margin_r	if line.margin_r>0 then acright=line.margin_r end
	acvert=st.margin_t	if line.margin_t>0 then acvert=line.margin_t end
	acalign=st.align	if text:match("\\an%d") then acalign=text:match("\\an(%d)") end
	aligntop="789" alignbot="123" aligncent="456"
	alignleft="147" alignright="369" alignmid="258"
	if alignleft:match(acalign) then horz=acleft
	elseif alignright:match(acalign) then horz=resx-acright
	elseif alignmid:match(acalign) then horz=resx/2 end
	if aligntop:match(acalign) then vert=acvert
	elseif alignbot:match(acalign) then vert=resy-acvert
	elseif aligncent:match(acalign) then vert=resy/2 end
    end
    if horz>0 and vert>0 then 
	if not text:match("^{\\") then text="{\\rel}"..text end
	text=text:gsub("^({\\[^}]-)}","%1\\pos("..horz..","..vert..")}") :gsub("\\rel","")
    end
    return text
end


function nopar(tag,t)
    t=t:gsub("\\"..tag.."%b()","") :gsub("{}","")
    return t
end

function stylechk(subs,sn)
    for i=1,#subs do
        if subs[i].class=="style" then
	    local st=subs[i]
	    if sn==st.name then sr=st break end
	end
    end
    if sr==nil then t_error("Style '"..sn.."' doesn't exist.",1) end
    return sr
end

function shiftsel2(sel,i,mode)
	if i<sel[#sel] then
	for s=1,#sel do if sel[s]>i then sel[s]=sel[s]+1 end end
	end
	if mode==1 then table.insert(sel,i+1) end
	table.sort(sel)
return sel
end

function vis_replace(t,r1,r2,word)
	local nt=''
	repeat
		seg,t2=t:match("^(%b{})(.*)") --tags/comms
		if not seg then seg,t2=t:match("^([^{]+)(.*)") --text
			if not seg then break end
			if word then
				seg=re.sub(seg,r1,r2)
			else
				seg=seg:gsub(r1,r2)
			end
		end
		nt=nt..seg
		t=t2
	until t==''
	return nt
end



function doushiyou()
Pr=aegisub.dialog.display({{width=44,height=18,class="textbox",value=hlp}},{"OK","OK","OK","OK","Not OK","Maybe","IDK","...?!"},{close='Not OK'})
if Pr=='Not OK' then aegisub.cancel() end
end

--	Config		--
function saveconfig()
msqkonf="Masquerade config\n\n"
  for key,val in ipairs(GUI) do
    if val.class:match"edit" or val.class=="dropdown" then
	msqkonf=msqkonf..val.name..":"..res[val.name].."\n"
    end
    if val.class=="checkbox" and val.name~="config" and val.name~="help" then
	msqkonf=msqkonf..val.name..":"..tf(res[val.name]).."\n"
    end
  end
delta={
	{x=0,y=0,width=2,class="label",label="User-defined replacements for deltastrike:",},
	{x=0,y=1,class="label",label="{\\s1}",},
	{x=1,y=1,class="edit",name="s1",value=D2[1]},
	{x=0,y=2,class="label",label="{\\s0}",},
	{x=1,y=2,class="edit",name="s0",value=D2[2]},
	{x=0,y=3,class="label",label="{\\u1}",},
	{x=1,y=3,class="edit",name="u1",value=D2[3]},
	{x=0,y=4,class="label",label="{\\u0}",},
	{x=1,y=4,class="edit",name="u0",value=D2[4]},
	{x=0,y=5,class="label",label="{•}",},
	{x=1,y=5,class="edit",name="bell",value=D2[5]},
	{x=0,y=6,class="label",label="{~}",},
	{x=1,y=6,class="edit",name="wave",value=D2[6]},
}
CS,rez=ADD(delta,{"Save","Cancel"},{ok='Save',close='Cancel'})
if CS=='Cancel' then ak() end

for k,v in ipairs(delta) do
	if v.class=="edit" then
		msqkonf=msqkonf..'delta'..v.name..':'..rez[v.name]..'\n'
	end
end
masquecfg=ADP("?user").."\\masquerade.conf"
file=io.open(masquecfg,"w")
file:write(msqkonf)
file:close()
ADD({{class="label",label="Config saved to:\n"..masquecfg}},{"OK"},{close='OK'})
end

function loadconfig()
fconfig=ADP("?user").."\\masquerade.conf"
file=io.open(fconfig)
D1={"{\\s1}","{\\s0}","{\\u1}","{\\u0}","{•}","{~}"}
D2={}
    if file~=nil then
	konf=file:read("*all")
	io.close(file)
	  for key,val in ipairs(GUI) do
	    local V2
	    if val.class:match"edit" or val.class=="checkbox" or val.class=="dropdown" then
	      if res then V2=res[val.name] end
	      if konf:match(val.name) then val.value=V2 or detf(konf:match(val.name..":(.-)\n")) end
	      if val.def~=nil then val.value=val.def end
	    end
	  end
    for r in konf:gmatch("delta%w+:(.-)\n") do table.insert(D2,r) end
    end
end

function masquerade(subs,sel,act)
	if subs[act].effect=='help' then doushiyou() end
	ADD=aegisub.dialog.display
	ADP=aegisub.decode_path
	ak=aegisub.cancel
	ATAG="{%*?\\[^}]-}"
	STAG="^{\\[^}]-}"
	defmasks="mask:square:m 0 0 l 100 0 100 100 0 100:\n\nmask:rounded square:m -100 -25 b -100 -92 -92 -100 -25 -100 l 25 -100 b 92 -100 100 -92 100 -25 l 100 25 b 100 92 92 100 25 100 l -25 100 b -92 100 -100 92 -100 25 l -100 -25:\n\nmask:rounded square 2:m -100 -60 b -100 -92 -92 -100 -60 -100 l 60 -100 b 92 -100 100 -92 100 -60 l 100 60 b 100 92 92 100 60 100 l -60 100 b -92 100 -100 92 -100 60 l -100 -60:\n\nmask:rounded square 3:m -100 -85 b -100 -96 -96 -100 -85 -100 l 85 -100 b 96 -100 100 -96 100 -85 l 100 85 b 100 96 96 100 85 100 l -85 100 b -96 100 -100 96 -100 85 l -100 -85:\n\nmask:circle:m -100 -100 b -45 -155 45 -155 100 -100 b 155 -45 155 45 100 100 b 46 155 -45 155 -100 100 b -155 45 -155 -45 -100 -100:\n\nmask:equilateral triangle:m -122 70 l 122 70 l 0 -141:\n\nmask:right-angled triangle:m -70 50 l 180 50 l -70 -100:\n\nmask:alignment grid:m -500 -199 l 500 -199 l 500 -201 l -500 -201 m -701 1 l 700 1 l 700 -1 l -701 -1 m -500 201 l 500 201 l 500 199 l -500 199 m -1 -500 l 1 -500 l 1 500 l -1 500 m -201 -500 l -199 -500 l -199 500 l -201 500 m 201 500 l 199 500 l 199 -500 l 201 -500 m -150 -25 l 150 -25 l 150 25 l -150 25:\n\nmask:alignment grid 2:m -500 -199 l 500 -199 l 500 -201 l -500 -201 m -701 1 l 700 1 l 700 -1 l -701 -1 m -500 201 l 500 201 l 500 199 l -500 199 m -1 -500 l 1 -500 l 1 500 l -1 500 m -201 -500 l -199 -500 l -199 500 l -201 500 m 201 500 l 199 500 l 199 -500 l 201 -500 m -150 -25 l 150 -25 l 150 25 l -150 25 m -401 -401 l 401 -401 l 401 401 l -401 401 m -399 -399 l -399 399 l 399 399 l 399 -399:\n\n"
	maasks={"from clip"}
	allmasks={}
	masker=ADP("?user").."\\masquerade.masks"
	file=io.open(masker)
	if file then
		masx=file:read("*all")
		io.close(file)
	else masx=""
	end
	masklist=defmasks..masx
	for nam,msk in masklist:gmatch("mask:(.-):(.-):") do table.insert(maasks,nam) table.insert(allmasks,{n=nam,m=msk}) end
	for i=1,#subs do
		if subs[i].class=="dialogue" then line0=i-1 break end
	end
	GUI={
	-- Masks
	{x=0,y=0,class="label",label="Mask:",},
	{x=1,y=0,width=4,class="dropdown",name="mask",items=maasks,value="square"},
	{x=0,y=1,width=2,class="checkbox",name="masknew",label="New line  ",value=true,hint="create mask on a new line"},
	{x=2,y=1,width=2,class="checkbox",name="save",label="Save/delete  ",value=false,hint="save/delete a mask [type name below]"},
	{x=4,y=1,width=1,class="checkbox",name="remask",label="Remask   ",value=false,hint="replace current mask with selected"},
	{x=0,y=2,width=4,class="edit",name="maskname",value="mask name here",hint="Type name of the mask you want to save/delete\n(very long names will mess with the GUI)"},

	{x=4,y=2,class="dropdown",name="an8",items={"q2","an1","an2","an3","an4","an5","an6","an7","an8","an9"},value="an8"},
	{x=10,y=0,height=2,class="label",label=":\n:\n:",},
	
	-- Motion blur
	{x=5,y=0,class="label",label=" Blur:"},
	{x=6,y=0,width=3,class="floatedit",name="mblur",value=3,hint="motion blur"},
	{x=9,y=0,class="checkbox",name="keepblur",label="Keep",hint="keep current blur"},
	{x=5,y=1,class="label",label=" Dist.:"},
	{x=6,y=1,width=3,class="floatedit",name="mbdist",value=6,hint="distance between positions"},
	{x=5,y=2,class="label",label=" Alpha:"},
	{x=6,y=2,class="dropdown",name="mbalfa",value="80",items={"00","20","40","60","80","A0","C0","D0"},hint="motion blur alpha"},
	{x=9,y=1,class="checkbox",name="mb3",label="3 lines",hint="use 3 lines instead of 2"},
	
	-- Shift
	{x=7,y=2,class="label",label=" Shift by:"},
	{x=8,y=2,width=5,class="intedit",name="shiftby",value=1,min=1,max=666,hint="characters to shift tags by"},
	{x=11,y=1,class="label",label=" α S:"},
	{x=12,y=1,class="dropdown",name="ash",items={"α","1a","3a","4a"},value="α",hint="α: shift alpha by characters per line\n1a-4a: turn alpha into one of those"},	
	
	-- StrikeAlfa
	{x=11,y=0,width=2,class="label",label=" Strike mode: "},
	{x=13,y=0,width=2,class="dropdown",name="s_alfa",items={"StrikeAlpha","SvartAlfa","BetaStrike","DeltaStrike"},value="StrikeAlpha"},
	{x=13,y=1,class="label",label=" Svart:"},
	{x=14,y=1,class="dropdown",name="sa_max",items={"20","25","30","35","40","45"},value="20",hint="Maximum results for Svartalfa.\nYou can raise this if your monitor can handle it."},	
	{x=13,y=2,width=2,class="checkbox",name="gam",label="Gamma Rays",hint="Dangerous. Do NOT use!",def=false},
	
	{x=15,y=0,class="label",label=" Masquerade "..script_version},
	{x=15,y=1,class="checkbox",name="config",label="Save config",def=false},
	{x=15,y=2,class="checkbox",name="help",label="What the...",hint="What is all this? Help!",def=false},
	}
	loadconfig()
	P,res=ADD(GUI,
	{"Masquerade","Merge Tags","an8 / q2","Motion Blur","Shift Tags","Alpha Shift","Alpha Time","StrikeAlpha","Ωmega"},{cancel='Ωmega'})
	if P=="Ωmega" then ak() end
	shiftby=res.shiftby
	smax=tonumber(res.sa_max)
	if res.help then doushiyou() ak() end
	if res.config then saveconfig() ak() end
	if P=="Masquerade" and not res.save then sel=addmask(subs,sel) end
	if P=="Masquerade" and res.save then savemask(subs,sel,act) end
	if P=="StrikeAlpha" then
		if res.s_alfa=="DeltaStrike" then deltastrike(subs,sel)
		elseif res.s_alfa=="BetaStrike" then betastrike(subs,sel)
		elseif res.s_alfa=="SvartAlfa" then svartalfa(subs,sel)
		else strikealpha(subs,sel) end
	end
	if P=="an8 / q2" then add_an8(subs,sel,act) end
	if P=="Alpha Shift" then
		if res.ash=="α" then alfashift(subs,sel)
		else alfashift2(subs,sel) end
	end
	if P=="Alpha Time" then alfatime(subs,sel) end
	if P=="Motion Blur" then motionblur(subs,sel) end
	if P=="Merge Tags" and #sel>1 then sel,act=merge(subs,sel,act) end
	if P=="Shift Tags" then
		if #sel==1 then
		if subs[act].text:match">\\" then shiftarrow(subs,sel,act) else shiftag(subs,sel,act) end
		else shitfags(subs,sel) end
	end
	return sel,act
end

if haveDepCtrl then
  depRec:registerMacros({
	{script_name,script_description,masquerade},
	{": HELP : / Masquerade",script_description,doushiyou},
	{"Converter/raw","Converts things - all text",converter1},
	{"Converter/clean","Converts things - visible text",converter2},
  },false)
else
	aegisub.register_macro(script_name,script_description,masquerade)
	aegisub.register_macro(": HELP : / Masquerade",script_description,doushiyou)
	aegisub.register_macro("Converter/raw","Converts things - all text",converter1)
	aegisub.register_macro("Converter/clean","Converts things - visible text",converter2)
end