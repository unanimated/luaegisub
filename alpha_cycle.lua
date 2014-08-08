-- if an alpha tag exists, changes it to alphaFF, otherwise creates it. if there's alphaFF, cycles through 00, 30, 60, 80, A0, D0, FF

script_name="Alpha cycle"
script_description="Add alpha tags to selected lines."
script_author="unanimated"
script_version="1.53"

sequence={"FF","00","10","30","60","80","A0","C0","E0"}	-- you can modify this

function alpha(subs, sel)
    for z, i in ipairs(sel) do
	line=subs[i]
	text=line.text
	    tf=""
	    if text:match("^{\\[^}]-}") then
	    tags,after=text:match("^({\\[^}]-})(.*)")
		if tags:match("\\t") then 
		    for t in tags:gmatch("\\t%b()") do tf=tf..t end
		    tags=tags:gsub("\\t%b()","")
		    :gsub("{}","")
		    text=tags..after
		end
	    end

	    al=text:match("^{[^}]-\\alpha&H(%x%x)&")
	    if al~=nil then
		for b=1,#sequence do
		    if al==sequence[b] then al2=sequence[b+1] end
		end
		if al2==nil then al2="FF" end
		text=text:gsub("^({[^}]-\\alpha&H)%x%x","%1"..al2)
	    else
		text="{\\alpha&HFF&}" .. text
		text=text:gsub("{\\alpha&HFF&}{(\\[^}]-)}","{%1\\alpha&HFF&}")
	    end

	text=text:gsub("^({\\[^}]-)}","%1"..tf.."}")
	line.text=text
	subs[i]=line
    end
    aegisub.set_undo_point(script_name)
    return sel
end

aegisub.register_macro(script_name, script_description, alpha)