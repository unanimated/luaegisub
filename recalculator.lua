-- Example: Set to 120%, check fscx and fscy, and all values for fscx/y will be increased by 20% for selected lines.

script_name="Recalculator"
script_description="recalculates sizes of things"
script_author="unanimated"
script_version="1.7"

function calc(num)
    if pressed=="Multiply" then num=math.floor((num*c*100)+0.5)/100 end
    if pressed=="Add" then num=num+res.add end
    return num
end

function multiply(subs, sel)
    c=res.pc/100
    for x, i in ipairs(sel) do
        line=subs[i]
	text=line.text
	styleref=stylechk(line.style)
	if not text:match("^{\\") then text="{\\}"..text end
	
		scx=styleref.scale_x
	if res.fscx and not text:match("\\fscx") then text=text:gsub("^({\\[^}]*)}","%1\\fscx"..scx.."}") end
		scy=styleref.scale_y
	if res.fscy and not text:match("\\fscy") then text=text:gsub("^({\\[^}]*)}","%1\\fscy"..scy.."}") end
		fsize=styleref.fontsize
	if res.fs and not text:match("\\fs%d") then text=text:gsub("^({\\[^}]*)}","%1\\fs"..fsize.."}") end 
		brdr=styleref.outline
	if res.bord and not text:match("\\bord") and brdr~=0 then text=text:gsub("^({\\[^}]*)}","%1\\bord"..brdr.."}") end
		shdw=styleref.shadow
	if res.shad and not text:match("\\shad") and shdw~=0 then text=text:gsub("^({\\[^}]*)}","%1\\shad"..shdw.."}") end
		spac=styleref.spacing
	if res.fsp and not text:match("\\fsp") and spac~=0 then text=text:gsub("^({\\[^}]*)}","%1\\fsp"..spac.."}") end
	
	    if res.fscx then text=text:gsub("\\fscx([%d%.]+)",function(a) return "\\fscx"..calc(tonumber(a)) end) end
	    if res.fscy then text=text:gsub("\\fscy([%d%.]+)",function(a) return "\\fscy"..calc(tonumber(a)) end) end
	    if res.fs then text=text:gsub("\\fs([%d%.]+)",function(a) return "\\fs"..calc(tonumber(a)) end) end
	    if res.fsp then text=text:gsub("\\fsp([%d%.%-]+)",function(a) return "\\fsp"..calc(tonumber(a)) end) end
	    if res.bord then text=text:gsub("\\bord([%d%.]+)",function(a) return "\\bord"..calc(tonumber(a)) end) end
	    if res.shad then text=text:gsub("\\shad([%d%.]+)",function(a) return "\\shad"..calc(tonumber(a)) end) end
	    if res.blur then text=text:gsub("\\blur([%d%.]+)",function(a) return "\\blur"..calc(tonumber(a)) end) end
	    if res.be then text=text:gsub("\\be([%d%.]+)",function(a) return "\\be"..calc(tonumber(a)) end) end
	    if res.xbord then text=text:gsub("\\xbord([%d%.]+)",function(a) return "\\xbord"..calc(tonumber(a)) end) end
	    if res.ybord then text=text:gsub("\\ybord([%d%.]+)",function(a) return "\\ybord"..calc(tonumber(a)) end) end
	    if res.xshad then text=text:gsub("\\xshad([%d%.%-]+)",function(a) return "\\xshad"..calc(tonumber(a)) end) end
	    if res.yshad then text=text:gsub("\\yshad([%d%.%-]+)",function(a) return "\\yshad"..calc(tonumber(a)) end) end
	    if res.frx then text=text:gsub("\\frx([%d%.%-]+)",function(a) return "\\frx"..calc(tonumber(a)) end) end
	    if res.fry then text=text:gsub("\\fry([%d%.%-]+)",function(a) return "\\fry"..calc(tonumber(a)) end) end
	    if res.frz then text=text:gsub("\\frz([%d%.%-]+)",function(a) return "\\frz"..calc(tonumber(a)) end) end
	    if res.fax then text=text:gsub("\\fax([%d%.%-]+)",function(a) return "\\fax"..calc(tonumber(a)) end) end
	    if res.posx then text=text:gsub("\\pos%(([%d%.%-]+),([%d%.%-]+)%)",function(a,b) 
	    return "\\pos("..calc(tonumber(a))..","..b..")" end) end
	    if res.posy then text=text:gsub("\\pos%(([%d%.%-]+),([%d%.%-]+)%)",function(a,b) 
	    return "\\pos("..a..","..calc(tonumber(b))..")" end) end
	    if res.move then text=text:gsub("\\move%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)",function(a,b,c,d) 
	    return "\\move("..calc(tonumber(a))..","..calc(tonumber(b))..","..calc(tonumber(c))..","..calc(tonumber(d)) end) end
	    if res.org then text=text:gsub("\\org%(([%d%.%-]+),([%d%.%-]+)%)",function(a,b) 
	    return "\\org("..calc(tonumber(a))..","..calc(tonumber(b))..")" end) end
	    
	    if res.clip then
		if res.anchor and pressed=="Multiply" then m=1/c
		  text=text:gsub("clip%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)",
		  function(a,b,c,d) x=(a+c)/2-((a+c)/2)*m y=(b+d)/2-((b+d)/2)*m return "clip("..a-x..","..b-y..","..c-x..","..d-y end)
		  if text:match("clip%(m [%d%a%s%-%.]+%)") then
		    ctext=text:match("clip%(m ([%d%a%s%-%.]+)%)")
		    c1,c2=ctext:match("([%d%-%.]+)%s([%d%-%.]+)")
		    x=c1-c1*m y=c2-c2*m
		    ctext2=ctext:gsub("([%d%-%.]+)%s([%d%-%.]+)",function(a,b) return a-x.." "..b-y end)
		    ctext=ctext:gsub("%-","%%-")
		    text=text:gsub("clip%(m "..ctext,"clip(m "..ctext2)
	          end
		end
	    text=text:gsub("clip%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)%)",function(a,b,c,d) 
	    return "clip("..calc(tonumber(a))..","..calc(tonumber(b))..","..calc(tonumber(c))..","..calc(tonumber(d))..")" end) 
	      if text:match("clip%(m [%d%a%s%-%.]+%)") then
	      ctext=text:match("clip%(m ([%d%a%s%-%.]+)%)")
	      ctext2=ctext:gsub("([%d%-%.]+)%s([%d%-%.]+)",function(a,b) return calc(tonumber(a)).." "..calc(tonumber(b)) end)
	      ctext=ctext:gsub("%-","%%-")
	      text=text:gsub(ctext,ctext2)
	      end
	    end
	    
	    if res.drawx or res.drawy then
	      if text:match("\\p[1-9]") and text:match("}m [%d%a%s%-%.]+") then
	      dtext=text:match("}m ([%d%a%s%-%.]+)")
	      dtext2=dtext:gsub("([%d%-%.]+)%s([%d%-%.]+)",function(a,b) 
		if res.drawx then xx=math.floor(calc(tonumber(a))+0.5) else xx=a end
		if res.drawy then yy=math.floor(calc(tonumber(b))+0.5) else yy=b end
		return xx.." "..yy end)
	      dtext=dtext:gsub("%-","%%-")
	      text=text:gsub(dtext,dtext2)
	      end
	    end
	    
	    if res.ttim then text=text:gsub("\\t%(([%d%.%-]+),([%d%.%-]+),",function(a,b) 
	    return "\\t("..calc(tonumber(a))..","..calc(tonumber(b)).."," end) end
	    
	text=text:gsub("\\\\","\\")
	text=text:gsub("\\}","}")
	text=text:gsub("{}","")
	line.text=text
        subs[i]=line
    end
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

function recalculator(subs, sel)
	dialog_config=
	{
	    {x=0,y=0,width=2,height=1,class="label",label="Change values to:",},
	    {x=2,y=0,width=2,height=1,class="floatedit",name="pc",value=100,min=0,hint="Multiply"},
	    {x=4,y=0,width=1,height=1,class="label",label="%",},
	    
	    {x=0,y=1,width=2,height=1,class="label",label="Increase values by:",},
	    {x=2,y=1,width=2,height=1,class="floatedit",name="add",value=0,hint="Add (use negative to subtract)"},
	    
	    {x=0,y=2,width=1,height=1,class="checkbox",name="fscx",label="fscx",value=true,},
	    {x=1,y=2,width=1,height=1,class="checkbox",name="fscy",label="fscy",value=true,},
	    {x=2,y=2,width=1,height=1,class="checkbox",name="fs",label="fs",value=false,},
	    {x=3,y=2,width=1,height=1,class="checkbox",name="fsp",label="fsp",value=false,},
	    
	    {x=0,y=3,width=1,height=1,class="checkbox",name="bord",label="bord",value=false,},
	    {x=1,y=3,width=1,height=1,class="checkbox",name="shad",label="shad",value=false,},
	    {x=2,y=3,width=1,height=1,class="checkbox",name="blur",label="blur",value=false,},
	    {x=3,y=3,width=1,height=1,class="checkbox",name="be",label="be",value=false,},
	    
	    {x=0,y=4,width=1,height=1,class="checkbox",name="xbord",label="xbord",value=false,},
	    {x=1,y=4,width=1,height=1,class="checkbox",name="ybord",label="ybord",value=false,},
	    {x=2,y=4,width=1,height=1,class="checkbox",name="xshad",label="xshad",value=false,},
	    {x=3,y=4,width=1,height=1,class="checkbox",name="yshad",label="yshad",value=false,},
	    
	    {x=0,y=5,width=1,height=1,class="checkbox",name="frx",label="frx",value=false,},
	    {x=1,y=5,width=1,height=1,class="checkbox",name="fry",label="fry",value=false,},
	    {x=2,y=5,width=1,height=1,class="checkbox",name="frz",label="frz",value=false,},
	    {x=3,y=5,width=1,height=1,class="checkbox",name="fax",label="fax",value=false,},
	    
	    {x=0,y=6,width=1,height=1,class="checkbox",name="posx",label="pos x",value=false,},
	    {x=1,y=6,width=1,height=1,class="checkbox",name="posy",label="pos y",value=false,},
	    {x=2,y=6,width=1,height=1,class="checkbox",name="move",label="move",value=false,},
	    {x=3,y=6,width=1,height=1,class="checkbox",name="org",label="org",value=false,},
	    
	    {x=0,y=7,width=1,height=1,class="checkbox",name="clip",label="clip",value=false,},
	    {x=1,y=7,width=4,height=1,class="checkbox",name="anchor",label="anchor clip with Multiply",value=false,},
	    
	    {x=0,y=8,width=1,height=1,class="checkbox",name="drawx",label="draw x",value=false,},
	    {x=1,y=8,width=1,height=1,class="checkbox",name="drawy",label="draw y",value=false,},
	    {x=2,y=8,width=2,height=1,class="checkbox",name="ttim",label="\\t times",value=false,},
	} 	
	pressed, res=aegisub.dialog.display(dialog_config,
		{"Multiply","Add","Cancel"},{ok='Multiply',cancel='Cancel'})
	if pressed=="Cancel" then    aegisub.cancel() end
	if pressed=="Multiply" or pressed=="Add" then  styleget(subs)  multiply(subs, sel) end
	aegisub.set_undo_point(script_name)
	return sel
end

aegisub.register_macro(script_name, script_description, recalculator)