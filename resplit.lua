-- Moves the last word of the line to the start of the next, or the first word of the next line to the end of the active one.

script_name="Re-Split"
script_description="Resplits lines at a different place"
script_author="unanimated"
script_version="1.1"

function resplitl(subs,sel,act)
	line=subs[act]
	text=line.text
	if act<#subs then
	    nl=subs[act+1]
	    first=nl.text:match("^([%w']+%p?) ")
	    if first==nil then first=nl.text:match("^{\\[^}]-}([%w']+%p?) ") end
	    if first~=nil then
		nl.text=nl.text:gsub("^([%w']+%p?) ","") :gsub("^({\\[^}]-})[%w']+%p? ","%1")
		text=text.." "..first
	    end
	    subs[act+1]=nl
	end
	line.text=text
	subs[act]=line
    aegisub.set_undo_point(script_name)
    return sel
end

function resplitr(subs,sel,act)
	line=subs[act]
	text=line.text
	if act<#subs then
	    nl=subs[act+1]
	    last=text:match("[} ]([%w']+%p?)$")
	    if last~=nil then
		text=text:gsub("%s?[%w']+%p?$","") :gsub("%s*{\\[^}]-}$","")
		if nl.text:match("^{\\[^}]-}") then
		  nl.text=nl.text:gsub("^({\\[^}]-})","%1"..last.." ")
		else
		  nl.text=last.." "..nl.text
		end
	    end
	    subs[act+1]=nl
	end
	line.text=text
	subs[act]=line
    aegisub.set_undo_point(script_name)
    return sel
end

aegisub.register_macro("ReSplit - Backward",script_description,resplitl)
aegisub.register_macro("ReSplit - Forward",script_description,resplitr)