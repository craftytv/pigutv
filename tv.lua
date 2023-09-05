local args = {...}
local pb
local status, err = pcall(function () pb = require("pixelbox_lite") end) -- Installation script : wget https://github.com/9551-Dev/apis/raw/main/pixelbox_lite.lua
if err then
    print("Pixelbox not installed")
    print("Would you like to install it? [yes/no]")
    if read()=="yes" then
        shell.run("wget https://github.com/9551-Dev/apis/raw/main/pixelbox_lite.lua")
    else
        return
    end
end

local subtitle = ""

local function center(term, text, y)
    local w,h = term.getSize()
    term.setCursorPos(w/2-text:len()/2+1,y)
    term.write(text)
end

local function renderSubtitles(term, text, bg, fg)
    term.setTextColor(fg)
    term.setBackgroundColor(bg)
    local w,h = term.getSize()
    for x=1,math.ceil(text:len()/w) do
        center(term, text:sub((x-1)*w+1, x*w), h-math.ceil(text:len()/w)+x)
    end
end

local datas = {}
local mon
local modem = peripheral.find("modem", function(_, p) return p.isWireless() end) or error("No modem attached", 0)

print("Are you using a monitor? [yes/no]")
if read()=="yes" then
    mon = peripheral.find("monitor")
    mon.setTextScale(0.5)
else
    mon = term
end

function c(n) if n then return math.floor(2^n) end return 1 end

local function getRGB(x)
    return colors.packRGB(mon.getPaletteColor(c(x)))
end

local chan = tonumber(args[1])
modem.open(chan)
print("Communication opened on channel " .. chan)

local active = true

parallel.waitForAll(function()
while active do
    local event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
    if (channel==chan) and (type(message) == "table") and (message.type=="TV_SIGNAL") then
        local data = message.data

        if message.subtitles then
            subtitle = message.subtitles
        end

        local b = {}
        for x=1,data:len() do
            table.insert(b, math.floor(data:byte(x)))
        end

        local size = {w = b[1]^2^8+b[2], h = b[3]^2^8+b[4]} --Convert the first 4 bytes to 2 16 bit numbers representing width and height.

        local bitdepth = math.floor(b[5]/16)

        local offset = -size.w+2+8

        if b[5]%16==1 then
            for x=0,15 do
                mon.setPaletteColor(2^x, mon.nativePaletteColor(2^x)) -- Palette mode 1: native terminal colors
            end
        end

        if b[5]%16==2 then
            for p=6,2^math.floor(b[5]/16)+5 do
                local index = (p-6)*3+6
                local tbl = {b[index], b[index+1], b[index+2]}  -- Palette mode 2: define colors
                local color = p-6
                mon.setPaletteColor(2^color, colors.packRGB(tbl[1]/255, tbl[2]/255, tbl[3]/255))
            end
            offset = -size.w+2^bitdepth*6+2+8+1 --Canvas bytes + Resolution bytes
        end

        local t = {}
        for x=1,data:len() do
            for y=8/bitdepth,1,-1 do
                table.insert(t, math.floor(math.floor(data:byte(x)/(2^(bitdepth*(y-1)))) % (2^bitdepth)))
            end
        end

        local monitor = pb.new(mon)
        local monsizew, monsizeh = mon.getSize()

        monitor:clear(c(15))

        local doublepix = false

        for x=1,size.w do
            for y=1,size.h do
                if doublepix then
                    for h=0,1 do
                        for l=0,1 do
                            monitor:set_pixel(x*2-1+h,y*2-1+l,c(t[offset+x+y*size.w])) --(not supported)
                        end
                    end
                else
                    for h=0,math.ceil(size.w/(monsizew*2))+1 do
                        for l=0,math.ceil(size.h/(monsizeh*3))+1 do
                            local status, err = pcall(function()
                            monitor:set_pixel(math.floor(x*((monsizew*2)/size.w))+h,math.floor(y*((monsizeh*3)/size.h))+l,c(t[offset+x+y*size.w]))
                            end)
                        end
                    end
                end
            end
        end

        monitor:render()

        local bg = 0
        local fg = 0
        for x=0,15 do
            if getRGB(x)>getRGB(fg) then
                fg = x
            elseif getRGB(x)<getRGB(bg) then
                bg = x
            end
        end

        renderSubtitles(mon, subtitle, c(bg), c(fg))
    end
end
os.queueEvent("tv")
os.pullEvent("tv")
end, function()
    local event = os.pullEventRaw("terminate")
    if event == "terminate" then
        activate = false
        for x=0,15 do
            mon.setPaletteColor(2^x, mon.nativePaletteColor(2^x)) -- Palette mode 1: native terminal colors
        end
    end
end)