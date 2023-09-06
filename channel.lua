local args = {...}
local subtitles = require("subtitles")

local modem = peripheral.find("modem") or error("No modem attached", 0)
local channel = tonumber(args[1])

local datas = {}

local filename = "out.pbb"
local file = fs.open(filename, "rb")
local filedata = file.readAll()
file.close()

local off = 0

local b = {}
for x=1,filedata:len() do
    table.insert(b, math.floor(filedata:byte(x)))
end

while 1 do
    print(b[1+off], "balls")
    if b[1+off]==nil then break end
    local size = {w = b[1+off]^2^8+b[2+off], h = b[3+off]^2^8+b[4+off]} --Convert the first 4 bytes to 2 16 bit numbers representing width and height.

    local bitdepth = math.floor(b[5+off]/16)
    local nextoff = off+5
    print(nextoff, 2)

    if b[5+off]%16==2 then
        nextoff = nextoff + 2^bitdepth*3 --Add rgb bytes if palette is enabled
    end
    print(nextoff, 3)

    print(size.w,size.h)
    print(math.floor(size.w/2),math.floor(size.h))
    nextoff = nextoff + math.floor(size.w/2)*math.floor(size.h)
    print(nextoff, 4)

    local rdata = filedata:sub(1+off, nextoff)
    table.insert(datas, rdata)
    off = nextoff
end

local subtitle = ""

while 1 do
    for k,data in pairs(datas) do
        if subtitles[k] then subtitle = subtitles[k] end
        modem.transmit(channel, channel, {type="TV_SIGNAL", data=data, subtitles=subtitle})
        print(k)
        os.sleep(0.3*4)
    end
end


