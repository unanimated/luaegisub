script_name="Multi-line Editor"
script_description="Multi-line Editor"
script_author="unanimated"
script_version="1.32"

require "clipboard"

function editlines(subs, sel)
	editext=""
	dura=""
    for x, i in ipairs(sel) do
        local line=subs[i]
	local text=subs[i].text
	dur=line.end_time-line.start_time
	dur=dur/1000
	char=text:gsub("{[^}]-}","")	:gsub("\\[Nn]","*")	:gsub("%s?%*+%s?"," ")	:gsub(" ","")	:gsub("[%.,%?!'\"—]","")
	linelen=char:len()
	cps=math.ceil(linelen/dur)
	if tostring(dur):match("%.%d$") then dur=dur.."0" end
	if not tostring(dur):match("%.") then dur=dur..".00" end
	if cps<10 then cps="  "..cps end
	if dur=="0.00" then cps="n/a" end
	
	      if x~=#sel then editext=editext..text.."\n" dura=dura..dur.." .. "..cps.." .. "..linelen.."\n" end
	      if x==#sel then editext=editext..text dura=dura..dur.." .. "..cps.." .. "..linelen end
	subs[i]=line
    end
    editbox(subs, sel)
    if failt==1 then editext=res.dat editbox(subs, sel) end
    return sel
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

function editbox(subs, sel)
	if #sel<=4 then boxheight=6 end
	if #sel>=5 and #sel<9 then boxheight=8 end
	if #sel>=9 and #sel<15 then boxheight=math.ceil(#sel*0.8) end
	if #sel>=15 and #sel<18 then boxheight=12 end
	if #sel>=18 then boxheight=15 end
	nocom=editext:gsub("{[^}]-}","")
	words=0
	plaintxt=nocom:gsub("%p","")
	for wrd in plaintxt:gmatch("%w+") do
	words=words+1
	end
	if lastrep1==nil then lastrep1="" end
	if lastrep2==nil then lastrep2="" end
	dialog=
	{
	    {x=0,y=0,width=52,height=1,class="label",label="Text"},
	    {x=52,y=0,width=5,height=1,class="label",label="Duration | CPS | chars"},
	    
	    {x=0,y=boxheight+1,width=1,height=1,class="label",label="Replace:"},
	    {x=1,y=boxheight+1,width=15,height=1,class="edit",name="rep1",value=lastrep1},
	    {x=16,y=boxheight+1,width=1,height=1,class="label",label="with"},
	    {x=17,y=boxheight+1,width=15,height=1,class="edit",name="rep2",value=lastrep2},
	    
	    {x=0,y=1,width=52,height=boxheight,class="textbox",name="dat",value=editext},
	    {x=52,y=1,width=5,height=boxheight,class="textbox",name="durr",value=dura,hint="This is informative only. \nCPS=Characters Per Second"},
	    
	    {x=32,y=boxheight+1,width=20,height=1,class="edit",name="info",value="Lines loaded: "..#sel..", Characters: "..editext:len()..", Words: "..words },
	    {x=52,y=boxheight+1,width=5,height=1,class="label",label="Multi-Line Editor v"..script_version},
	}
	buttons={"Save","Replace","Remove tags","Rm. comments","Remove \"- \"","Remove \\N","Add italics","Add \\an8","Reload text","Cancel"}
	repeat
	if pressed=="Replace" or pressed=="Add italics" or pressed=="Add \\an8" or pressed=="Remove \\N" or pressed=="Reload text"
		or pressed=="Remove tags" or pressed=="Rm. comments" or pressed=="Remove \"- \"" then
		
		if pressed=="Add italics" then
		res.dat=res.dat	:gsub("$","\n") :gsub("(.-)\n","{\\i1}%1\n") :gsub("{\\i1}{\\","{\\i1\\") :gsub("\n$","") end
		if pressed=="Add \\an8" then
		res.dat=res.dat	:gsub("$","\n") :gsub("(.-)\n","{\\an8}%1\n") :gsub("{\\an8}{\\","{\\an8\\") :gsub("\n$","") end
		if pressed=="Remove \\N" then res.dat=res.dat	:gsub("%s?\\N%s?"," ") end
		if pressed=="Remove tags" then res.dat=res.dat:gsub("{\\[^}]-}","") end
		if pressed=="Rm. comments" then res.dat=res.dat:gsub("{[^\\}]-}","") :gsub("{[^\\}]-\\N[^\\}]-}","") end
		if pressed=="Remove \"- \"" then res.dat=res.dat:gsub("%- ","") end
		if pressed=="Replace" then rep1=esc(res.rep1)
		res.dat=res.dat:gsub(rep1,res.rep2)
		end
		
		for key,val in ipairs(dialog) do
		  if pressed~="Reload text" then
		    if val.name=="dat" then val.value=res.dat end
		    if val.name=="durr" then val.value=res.durr end
		    if val.name=="info" then val.value=res.info end
		    if val.name=="oneline" then val.value=res.oneline end
		    if val.name=="rep1" then val.value=res.rep1 end
		    if val.name=="rep2" then val.value=res.rep2 end
		  else
		    if val.name=="dat" then val.value=editext end
		  end
		end
	end
	pressed, res=aegisub.dialog.display(dialog,buttons,{save='Save',close='Cancel'})
	until pressed~="Add italics" and pressed~="Add \\an8" and pressed~="Remove \\N" and pressed~="Reload text" 
		and pressed~="Remove tags"and pressed~="Rm. comments" and pressed~="Remove \"- \"" and pressed~="Replace"

	if pressed=="Cancel" then aegisub.cancel() end
	if pressed=="Save" then savelines(subs, sel) end
	lastrep1=res.rep1
	lastrep2=res.rep2
	return sel
end

function savelines(subs, sel)
    local data={}	raw=res.dat.."\n"
    if #sel==1 then raw=raw:gsub("\n(.)","\\N%1") raw=raw:gsub("\\N "," \\N") end
    for dataline in raw:gmatch("(.-)\n") do table.insert(data,dataline) end
    failt=0    
    if #sel~=#data and #sel>1 then failt=1 else
	for x, i in ipairs(sel) do
        local line=subs[i]
	local text=subs[i].text
	text=data[x]
	line.text=text
	subs[i]=line
	end
    end
    if failt==1 then aegisub.dialog.display({{class="label",
		    label="Line count of edited text does not \nmatch the number of selected lines.",x=0,y=0,width=1,height=2}},{"OK"})  
		    clipboard.set(res.dat) end
	aegisub.set_undo_point(script_name)
	return sel
end

aegisub.register_macro(script_name, script_description, editlines)