local args = {...}
local subtitles = require("subtitles")

local modem = peripheral.find("modem") or error("No modem attached", 0)
local channel = tonumber(args[1])

local datas = {}

local dir = "net/"

for x=0,2687 do
    local zeros = ""
    for y=1,5-tostring(x):len() do
        zeros = zeros .. "0"
    end
    local file = fs.open("net/".."image" .. zeros .. x .. ".pbb", "rb")
    print("image" .. zeros .. x .. ".pbb")
    table.insert(datas, file.readAll())
    file.close()
end

local subtitle = ""

while 1 do
    for k,data in pairs(datas) do
        if subtitles[k] then subtitle = subtitles[k] end
        modem.transmit(channel, channel, {type="TV_SIGNAL", data=data, subtitles=subtitle})
        os.sleep(0.3*4)
    end
end

