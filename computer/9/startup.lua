mainID=0
floors={
	-2,
	-1,
	1,
	2,
	3,
	4,
	5,
	6
}
buttons={
	{2,23,6,23},
	{10,23,14,23},
	{2,20,6,20},
	{10,20,14,20},
	{2,17,6,17},
	{10,17,14,17},
	{2,14,6,14},
	{10,14,14,14}
}
monitor=peripheral.find("monitor")
maxLevel=table.getn(floors)
current=0
last={}
----

function getMinMax()
	local Min=256
	local Max=-256
	for k,v in pairs(floors) do
		if v<Min then Min=v end
		if v>Max then Max=v end
	end
	return Min,Max
end

function drawButton(i,color)
	paintutils.drawFilledBox(buttons[i][1],buttons[i][2],buttons[i][3],buttons[i][4],color)
    if floors[i]<0 then
		monitor.setCursorPos((buttons[i][1]+buttons[i][3])/2-1,buttons[i][2])
	else
		monitor.setCursorPos((buttons[i][1]+buttons[i][3])/2,buttons[i][2])	
	end	
    monitor.write(tostring(floors[i]))
end

function sendButton()
	event,button,x,y=os.pullEvent("monitor_touch")
	for i,v in ipairs(floors) do
		if x>=buttons[i][1] and x<=buttons[i][3] and y>=buttons[i][2] and y<=buttons[i][4] then
			rednet.send(mainID,v,"button")
			drawButton(i,colors.green)
			if v~=current then table.insert(last,i) end
		end
	end
end	

function waitForLevel()
	local id,msg=rednet.receive("level",0.05)
	if id==mainID then 
		current=msg
		paintutils.drawPixel(7,5,colors.lightGray)
		paintutils.drawPixel(8,5,colors.lightGray)
		monitor.setTextColor(colors.yellow)
		if msg<0 then 
			monitor.setCursorPos(7,5) 
		else
			monitor.setCursorPos(8,5) 
		end
		monitor.write(tostring(msg))
		monitor.setTextColor(colors.white)
		local i=0
		for k,v in pairs(floors) do
			if v==current then 
				i=k
			end
		end
		drawButton(i,colors.blue)
	end
end

function waitForDirection()
	local id,msg=rednet.receive("direction",0.05)
	if id==mainID then
		paintutils.drawPixel(8,4,colors.lightGray)
		paintutils.drawPixel(8,6,colors.lightGray)
		monitor.setTextColor(colors.yellow)
		local minFloor,maxFloor=getMinMax()
		if msg>0 and current~=maxFloor then
			monitor.setCursorPos(8,4)
			monitor.write("^")
		end
		if msg<0 and current~=minFloor then
			monitor.setCursorPos(8,6)
			monitor.write("v")
		end
		monitor.setTextColor(colors.white)
		if msg==0 then
			--do nothing
		end
	end
end

function writeRecord()
	local rec=io.open("record","w")
	io.output(rec)
	for k,v in pairs(last) do
		io.write(v)
		io.write("\n")
	end
	io.write(-1)
	io.close(rec)
end

----
do
	redstone.setOutput("back",true)
	peripheral.find("modem", rednet.open)
	monitor.setTextColor(colors.white)
	monitor.setBackgroundColor(colors.black)
	monitor.clear()
	monitor.setTextScale(0.5)
	term.redirect(monitor)
end

do
	if io.open("record","r")==nil then
		local newfile=io.open("record","w")
		io.output(newfile)
		io.write(-1)
		io.close()
	end
	_,current=rednet.receive("level",0.5)
	local record=io.open("record","r")
	io.input(record)
	local temp=io.read("*l")
	while temp~=nil do
		if tonumber(temp)==-1 then break end
		if floors[tonumber(temp)]~=current then 
			table.insert(last,tonumber(temp)) 
		end
		temp=io.read("*l")
	end
	io.close(record)
end

do
	for i=1,maxLevel do
		local color=colors.blue
		for k,v in pairs(last) do
			if v==i then color=colors.green end
		end
		drawButton(i,color)
	end
	paintutils.drawFilledBox(4,3,12,7,colors.lightGray)
end

while true do    
    parallel.waitForAny(sendButton,waitForLevel,waitForDirection)
	writeRecord()
end