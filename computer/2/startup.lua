mainID=0
up=false
down=false
monitor=peripheral.find("monitor")
----

function sendButton()
	event,button,x,y=os.pullEvent("monitor_touch")
	if x>=3 and x<=5 and y>=2 and y<=3 and up==false then
        paintutils.drawFilledBox(3,2,5,3,colors.green)
		rednet.send(mainID,1,"button")
		up=true
		return
	end
	if x>=3 and x<=5 and y>=5 and y<=6 and down==false then
        paintutils.drawFilledBox(3,5,5,6,colors.green)
		rednet.send(mainID,-1,"button")
		down=true
	end
end

function sendContact()
	if  redstone.getInput("right")==true then
		rednet.send(mainID,true,"contact")
	end
	os.sleep(0.05)
end

function waitForLevel()
	local id,msg=rednet.receive("level",0.05)
	if id==mainID then 
		paintutils.drawPixel(3,10,colors.black)
		paintutils.drawPixel(4,10,colors.black)		
		if msg<mainID then 
			monitor.setCursorPos(3,10) 
		else
			monitor.setCursorPos(4,10) 
		end
		monitor.write(tostring(msg))
	end
end

function waitForDirection()
	local id,msg=rednet.receive("direction",0.05)
	if id==mainID then
		paintutils.drawPixel(4,9,colors.black)
		paintutils.drawPixel(4,11,colors.black)
		if msg>0 then
			monitor.setCursorPos(4,9)
			monitor.write("^")
		end
		if msg<0  then
			monitor.setCursorPos(4,11)
			monitor.write("v")
		end
		if msg==0 then
			--do nothing
		end
	end
end	

function waitForArrival()
	local id,msg=rednet.receive("arrival",0.05)
	if id==mainID and msg==1 then
		paintutils.drawFilledBox(3,2,5,3,colors.blue)
		up=false
		redstone.setOutput("left",true)
		return
	end
	if id==mainID and msg==-1 then
		paintutils.drawFilledBox(3,5,5,6,colors.blue)
		down=false
		redstone.setOutput("left",true)
	end
end

function waitForDeparture()
	local id,msg=rednet.receive("departure",0.05)
	if id==mainID then
		redstone.setOutput("left",false)
	end
end

----
do
	peripheral.find("modem", rednet.open)
	monitor.setBackgroundColor(colors.black)
	monitor.clear()
	term.redirect(monitor)
	paintutils.drawFilledBox(3,2,5,3,colors.blue)
	paintutils.drawFilledBox(3,5,5,6,colors.blue)
	monitor.setTextColor(colors.yellow)
end

while true do	
	parallel.waitForAny(sendButton,sendContact,waitForLevel,waitForDirection,waitForArrival,waitForDeparture)
end
	