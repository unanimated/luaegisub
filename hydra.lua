script_name="HYDRA"
script_description="A multi-headed typesetting tool"
script_author="unanimated"
script_url1="http://unanimated.xtreemhost.com/ts/hydra.lua"
script_url2="https://raw.githubusercontent.com/unanimated/luaegisub/master/hydra.lua"
script_version="3.7"

-- SETTINGS - feel free to change these

startup_mode=1		-- 1: only basic tags (fast), 2: medium (no transforms), 3: full // you can load the rest from the GUI in modes 1-2
default_blur=0.5
default_border=0
default_shadow=0
default_fontsize=50
default_spacing=1
default_fax=0.05
default_fay=0.05

-- ^ this block (with '=' replaced with ':') can be saved as 'hydra.conf' in your Application Data with values that will override these
-- it must contain all 8 lines. you can use that if you don't want to overwrite these every time you update
-- you can also get the default here: http://unanimated.xtreemhost.com/ts/hydra.conf

-- this is the order "sort tags in set order" will use:
order="\\r\\fad\\fade\\an\\q\\blur\\be\\bord\\shad\\fn\\fs\\fsp\\fscx\\fscy\\frx\\fry\\frz\\c\\2c\\3c\\4c\\alpha\\1a\\2a\\3a\\4a\\xbord\\ybord\\xshad\\yshad\\pos\\move\\org\\clip\\iclip\\b\\i\\u\\s\\p"

-- END of SETTINGS

function checkonfig()
hconfig=aegisub.decode_path("?user").."//hydra.conf"
file=io.open(hconfig)
    if file~=nil then
	konf=file:read("*all")
	startup_mode=tonumber(konf:match("startup_mode:(%d)"))
	default_blur=tonumber(konf:match("default_blur:([%d%.]+)"))
	default_border=tonumber(konf:match("default_border:([%d%.]+)"))
	default_shadow=tonumber(konf:match("default_shadow:([%d%.]+)"))
	default_fontsize=tonumber(konf:match("default_fontsize:([%d%.]+)"))
	default_spacing=tonumber(konf:match("default_spacing:([%d%-%.]+)"))
	default_fax=tonumber(konf:match("default_fax:([%d%-%.]+)"))
	default_fay=tonumber(konf:match("default_fay:([%d%-%.]+)"))
	io.close(file)
    end
end
    
re=require'aegisub.re'

function hh9(subs, sel)
	-- get colours from input
	getcolours()
	
    for z, i in ipairs(sel) do
    cancelled=aegisub.progress.is_cancelled()
    if cancelled then aegisub.cancel() end
    aegisub.progress.title(string.format("Hydralizing line: %d/%d",z,#sel))
    prog=math.floor((z+0.5)/#sel*100)
    aegisub.progress.set(prog)
    line=subs[i]
    text=subs[i].text
    lay=line.layer    sty=line.style	act=line.actor	eff=line.effect
    if res.applay=="All Layers" or tonumber(res.applay)==lay then layergo=true else layergo=false end
    if res.applst=="All Styles" or res.applst==sty then stylego=true else stylego=false end
    if res.applac=="All Actors" or res.applac==act then actorgo=true else actorgo=false end
    if res.applef=="All Effects" or res.applef==eff then effectgo=true else effectgo=false end
    if layergo and stylego and actorgo and effectgo then GO=true else GO=false end
    if loaded<3 then GO=true end
	
	if not text:match("^{\\") then text="{\\hydra}"..text end		-- add {\} if line has no tags
	
	-- tag position
	place=res.linetext	if place==nil then place="" end
	if place:match("*") then pl1,pl2,pl3=place:match("(.*)(%*)(.*)") pla=1 else pla=0 end
	if res.tagpres~="--- presets ---" and res.tagpres~=nil then pla=1 end

    -- transforms
    if trans==1 and GO then
	
	tin=res.trin tout=res.trout
	if res.tend then
	tin=line.end_time-line.start_time-res.trin
	tout=line.end_time-line.start_time-res.trout
	end
	
	-- clean up existing transforms
	if text:match("^{[^}]*\\t") then
	text=text:gsub("^({\\[^}]-})",function(tg) return cleantr(tg) end)
	end
	
	if tmode==2 then
	    text=text:gsub("^({[^}]*\\t%([^%)]+)%)","%1\\alltagsgohere)")
	    :gsub("(\\clip%([^\\%)]+)(\\alltagsgohere)%)([^%)]-)%)","%1)%3%2)")
	end
	if tmode==3 then
	    text=text:gsub("(\\t%([^%)]+)%)","%1alltagsgohere)")
	end
	if tmode==1 then
	  if text:match("^{[^}]-\\t%(\\") and tin==0 and tout==0 and res.accel==1 then
	    text=text:gsub("^({[^}]*\\t%()\\","%1\\alltagsgohere\\")
	  else
	    text=text:gsub("^({\\[^}]*)}","%1".."\\t("..tin..","..tout..","..res.accel..",\\alltagsgohere)}") 
	  end
	end
	
	transform=""
	transform=gettags(transform)
	text=text:gsub("\\alltagsgohere",transform)
	text=text:gsub("\\t%(0,0,1,","\\t(")
	for tranz in text:gmatch("\\t(%([^%(%)]+%))") do
		tranz2=duplikill(tranz)
		tranz=esc(tranz)
		text=text:gsub(tranz,tranz2)
	end
	for tranz in text:gmatch("\\t(%([^%(%)]-%([^%)]-%)[^%)]-%))") do
		tranz2=duplikill(tranz)
		tranz=esc(tranz)
		text=text:gsub(tranz,tranz2)
	end
	
    -- non transform, ie the regular stuff
    elseif GO then
	-- temporarily remove transforms
	if text:match("\\t") then
	text=text:gsub("^({\\[^}]-})",function(tg) return trem(tg) end)
	if text:match("^{}") then text=text:gsub("^{}","{\\hydra}")  end
	end
	
	tags=""
	tags=gettags(tags)
	
	if pla==1 then 
	    	bkp=text
	    if res.tagpres=="before last char." then	
	    -- BEFORE LAST CHARACTER
		text=text:gsub("({\\[^}]-)}(.)$","%1"..tags.."}%2")
		if bkp==text then text=text:gsub("([^}])$","{"..tags.."}%1") end
		if bkp==text then text=text:gsub("([^}])({[^\\}]-})$","{"..tags.."}%1%2") end
	    elseif res.tagpres=="in the middle" or res.tagpres:match("of text") then  
	    -- SOMEWHERE IN THE MIDDLE
		clean=text:gsub("{[^}]-}","") :gsub("%s?\\[Nn]%s?"," ")
		text=text:gsub("%*","_ast_")
		lngth=math.floor(clean:len()*fak)		--aegisub.log("\n lngth "..lngth)
		text="*"..text
		text=text:gsub("%*({\\[^}]-})","%1*")
		m=0
		if lngth>0 then
		  repeat text=text:gsub("%*({[^}]-})","%1*") :gsub("%*(.)","%1*") :gsub("%*(%s?\\[Nn]%s?)","%1*") m=m+1
		  until m==lngth	end	--aegisub.log("\n text "..text)
		text=text:gsub("%*","{"..tags.."}") :gsub("({"..tags.."})({[^}]-})","%2%1") 
		:gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}") :gsub("_ast_","*")
	    elseif res.tagpres=="custom pattern" then
		pl1=esc(pl1)	pl3=esc(pl3)
		text=text:gsub(pl1.."({\\[^}]-)}"..pl3,pl1.."%1"..tags.."}"..pl3)
		if bkp==text then text=text:gsub(pl1..pl3,pl1.."{"..tags.."}"..pl3) end
	    else
	    -- AT ASTERISK POINT
		initags=text:match("^{\\[^}]-}") if initags==nil then initags="" end
		orig=text
		replace=place:gsub("%*","{"..tags.."}")
		v1=orig:gsub("{[^}]-}","")
		v2=replace:gsub("{[^}]-}","")
		if v1==v2 then
		  text=textmod(orig,replace)
		  text=initags..text
		end
	    end
	else
	-- REGULAR STARTING TAGS
	    text=text:gsub("^({\\[^}]-)}","%1"..tags.."}")
	end
	text=text:gsub("({%*?\\[^}]-})",function(tg) return duplikill(tg) end)
	
	
	-- bold
	if res["bolt"] then
	    if text:match("^{[^}]*\\b[01]") then
	    text=text:gsub("\\b([01])",function (a) return "\\b"..(1-a) end )
	    else
	    if text:match("\\b([01])") then bolt=text:match("\\b([01])") else bolt="1" end
	    text=text:gsub("\\b([01])",function (a) return "\\b"..(1-a) end )
	    text=text:gsub("^({\\[^}]*)}","%1\\b"..bolt.."}")
	    end
	end
	-- italics
	if res["italix"] then
	    if text:match("^{[^}]*\\i[01]") then
	    text=text:gsub("\\i([01])",function (a) return "\\i"..(1-a) end )
	    else
	    if text:match("\\i([01])") then italix=text:match("\\i([01])") else italix="1" end
	    text=text:gsub("\\i([01])",function (a) return "\\i"..(1-a) end )
	    text=text:gsub("^({\\[^}]*)}","%1\\i"..italix.."}")
	    end
	end
	-- \fad
	if res.fade then
	    IN=res.fadin OUT=res.fadout GO=1
	    if res.glo then
		if z<#sel then OUT=0 end
		if z>1 then IN=0 end
		if IN==0 and OUT==0 then GO=0 end
	    end
	    text=text:gsub("\\fad%([%d%.%,]-%)","")
	    if GO==1 then text=text:gsub("^{\\","{\\fad("..IN..","..OUT..")\\") end
	end
	-- \q2
	if res["q2"] then
	    if text:match("^{[^}]-\\q2") then
	    text=text:gsub("\\q2","") 
	    else
	    text=text:gsub("^{\\","{\\q2\\") 
	    end
	end
	-- \an
	if res["an1"] then
	    if text:match("^{[^}]-\\an%d") then
	    text=text:gsub("^({[^}]-\\an)(%d)","%1"..res["an2"]) 
	    else
	    text=text:gsub("^{(\\)","{\\an"..res["an2"].."%1") 
	    end
	end
	-- raise layer
	if res["layer"] then
	if line.layer+res["layers"]<0 then aegisub.dialog.display({{class="label",
		    label="Layers can't be negative.",x=0,y=0,width=1,height=2}},{"OK"}) else
	line.layer=line.layer+res["layers"] end
	end
	
	-- put transform back
	if trnsfrm~=nil then text=text:gsub("^({\\[^}]*)}","%1"..trnsfrm.."}") trnsfrm=nil end
	
    end
    -- the end
	
    text=text:gsub("\\hydra","")	:gsub("{}","")
    line.text=text
    subs[i]=line
    end
end

function getcolours()
col={} alfalfa={}
    for c=1,4 do
    colur=res["c"..c]:gsub("#(%x%x)(%x%x)(%x%x).*","&H%3%2%1&")
    table.insert(col,colur)
      if res.alfas then
      alpa=res["c"..c]:match("#%x%x%x%x%x%x(%x%x)")
	if alpa~=nil then
          table.insert(alfalfa,alpa)
          if res["k"..c] then res["arf"..c]=true res["alph"..c]=alfalfa[c] end
	end
      end
      if res.aonly then res["k"..c]=false end
    end
end

function gettags(tags)
	if res["shad1"] then tags=tags.."\\shad"..res["shad2"] end
	if res["bord1"] then tags=tags.."\\bord"..res["bord2"] end
	if res["blur1"] then tags=tags.."\\blur"..res["blur2"] end
	if res["be1"] then tags=tags.."\\be"..res["be2"] end
	if res["fs1"] then tags=tags.."\\fs"..res["fs2"] end
	if res["spac1"] then tags=tags.."\\fsp"..res["spac2"] end
	if res["fscx1"] then tags=tags.."\\fscx"..res["fscx2"] end
	if res["fscy1"] then tags=tags.."\\fscy"..res["fscy2"] end
	if res["xbord1"] then tags=tags.."\\xbord"..res["xbord2"] end
	if res["ybord1"] then tags=tags.."\\ybord"..res["ybord2"] end
	if res["xshad1"] then tags=tags.."\\xshad"..res["xshad2"] end
	if res["yshad1"] then tags=tags.."\\yshad"..res["yshad2"] end
	if res["frz1"] then tags=tags.."\\frz"..res["frz2"] end
	if res["frx1"] then tags=tags.."\\frx"..res["frx2"] end
	if res["fry1"] then tags=tags.."\\fry"..res["fry2"] end
	if res["fax1"] then tags=tags.."\\fax"..res["fax2"] end
	if res["fay1"] then tags=tags.."\\fay"..res["fay2"] end
	if res["k1"] then tags=tags.."\\c"..col[1] end
	if res["k2"] then tags=tags.."\\2c"..col[2] end
	if res["k3"] then tags=tags.."\\3c"..col[3] end
	if res["k4"] then tags=tags.."\\4c"..col[4] end
	if res["arfa"] then tags=tags.."\\alpha&H"..res["alpha"].."&" end
	if res["arf1"] then tags=tags.."\\1a&H"..res["alph1"].."&" end
	if res["arf2"] then tags=tags.."\\2a&H"..res["alph2"].."&" end
	if res["arf3"] then tags=tags.."\\3a&H"..res["alph3"].."&" end
	if res["arf4"] then tags=tags.."\\4a&H"..res["alph4"].."&" end
	if res["moretags"]~="\\" and res["moretags"]~=nil then tags=tags..res["moretags"] end
	return tags
end

function special(subs, sel)
  if res.spec=="back and forth transform" then
    styleget(subs)
    getcolours()
    transphorm=""
    transphorm=gettags(transphorm)
  end
  if res.spec=="select overlaps" then
    sel=selover(subs)
  else
    for i=#sel,1,-1 do
        aegisub.progress.title(string.format(res.spec..": %d/%d",#sel-i,#sel))
	prog=math.floor((#sel-i+0.5)/#sel*100)
 	aegisub.progress.set(prog)
	local line=subs[sel[i]]
        local text=subs[sel[i]].text
	local layer=line.layer
	text=text:gsub("\\1c","\\c")
	
	if text:match("\\fscx") and text:match("\\fscy") then
	scalx=text:match("\\fscx([%d%.]+)")
	scaly=text:match("\\fscy([%d%.]+)")
	  if res.spec=="fscx -> fscy" then text=text:gsub("\\fscy[%d%.]+","\\fscy"..scalx) end
	  if res.spec=="fscy -> fscx" then text=text:gsub("\\fscx[%d%.]+","\\fscx"..scaly) end
	end
	
	if res.spec=="move colour tag to first block" then
	    tags=text:match("^{\\[^}]-}") if tags==nil then tags="" end
	    text=text:gsub("^{\\[^}]-}","")
	    klrs=""
	    for klr in text:gmatch("\\[1234]?c&H%x+&") do
		klrs=klrs..klr
		klrs=duplikill(klrs)
	    end
	    text=text:gsub("(\\[1234]?c&H%x+&)","") :gsub("{}","") 
	    text=tags.."{"..klrs.."}"..text
	    text=text:gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}")
	    text=text:gsub("({%*?\\[^}]-})",function(tg) return duplikill(tg) end)
	end
	
	if res.spec=="convert clip <-> iclip" then
	if text:match("\\clip") then text=text:gsub("\\clip","\\iclip")
	elseif text:match("\\iclip") then text=text:gsub("\\iclip","\\clip") end
	end
	
	-- CLEAN UP TAGS
	if res.spec=="clean up tags" then
  	    text=text:gsub("\\\\","\\")
	    text=text:gsub("\\}","}")
	    text=text:gsub("(%.%d%d)%d+","%1")
	    text=text:gsub("(%.%d)0","%1")
	    text=text:gsub("%.0([^%d])","%1")
		repeat
		text=text:gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}")
		until text:match("{(\\[^}]-)}{(\\[^}]-)}")==nil
	    text=text:gsub("^{(\\[^}]-)\\frx0\\fry0([\\}])","{%1%2")
	    text=text:gsub("({%*?\\[^}]-})",function(tg) return duplikill(tg) end)
	end
	
	-- SORT TAGS
	if res.spec=="sort tags in set order" then
	  text=text:gsub("\\a6","\\an8")
	  text=text:gsub("\\1c","\\c")
	  -- run for each set of tags
	  for tags in text:gmatch("{\\[^}]-}") do
	  orig=tags
	  ordered=""
	  tags=tags:gsub("{.-\\r","{\\r")	-- delete shit before \r in case some idiot puts it there
		-- save & nuke transforms
		trnsfrm=""
		for t in tags:gmatch("(\\t%([^%(%)]-%))") do trnsfrm=trnsfrm..t end
		for t in tags:gmatch("(\\t%([^%(%)]-%([^%)]-%)[^%)]-%))") do trnsfrm=trnsfrm..t end
		tags=tags:gsub("(\\t%([^%(%)]+%))","")
		tags=tags:gsub("(\\t%([^%(%)]-%([^%)]-%)[^%)]-%))","")
	    -- go through tags, save them in ordered, and delete from tags
	    for tg in order:gmatch("\\[%a%d]+") do
		tag=tags:match("("..tg.."[^\\}]-)[\\}]")
		if tg=="\\fs" then tag=tags:match("(\\fs%d[^\\}]-)[\\}]") end
		if tg=="\\fad" then tag=tags:match("(\\fad%([^\\}]-)[\\}]") end
		if tg=="\\c" then tag=tags:match("(\\c&[^\\}]-)[\\}]") end
		if tg=="\\i" then tag=tags:match("(\\i[^%a\\}]-)[\\}]") end
		if tg=="\\s" then tag=tags:match("(\\s[^%a\\}]-)[\\}]") end
		if tg=="\\p" then tag=tags:match("(\\p[^%a\\}]-)[\\}]") end
		if tag~=nil then ordered=ordered..tag etag=esc(tag) tags=tags:gsub(etag,"") end
	    end
	    -- attach whatever got left
	    if tags~="{}" then remains=tags:match("{(.-)}") ordered=ordered..remains end
	    -- put saved transforms at the end of ordered + add { }
	    ordered="{"..ordered..trnsfrm.."}"
	    orig=esc(orig)
	    text=text:gsub(orig,ordered)
	  end
	end
	
	-- CLEAN / SORT TRANSFORMS
	if res.spec=="clean up and sort transforms" then
	text=text:gsub("^({\\[^}]-})",function(tg) return cleantr(tg) end)
	end
	
	-- CLIP TO DRAWING
	if res.spec=="convert clip to drawing" then
	  if not text:match("\\clip") then aegisub.cancel() end
	  text=text:gsub("^({\\[^}]-}).*","%1")
	  text=text:gsub("^({[^}]*)\\clip%(m(.-)%)([^}]*)}","%1%3\\p1}m%2")
	  if text:match("\\pos") then
	    local xx,yy=text:match("\\pos%(([%d%.%-]+),([%d%.%-]+)%)")
	    xx=round(xx) yy=round(yy)
	    ctext=text:match("}m ([%d%a%s%-]+)")
	    ctext2=ctext:gsub("([%d%-]+)%s([%d%-]+)",function(a,b) return a-xx.." "..b-yy end)
	    ctext=ctext:gsub("%-","%%-")
	    text=text:gsub(ctext,ctext2)
	  end
	  if not text:match("\\pos") then text=text:gsub("^{","{\\pos(0,0)") end
	  if text:match("\\an") then text=text:gsub("\\an%d","\\an7") else text=text:gsub("^{","{\\an7") end
	  if text:match("\\fscx") then text=text:gsub("\\fscx[%d%.]+","\\fscx100") else text=text:gsub("\\p1","\\fscx100\\p1") end
	  if text:match("\\fscy") then text=text:gsub("\\fscy[%d%.]+","\\fscy100") else text=text:gsub("\\p1","\\fscy100\\p1") end
	end
	
	-- DRAWING TO CLIP
	if res.spec=="convert drawing to clip" then
	  if not text:match("\\p1") then aegisub.cancel() end
	  --text=text:gsub("^({\\[^}]-}).*","%1")
	  text=text:gsub("^({[^}]*)\\p1([^}]-})(m [^{]*)","%1\\clip(%3)%2")
	  scx=text:match("\\fscx([%d%.]+)")	if scx==nil then scx=100 end
	  scy=text:match("\\fscy([%d%.]+)")	if scy==nil then scy=100 end
	  --aegisub.log("\n text "..text)
	  if text:match("\\pos") then
	    local xx,yy=text:match("\\pos%(([%d%.%-]+),([%d%.%-]+)%)")
	    xx=round(xx) yy=round(yy)
	    ctext=text:match("\\clip%(m ([^%)]+)%)")
	    ctext2=ctext:gsub("([%d%-]+)%s([%d%-]+)",function(a,b) return round(a*scx/100+xx).." "..round(b*scy/100+yy) end)
	    ctext=ctext:gsub("%-","%%-")
	    text=text:gsub(ctext,ctext2)
	  end
	  if not text:match("\\pos") then text=text:gsub("^{","{\\pos(0,0)") end
	end
	
	-- 3D SHADOW
	if res.spec=="create 3D effect from shadow" then
	  xshad=text:match("^{[^}]-\\xshad([%d%.%-]+)")	if xshad==nil then xshad=0 end 	ax=math.abs(xshad)
	  yshad=text:match("^{[^}]-\\yshad([%d%.%-]+)")	if yshad==nil then yshad=0 end 	ay=math.abs(yshad)
	  if ax>ay then lay=math.floor(ax) else lay=math.floor(ay) end
	
	  text2=text:gsub("^({\\[^}]-)}","%1\\3a&HFF&}")	:gsub("\\3a&H%x%x&([^}]-)(\\3a&H%x%x&)","%1%2")
	
	  for l=lay,1,-1 do
	    line2=line	    f=l/lay
	    txt=text2	    if l==1 then txt=text end
	    line2.text=txt
	    :gsub("\\xshad([%d%.%-]+)",function(a) xx=tostring(f*a) xx=xx:gsub("([%d%-]+%.%d%d)%d+","%1") return "\\xshad"..xx end)
	    :gsub("\\yshad([%d%.%-]+)",function(a) yy=tostring(f*a) yy=yy:gsub("([%d%-]+%.%d%d)%d+","%1") return "\\yshad"..yy end)
	    line2.layer=layer+(lay-l)
	    subs.insert(sel[i]+1,line2)
	  end

	  if not xshad==0 and not yshad==0 then subs.delete(sel[i]) end
	end
	
	-- CLIP GRIDS
	if res.spec=="clip square grid small" then
	    text=text:gsub("^({[^}]-)\\clip%([^%)]+%)","%1")
	    text=text:gsub("^({\\[^}]-)}","%1\\clip(m 520 280 l 760 280 l 760 300 l 520 300 l 520 320 l 760 320 l 760 340 l 520 340 l 520 360 l 760 360 l 760 380 l 520 380 l 520 400 l 760 400 l 760 420 l 520 420 l 520 440 l 760 440 l 760 460 l 740 460 l 740 260 l 720 260 l 720 460 l 700 460 l 700 260 l 680 260 l 680 460 l 659 460 l 660 260 l 640 260 l 640 460 l 620 460 l 620 260 l 600 260 l 600 460 l 580 460 l 580 260 l 560 260 l 560 460 l 540 460 l 540 260 l 520 260)}")
	end
	if res.spec=="clip square grid large" then
	    text=text:gsub("^({[^}]-)\\clip%([^%)]+%)","%1")
	    text=text:gsub("^({\\[^}]-)}","%1\\clip(m 400 200 l 880 200 l 880 240 l 400 240 l 400 280 l 880 280 l 880 320 l 400 320 l 400 360 l 880 360 l 880 400 l 400 400 l 400 440 l 880 440 l 880 480 l 400 480 l 400 520 l 880 520 l 880 560 l 840 560 l 840 160 l 800 160 l 800 560 l 760 560 l 760 160 l 720 160 l 720 560 l 678 560 l 680 160 l 640 160 l 640 560 l 600 560 l 600 160 l 560 160 l 560 560 l 520 560 l 520 160 l 480 160 l 480 560 l 440 560 l 440 160 l 400 160)}")
	end
	
	-- BACK AND FORTH TRANSFORM
	if res.spec=="back and forth transform" and res.int>0 then
	    if defaref~=nil and line.style=="Default" then styleref=defaref
	    else styleref=stylechk(line.style) end
	    -- clean up existing transforms
		if text:match("^{[^}]*\\t") then
		text=text:gsub("^({\\[^}]-})",function(tg) return cleantr(tg) end)
		end
	    startags=text:match("^{\\[^}]-}")
	    bordr=startags:match("\\bord([%d%.]+)")
	    shadw=startags:match("\\shad([%d%.]+)")
	    tags1=""
	    for tg in transphorm:gmatch("\\[1234]?%a+") do
	      val1=nil
	      if not startags:match(tg.."[%d%-&%(]") then
		if tg=="\\bord" then val1=styleref.outline end
		if tg=="\\shad" then val1=styleref.shadow end
		if tg=="\\xbord" or tg=="\\ybord" then if bordr~=nil then val1=bordr else val1=styleref.outline end end
		if tg=="\\xshad" or tg=="\\yshad" then if shadw~=nil then val1=bordr else val1=styleref.shadow end end
		if tg=="\\fs" then val1=styleref.fontsize end
		if tg=="\\fsp" then val1=styleref.spacing end
		if tg=="\\frz" then val1=styleref.angle end
		if tg=="\\fscx" then val1=styleref.scale_x end
		if tg=="\\fscy" then val1=styleref.scale_y end
		if tg=="\\blur" or tg=="\\be" or tg=="\\fax" or tg=="\\fay" or tg=="\\frx" or tg=="\\fry" then val1=0 end
		if tg=="\\c" then val1=styleref.color1:gsub("H%x%x","H") end
		if tg=="\\2c" then val1=styleref.color2:gsub("H%x%x","H") end
		if tg=="\\3c" then val1=styleref.color3:gsub("H%x%x","H") end
		if tg=="\\4c" then val1=styleref.color4:gsub("H%x%x","H") end
		if tg=="\\1a" then val1=styleref.color1:gsub("(H%x%x)%x%x%x%x%x%x","%1") end
		if tg=="\\2a" then val1=styleref.color2:gsub("(H%x%x)%x%x%x%x%x%x","%1") end
		if tg=="\\3a" then val1=styleref.color3:gsub("(H%x%x)%x%x%x%x%x%x","%1") end
		if tg=="\\4a" then val1=styleref.color4:gsub("(H%x%x)%x%x%x%x%x%x","%1") end
		if tg=="\\alpha" then val1="&H00&" end
		if tg=="\\clip" then val1="(0,0,1280,720)" end
		if val1~=nil then tags1=tags1..tg..val1
		text=text:gsub("^({\\[^}]-)}","%1"..tg..val1.."}") end
	      else
	      val1=startags:match(tg.."([^\\}]+)")
	      tags1=tags1..tg..val1
	      end
	    end
	    int=res.int
	    tags2=transphorm
	    dur=line.end_time-line.start_time
	    count=math.ceil(dur/int)
	    t=1		tin=0		tout=tin+int
	    if text:match("^{\\")==nil then text="{\\}"..text end	-- add {\} if line has no tags
	    -- main function
	    while t<=math.ceil(count/2) do
		text=text:gsub("^({\\[^}]*)}","%1\\t("..tin..","..tout..","..tags2..")}")
		if tin+int<dur then
		text=text:gsub("^({\\[^}]*)}","%1\\t("..tin+int..","..tout+int..","..tags1..")}")	end
		tin=tin+int+int
		tout=tin+int
		t=t+1	    
	    end
	    text=text:gsub("\\\\","\\")	:gsub("\\}","}")
	end
	
	-- SPLIT LINE IN 3 PARTS
	if res.spec=="split line in 3 parts" then
		start=line.start_time		-- start time
		endt=line.end_time		-- end time
		effect=line.effect
	-- line 3
		line3=line
		line3.start_time=endt-res.trout
		line3.effect=effect.." pt.3"
		if line3.start_time~=line3.end_time then
		subs.insert(sel[i]+1,line3) end
	-- line 2
		line2=line
		line2.start_time=start+res.trin
		line2.end_time=endt-res.trout
		line2.effect=effect.." pt.2"
		subs.insert(sel[i]+1,line2)
	-- line 1
		line.start_time=start
		line.end_time=start+res.trin
		line.effect=effect.." pt.1"
	end
	
	if res.spec~="create 3D effect from shadow" then
	line.text=text	subs[sel[i]]=line
	if res.spec=="split line in 3 parts" and line.start_time==line.end_time then subs.delete(sel[i]) end
	end
    end
  end
  return sel
end

function selover(subs,sel)
  local dialogue={ }
  for i, line in ipairs(subs) do
    if line.class=="dialogue" then line.i=i
      table.insert(dialogue, line)
    end
  end
  table.sort(dialogue, function(a, b)
    return a.start_time < b.start_time or (a.start_time == b.start_time and a.i < b.i)
  end)
  local end_time=0
  local overlaps={ }
  for i=1, #dialogue do
    local line=dialogue[i]
    if line.start_time >= end_time then
      end_time=line.end_time
    else
      table.insert(overlaps, line.i)
    end
  end
  sel=overlaps
  return sel
end

function round(num)
	if num-math.floor(num)>=0.5 then num=math.ceil(num) else num=math.floor(num) end
	return num
end

function trem(tags)
	trnsfrm=""
	for t in tags:gmatch("(\\t%([^%(%)]-%))") do trnsfrm=trnsfrm..t end
	for t in tags:gmatch("(\\t%([^%(%)]-%([^%)]-%)[^%)]-%))") do trnsfrm=trnsfrm..t end
	tags=tags:gsub("(\\t%([^%(%)]+%))","")
	tags=tags:gsub("(\\t%([^%(%)]-%([^%)]-%)[^%)]-%))","")
	return tags
end

function cleantr(tags)
	trnsfrm=""
	for t in tags:gmatch("(\\t%([^%(%)]-%))") do trnsfrm=trnsfrm..t end
	for t in tags:gmatch("(\\t%([^%(%)]-%([^%)]-%)[^%)]-%))") do trnsfrm=trnsfrm..t end
	tags=tags:gsub("(\\t%([^%(%)]+%))","")
	tags=tags:gsub("(\\t%([^%(%)]-%([^%)]-%)[^%)]-%))","")
	tags=tags:gsub("^({\\[^}]*)}","%1"..trnsfrm.."}")

	cleant=""
	for ct in tags:gmatch("\\t%((\\[^%(%)]-)%)") do cleant=cleant..ct end
	for ct in tags:gmatch("\\t%((\\[^%(%)]-%([^%)]-%)[^%)]-)%)") do cleant=cleant..ct end
	tags=tags:gsub("(\\t%(\\[^%(%)]+%))","")
	tags=tags:gsub("(\\t%(\\[^%(%)]-%([^%)]-%)[^%)]-%))","")
	if cleant~="" then tags=tags:gsub("^({\\[^}]*)}","%1\\t("..cleant..")}") end
	tags=tags:gsub("(\\clip%([^%)]+%))([^%(%)]-)(\\c&H%x+&)","%2%3%1")
	return tags
end

function duplikill(tagz)
	tf=""
	if tagz:match("\\t") then 
	    for t in tagz:gmatch("(\\t%([^%(%)]-%))") do tf=tf..t end
	    for t in tagz:gmatch("(\\t%([^%(%)]-%([^%)]-%)[^%)]-%))","") do tf=tf..t end
	    tagz=tagz:gsub("\\t%([^%(%)]+%)","")
	    tagz=tagz:gsub("\\t%([^%(%)]-%([^%)]-%)[^%)]-%)","")
	end
	tags1={"blur","be","bord","shad","xbord","xshad","ybord","yshad","fs","fsp","fscx","fscy","frz","frx","fry","fax","fay"}
	for i=1,#tags1 do
	    tag=tags1[i]
	    tagz=tagz:gsub("\\"..tag.."[%d%.%-]+([^}]-)(\\"..tag.."[%d%.%-]+)","%2%1")
	end
	tagz=tagz:gsub("\\1c&","\\c&")
	tags2={"c","2c","3c","4c","1a","2a","3a","4a","alpha"}
	for i=1,#tags2 do
	    tag=tags2[i]
	    tagz=tagz:gsub("\\"..tag.."&H%x+&([^}]-)(\\"..tag.."&H%x+&)","%2%1")
	end
	tagz=tagz:gsub("({\\[^}]-)}","%1"..tf.."}")
	return tagz
end

function textmod(orig,text)
    tk={}
    tg={}
	text=text:gsub("{\\\\k0}","")
	repeat text=text:gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}")
	    until not text:match("{(\\[^}]-)}{(\\[^}]-)}")
	vis=text:gsub("{[^}]-}","")
	ltrmatches=re.find(vis,".")
	  for l=1,#ltrmatches do
	    table.insert(tk,ltrmatches[l].str)
	  end
	stags=text:match("^{(\\[^}]-)}")
	if stags==nil then stags="" end
	text=text:gsub("^{\\[^}]-}","") :gsub("{[^\\}]-}","")
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
	for n, t in ipairs(tg) do
	    if t.p==i then newt=newt..t.a..t.t end
	end
	if newt~="" then newline=newline.."{"..as..newt.."}" end
    end
    newtext="{"..stags.."}"..newline
    text=newtext
    return text
end

function esc(str)
str=str
:gsub("%%","%%%%")
:gsub("%(","%%%(")
:gsub("%)","%%%)")
:gsub("%[","%%%[")
:gsub("%]","%%%]")
:gsub("%.","%%%.")
:gsub("%*","%%%*")
:gsub("%-","%%%-")
:gsub("%+","%%%+")
:gsub("%?","%%%?")
return str
end

function styleget(subs)
    styles={}
    for i=1,#subs do
        if subs[i].class=="style" then
	    table.insert(styles,subs[i])
	end
	if subs[i].class=="dialogue" then break end
    end
end

function stylechk(stylename)
    for i=1,#styles do
	if stylename==styles[i].name then
	    styleref=styles[i]
	    if styles[i].name=="Default" then defaref=styles[i] end
	    break
	end
    end
    return styleref
end

hydraulics={"A multi-headed typesetting tool","Nine heads typeset better than one.","Eliminating the typing part of typesetting","Mass-production of typesetting tags","Hydraulic typesetting machinery","Making sure your subtitles aren't dehydrated","Making typesetting so easy that even you can do it!","A monstrous typesetting tool","A deadly typesetting beast","Building monstrous scripts with ease","For irrational typesetting wizardry","Building a Wall of Tags"}

function konfig(subs, sel)
app_lay={"All Layers"}
app_sty={"All Styles"}
app_act={"All Actors"}
app_eff={"All Effects"}
for x,i in ipairs(sel) do
    layr=subs[i].layer
    stl=subs[i].style
    akt=subs[i].actor
    eph=subs[i].effect
    asdf=0
    for a=1,#app_lay do if layr==app_lay[a] then asdf=1 end end
    if asdf==0 then table.insert(app_lay,layr) end
    asdf=0
    for a=1,#app_sty do if stl==app_sty[a] then asdf=1 end end
    if asdf==0 then table.insert(app_sty,stl) end
    asdf=0
    for a=1,#app_act do if akt==app_act[a] then asdf=1 end end
    if asdf==0 then table.insert(app_act,akt) end
    asdf=0
    for a=1,#app_eff do if eph==app_eff[a] then asdf=1 end end
    if asdf==0 then table.insert(app_eff,eph) end
end
sm=startup_mode
heads=sm*2+1
aegisub.progress.title(string.format("Loading Hydra Heads 1-"..heads))
hr=math.random(1,#hydraulics)
oneline=subs[sel[1]]
linetext=oneline.text:gsub("{[^}]-}","")
hh1=
{
    {x=0,y=0,width=5,height=1,class="label",label=hydraulics[hr], },
    {x=6,y=0,width=2,height=1,class="label",label="HYDRA version "..script_version },
    
    {x=0,y=1,width=1,height=1,class="checkbox",name="k1",label="Primary:",value=false },
    {x=0,y=2,width=1,height=1,class="checkbox",name="k3",label="Border:",value=false },
    {x=0,y=3,width=1,height=1,class="checkbox",name="k4",label="Shadow:",value=false },
    {x=0,y=4,width=1,height=1,class="checkbox",name="k2",label="useless... (2c):",value=false },
    {x=0,y=5,width=1,height=1,class="checkbox",name="alfas",label="Include alphas",value=false,
	hint="Include alphas from colours pickers.\nRequires Aegisub r7993 or higher." },
    {x=1,y=5,width=1,height=1,class="checkbox",name="aonly",label="only",value=false,hint="Use only alphas, not colours" },
    {x=0,y=6,width=1,height=1,class="checkbox",name="italix",label="Italics",value=false },
    {x=1,y=6,width=1,height=1,class="checkbox",name="bolt",label="Bold",value=false },
    
    {x=1,y=1,width=1,height=1,class="coloralpha",name="c1" },
    {x=1,y=2,width=1,height=1,class="coloralpha",name="c3" },
    {x=1,y=3,width=1,height=1,class="coloralpha",name="c4" },
    {x=1,y=4,width=1,height=1,class="coloralpha",name="c2" },
    
    {x=2,y=1,width=1,height=1,class="checkbox",name="bord1",label="\\bord",value=false },
    {x=2,y=2,width=1,height=1,class="checkbox",name="shad1",label="\\shad",value=false },
    {x=2,y=3,width=1,height=1,class="checkbox",name="fs1",label="\\fs",value=false },
    {x=2,y=4,width=1,height=1,class="checkbox",name="spac1",label="\\fsp",value=false },
    {x=2,y=5,width=1,height=1,class="checkbox",name="blur1",label="\\blur",value=false },
    {x=2,y=6,width=1,height=1,class="checkbox",name="be1",label="\\be",value=false },
    
    {x=3,y=1,width=2,height=1,class="floatedit",name="bord2",value=default_border,min=0 },
    {x=3,y=2,width=2,height=1,class="floatedit",name="shad2",value=default_shadow,min=0 },
    {x=3,y=3,width=2,height=1,class="floatedit",name="fs2",value=default_fontsize,min=1 },
    {x=3,y=4,width=2,height=1,class="floatedit",name="spac2",value=default_spacing },
    {x=3,y=5,width=2,height=1,class="floatedit",name="blur2",value=default_blur,min=0 },
    {x=3,y=6,width=2,height=1,class="floatedit",name="be2",value=1,min=0 },
    
    {x=5,y=1,width=1,height=1,class="checkbox",name="xbord1",label="\\xbord",value=false },
    {x=5,y=2,width=1,height=1,class="checkbox",name="ybord1",label="\\ybord",value=false },
    {x=5,y=3,width=1,height=1,class="checkbox",name="xshad1",label="\\xshad",value=false },
    {x=5,y=4,width=1,height=1,class="checkbox",name="yshad1",label="\\yshad",value=false },
    {x=5,y=5,width=1,height=1,class="checkbox",name="fax1",label="\\fax",value=false },
    {x=5,y=6,width=1,height=1,class="checkbox",name="fay1",label="\\fay",value=false },
    
    {x=6,y=1,width=2,height=1,class="floatedit",name="xbord2",value="",min=0 },
    {x=6,y=2,width=2,height=1,class="floatedit",name="ybord2",value="",min=0 },
    {x=6,y=3,width=2,height=1,class="floatedit",name="xshad2",value="" },
    {x=6,y=4,width=2,height=1,class="floatedit",name="yshad2",value="" },
    {x=6,y=5,width=2,height=1,class="floatedit",name="fax2",value=default_fax },
    {x=6,y=6,width=2,height=1,class="floatedit",name="fay2",value=default_fay },
}
    
hh2={
    {x=8,y=0,width=2,height=1,class="label",name="info",label="Selected lines: "..#sel },
    {x=8,y=1,width=1,height=1,class="checkbox",name="layer",label="layer",value=false},
    {x=8,y=2,width=1,height=1,class="checkbox",name="arfa",label="\\alpha",value=false },
    {x=8,y=3,width=1,height=1,class="checkbox",name="arf1",label="\\1a",value=false },
    {x=8,y=4,width=1,height=1,class="checkbox",name="arf2",label="\\2a",value=false },
    {x=8,y=5,width=1,height=1,class="checkbox",name="arf3",label="\\3a",value=false },
    {x=8,y=6,width=1,height=1,class="checkbox",name="arf4",label="\\4a",value=false },
    
    {x=9,y=1,width=1,height=1,class="dropdown",name="layers",
	items={"-5","-4","-3","-2","-1","+1","+2","+3","+4","+5"},value="+1" },
    {x=9,y=2,width=1,height=1,class="dropdown",name="alpha",
	items={"00","10","20","30","40","50","60","70","80","90","A0","B0","C0","D0","E0","F0","F8","FF"},value="00" },
    {x=9,y=3,width=1,height=1,class="dropdown",name="alph1",
	items={"00","10","20","30","40","50","60","70","80","90","A0","B0","C0","D0","E0","F0","FF"},value="00" },
    {x=9,y=4,width=1,height=1,class="dropdown",name="alph2",
	items={"00","10","20","30","40","50","60","70","80","90","A0","B0","C0","D0","E0","F0","FF"},value="00" },
    {x=9,y=5,width=1,height=1,class="dropdown",name="alph3",
	items={"00","10","20","30","40","50","60","70","80","90","A0","B0","C0","D0","E0","F0","FF"},value="00" },
    {x=9,y=6,width=1,height=1,class="dropdown",name="alph4",
	items={"00","10","20","30","40","50","60","70","80","90","A0","B0","C0","D0","E0","F0","FF"},value="00" },
    {x=0,y=7,width=1,height=1,class="checkbox",name="an1",label="\\an",value=false },
    {x=1,y=7,width=1,height=1,class="dropdown",name="an2",items={"1","2","3","4","5","6","7","8","9"},value="5"},
    {x=2,y=7,width=1,height=1,class="checkbox",name="fade",label="\\fad",value=false },
    {x=3,y=7,width=2,height=1,class="floatedit",name="fadin",min=0 },
    {x=5,y=7,width=1,height=1,class="label",label="<- in,out ->", },
    {x=6,y=7,width=2,height=1,class="floatedit",name="fadout",min=0 },
    {x=8,y=7,width=1,height=1,class="checkbox",name="glo",label="global",value=false,hint="global fade - IN on first line, OUT on last line" },
    {x=9,y=7,width=1,height=1,class="checkbox",name="q2",label="\\q2",value=false },
    
    {x=0,y=8,width=1,height=1,class="label",label="Additional tags:"},
    {x=1,y=8,width=4,height=1,class="edit",name="moretags",value="\\" },
}

hh3={
    {x=0,y=9,width=1,height=1,class="label",label="Transform mode:"},
    {x=1,y=9,width=2,height=1,class="dropdown",name="tmode",items={"normal","add2first","add2all"},value="normal",hint="new \\t  |  add to first \\t  |  add to all \\t"},
    {x=3,y=9,width=2,height=1,class="checkbox",name="tend",label="times from end",value=false,hint="Count times from end"},
    {x=0,y=10,width=1,height=1,class="label",label="Transform t1,t2:"},
    {x=1,y=10,width=2,height=1,class="floatedit",name="trin" },
    {x=3,y=10,width=2,height=1,class="floatedit",name="trout" },
    {x=0,y=11,width=1,height=1,class="label",label="Acceleration:"},
    {x=1,y=11,width=2,height=1,class="floatedit",name="accel",value=1 },
    {x=3,y=11,width=2,height=1,class="floatedit",name="int",value=500,hint="interval for 'back and forth transform'"},
    {x=4,y=12,width=1,height=1,class="label",label="^inetrval"},
    
    {x=5,y=8,width=1,height=1,class="checkbox",name="frz1",label="\\frz",value=false },
    {x=5,y=9,width=1,height=1,class="checkbox",name="frx1",label="\\frx",value=false },
    {x=5,y=10,width=1,height=1,class="checkbox",name="fry1",label="\\fry",value=false },
    {x=5,y=11,width=1,height=1,class="checkbox",name="fscx1",label="\\fscx",value=false },
    {x=5,y=12,width=1,height=1,class="checkbox",name="fscy1",label="\\fscy",value=false },
    
    {x=6,y=8,width=2,height=1,class="floatedit",name="frz2",value="" },
    {x=6,y=9,width=2,height=1,class="floatedit",name="frx2",value="" },
    {x=6,y=10,width=2,height=1,class="floatedit",name="fry2",value="" },
    {x=6,y=11,width=2,height=1,class="floatedit",name="fscx2",value=100,min=0 },
    {x=6,y=12,width=2,height=1,class="floatedit",name="fscy2",value=100,min=0 },

    {x=0,y=12,width=1,height=1,class="label",label="Special functions:"},
    {x=1,y=12,width=3,height=1,class="dropdown",name="spec",items={"fscx -> fscy","fscy -> fscx","move colour tag to first block","convert clip <-> iclip","clean up tags","sort tags in set order","clean up and sort transforms","back and forth transform","select overlaps","convert clip to drawing","convert drawing to clip","clip square grid small","clip square grid large","create 3D effect from shadow","split line in 3 parts"},value="convert clip <-> iclip"},
    
    {x=0,y=13,width=1,height=1,class="label",label="Tag position*:"},
    {x=1,y=13,width=5,height=1,class="edit",name="linetext",value=linetext,hint="Place asterisk where you want the tags"},
    {x=6,y=13,width=2,height=1,class="dropdown",name="tagpres",items={"--- presets ---","before last char.","in the middle","1/4 of text","3/4 of text","1/8 of text","3/8 of text","5/8 of text","7/8 of text","custom pattern"},value="--- presets ---"},
    
    {x=8,y=9,width=2,height=1,class="label",label="Apply to:"},
    {x=8,y=10,width=2,height=1,class="dropdown",name="applay",items=app_lay,value="All Layers"},
    {x=8,y=11,width=2,height=1,class="dropdown",name="applst",items=app_sty,value="All Styles"},
    {x=8,y=12,width=2,height=1,class="dropdown",name="applac",items=app_act,value="All Actors"},
    {x=8,y=13,width=2,height=1,class="dropdown",name="applef",items=app_eff,value="All Effects"},
}

	buttons={{"Apply","Repeat Last","Load Medium","Load Full","Cancel"},
	{"Apply","Repeat Last","Load Full","Cancel"},{"Apply","Transform","Repeat Last","Special","Help","Cancel"}}
	hh_gui=hh1	loaded=sm
	if sm==2 then for i=1,#hh2 do l=hh2[i] table.insert(hh_gui,l) end loaded=2 end
	if sm==3 then for i=1,#hh2 do l=hh2[i] table.insert(hh_gui,l) end for i=1,#hh3 do l=hh3[i] table.insert(hh_gui,l) end end
	hh_buttons=buttons[sm]
	pressed,res=aegisub.dialog.display(hh_gui,hh_buttons,{ok='Apply',cancel='Cancel'})
	
	if pressed=="Load Medium" then aegisub.progress.title(string.format("Loading Heads 4-5"))
	    for key,val in ipairs(hh_gui) do val.value=res[val.name] end
	    for i=1,#hh2 do l=hh2[i] table.insert(hh_gui,l) end loaded=2
	    pressed,res=aegisub.dialog.display(hh_gui,buttons[2],{ok='Apply',cancel='Cancel'})
	end
	
	if pressed=="Load Full" then aegisub.progress.title(string.format("Loading Heads "..(loaded+1)*2 .."-7"))
	    for key,val in ipairs(hh_gui) do val.value=res[val.name] end
	    if loaded<2 then  for i=1,#hh2 do l=hh2[i] table.insert(hh_gui,l) end  end
	    for i=1,#hh3 do l=hh3[i] table.insert(hh_gui,l) end loaded=3
	    pressed,res=aegisub.dialog.display(hh_gui,buttons[3],{ok='Apply',cancel='Cancel'})
	end
	
	if pressed=="Help" then aegisub.progress.title(string.format("Loading Head 8"))
	for key,val in ipairs(hh_gui) do val.value=res[val.name] end
	hhh={x=0,y=14,width=10,height=1,class="dropdown",name="herp",items={"HELP (scroll/click to read)",
	"Standard mode: check tags, set values, click 'Apply'.",
	"Transform mode normal: check tags, set values, set t1/t2/accel if needed, click 'Transform'.",
	"Transform mode add2first: the transforms will be added to the first existing transform in the line.",
	"Transform mode add2all: the transforms will be added to all existing transforms in the line.",
	"Additional tags: type any extra tags you want to add.",
	"Tag position: This shows the text of your first line. Type * where you want your tags to go.",
	"Tag position presets: This places tags in specified positions, proportionally for each selected line.",
	"Special functions: select a function, click 'Special'.",
	"Special functions - back and forth transform: select tags, set interval (ms). Missing initial tags are taken from style.",
	"Special functions - create 3D effect from shadow: creates a 3D-effect using layers. Requires xshad/yshad.",
	"Special functions - split line in 3 parts: uses t1 and t2 as time markers.",
	},value="HELP (scroll/click to read)"}
	table.insert(hh_gui,hhh)
	pressed,res=aegisub.dialog.display(hh_gui,{"Apply","Transform","Repeat Last","Special","Cancel"},{ok='Apply',cancel='Cancel'})
	end
	
	if res.tmode=="normal" then tmode=1 end
	if res.tmode=="add2first" then tmode=2 end
	if res.tmode=="add2all" then tmode=3 end
	if res.tagpres=="in the middle" then fak=0.5 end 
	if res.tagpres=="1/4 of text" then fak=0.25 end
	if res.tagpres=="3/4 of text" then fak=0.75 end
	if res.tagpres=="1/8 of text" then fak=1/8 end
	if res.tagpres=="3/8 of text" then fak=3/8 end
	if res.tagpres=="5/8 of text" then fak=5/8 end
	if res.tagpres=="7/8 of text" then fak=7/8 end
	if res.aonly then res.alfas=true end
	
	if pressed=="Apply" then trans=0 hh9(subs, sel) end
	if pressed=="Transform" then trans=1 hh9(subs, sel) end
	if pressed=="Special" then sel=special(subs, sel) end
	
	if pressed~="Repeat Last" then
	    last_set={}
	    for key,val in ipairs(hh_gui) do
		if val.name==nil then name="" result="n/a" else
		local name=val.name
		result=res[name]
		if result==nil then result="n/a" end
		if result==true then result="true" end
		if result==false then result="false" end
		end
		table.insert(last_set,result)
	    end
	end
	if pressed=="Repeat Last" then
	    for key,val in ipairs(hh_gui) do
		local name=val.name
		if last_set[key]=="true" then res[name]=true
		elseif last_set[key]=="false" then res[name]=false
		elseif last_set[key]~="n/a" then res[name]=last_set[key]
		else
		end
	    end
	    hh9(subs, sel)
	end
	return sel
end

function hydra(subs, sel)
    checkonfig()
    sel=konfig(subs, sel)
    aegisub.set_undo_point(script_name)
    return sel
end

aegisub.register_macro(script_name, script_description, hydra)