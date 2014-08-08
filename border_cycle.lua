-- Adds \bord0 to selected lines, then cycles through 1, 2, 3, 4, 5, 6, 7, 8, 9, back to 0. 

script_name="Border cycle"
script_description="Add border tags to selected lines."
script_author="unanimated"
script_version="1.62"

sequence={"0","1","2","3","4","5","6","7","8","9"}	-- you can modify this

function bord(subs, sel)
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

	    br=text:match("^{[^}]-\\bord([%d%.]+)")
	    if br~=nil then
		for b=1,#sequence do
		    if br==sequence[b] then br2=sequence[b+1] end
		end
		if br2==nil then br2="0" end
		text=text:gsub("^({[^}]-\\bord)[%d%.]+","%1"..br2)
	    else
		text="{\\bord0}" .. text
		text=text:gsub("{\\bord0}{\\","{\\bord0\\")
	    end

	text=text:gsub("^({\\[^}]-)}","%1"..tf.."}")
	line.text=text
	subs[i]=line
    end
    aegisub.set_undo_point(script_name)
    return sel
end

aegisub.register_macro(script_name, script_description, bord)