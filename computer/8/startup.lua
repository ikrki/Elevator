mainID=0
down=false
monitor=peripheral.find("monitor")
----

function sendButton()
	event,button,x,y=os.pullEvent("monitor_touch")
	if x>=3 and x<=5 and y>=4 and y<=5 and down==false then
        paintutils.drawFilledBox(3,4,5,5,colors.green)
		rednet.send(mainID,-1,"button")
		down=true
		return
	end
end

function sendContact()
	if  redstone.getInput("right")==true then
		rednet.send(0,true,"contact")
	end
	os.sleep(0.05)
end

function waitForLevel()
	local id,msg=rednet.receive("level",0.05)
	if id==mainID then 
		paintutils.drawPixel(3,10,colors.black)
		paintutils.drawPixel(4,10,colors.black)		
		if msg<0 then 
			monitor.setCursorPos(3,10) 
		else
			monitor.setCursorPos(4,10) 
		end
		monitor.write(tostring(msg))
	end
end

function waitForDirection()
	local id,msg=rednet.receive("direction",0.05)
	if id==0 then
		paintutils.drawPixel(4,9,colors.black)
		paintutils.drawPixel(4,11,colors.black)
		if msg>0 and redstone.getInput("right")==false then
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
	if id==0 then
		paintutils.drawFilledBox(3,4,5,5,colors.blue)
		down=false
		redstone.setOutput("left",true)
	end
end

function waitForDeparture()
	local id,msg=rednet.receive("departure",0.05)
	if id==0 then
		redstone.setOutput("left",false)
	end
end

----
do
	peripheral.find("modem", rednet.open)
	monitor.setBackgroundColor(colors.black)
	monitor.clear()
	term.redirect(monitor)
	paintutils.drawFilledBox(3,4,5,5,colors.blue)
	monitor.setTextColor(colors.yellow)
end

while true do	
	parallel.waitForAny(sendButton,sendContact,waitForLevel,waitForDirection,waitForArrival,waitForDeparture)
end
	