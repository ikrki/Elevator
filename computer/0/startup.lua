floors={
	[1]=-2,
	[2]=-1,
	[3]=1,
	[4]=2,
	[5]=3,
	[6]=4,
	[7]=5,
	[8]=6
}
eleID=9
direction=0
count=0
timer=0
latency=60
current=-256
minFloor=256
maxFloor=-256
offset=1024
revFloors={}
up={}
down={}
ele={}
signals={}
----

function getFloorFromID(x)
	if floors[x]~=nil then 
		return floors[x] 
	else 
		return 0
	end
end

function getIDFromFloor(x)	
	if revFloors[x]~=nil then 
		return revFloors[x]
	else 
		return 0
	end
end

function isFloorID(x)
	for k,v in pairs(floors) do	
		if k==x then return true end
	end
	return false
end

function waitForButtons()
	local id,msg=rednet.receive("button",0.05)
	if id~=nil then 
		if isFloorID(id)==true then
			table.insert(signals,id+offset*msg,msg)
		elseif id==eleID then
			table.insert(signals,getIDFromFloor(msg),0)
		end
	end
end

function waitForContact() 
	local id,msg=rednet.receive("contact",0.05)
    if msg==true then 
		current=getFloorFromID(id)
    end
end

function arrival(d)
	redstone.setOutput("back",true)--clutch
	rednet.send(getIDFromFloor(current),d,"arrival")	
	timer=latency
	direction=d
end

function goUpward()
	direction=1
	rednet.send(getIDFromFloor(current),true,"departure")
	redstone.setOutput("back",false)--clutch
	redstone.setOutput("right",true)--gearshift
end

function goDownward()	
	direction=-1
	rednet.send(getIDFromFloor(current),true,"departure")
	redstone.setOutput("back",false)--clutch
	redstone.setOutput("right",false)--gearshift
end

function shouldGoUpward()	
	if timer>0 then return end
	for k,v in pairs(floors) do
		if (up[v]==true or down[v]==true or  ele[v]==true) and v>current then
			return true
		end
	end
	return false
end

function shouldGoDownward()
	if timer>0 then return end
	for k,v in pairs(floors) do
		if (up[v]==true or down[v]==true or  ele[v]==true) and v<current then
			return true
		end
	end
	return false
end

function main()	
	local temp={}
	for dest,dir in pairs(signals) do--deal with button signals		
		if getFloorFromID(dest%offset)==current and direction~=0 and timer==0 then--just departed		
			table.insert(temp,dest,dir) 
		end			
		if getFloorFromID(dest%offset)~=current then		
			dest=getFloorFromID(dest%offset)
			if dir==1 then --upward
				up[dest]=true
				count=count+1	
			end
			if dir==-1 then --downward
				down[dest]=true
				count=count+1
			end
			if dir==0 then
				ele[dest]=true
				count=count+1
				if (direction==0 or timer>0) then timer=latency end
			end
		end
		--call the elevator from where it at
		if getFloorFromID(dest%offset)==current and (direction==0 or timer>0) then
			rednet.send(dest%offset,dir,"arrival")
			timer=latency
			if count==0 and dir~=0 then 
				direction=dir
			end
			rednet.broadcast(direction,"direction")
		end
	end
	signals=temp
	
	if current~=-256 then
		rednet.broadcast(current,"level")
	end
	rednet.broadcast(direction,"direction")

	if direction==0 and count>0 then--initialize
		if shouldGoUpward()==true then goUpward() end
		if shouldGoDownward()==true then goDownward() end
	end
	if timer==0 and count==0 then direction=0	end
	if direction==1 then
		if up[current]==true or ele[current]==true then		
			if up[current]==true then 
				count=count-1
				up[current]=false
			end
			if ele[current]==true then 
				count=count-1
				ele[current]=false
			end
			if current==maxFloor then arrival(-1) 
			else arrival(1) end			
		end	
		if down[current]==true and shouldGoUpward()==false then			
			down[current]=false
			count=count-1
			arrival(-1)
		end
		if shouldGoUpward()==true then
			goUpward() 
			return
		end
		if shouldGoDownward()==true then 
			goDownward() 
			return
		end		
	end
	
	if direction==-1 then
		if down[current]==true or ele[current]==true then
			if down[current]==true then 
				count=count-1
				down[current]=false
			end
			if ele[current]==true then 
				count=count-1
				ele[current]=false
			end
			if current==minFloor then arrival(1) 
			else arrival(-1) end		
		end	
		if up[current]==true and shouldGoDownward()==false then
			up[current]=false
			count=count-1
			arrival(1)
		end
		if shouldGoDownward()==true then 
			goDownward() 
			return
		end
		if  shouldGoUpward()==true then 
			goUpward() 
			return
		end
	end		
	if timer>0 then timer=timer-1 end
end

----
redstone.setOutput("back",true)
peripheral.find("modem", rednet.open)

for k,v in pairs(floors) do
	up[v]=false
	down[v]=false
	ele[v]=false
	revFloors[v]=k
	if v<minFloor then minFloor=v end
	if v>maxFloor then maxFloor=v end
end

local id,msg=rednet.receive("contact",0.05)
if msg==true then 
	current=getFloorFromID(id)	
end

while true do
	parallel.waitForAll(waitForButtons,waitForContact,main)
end