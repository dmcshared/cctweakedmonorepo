local textbuffer = {}

local textbufferProto = {}
textbufferProto.__index = textbufferProto

function textbuffer.createBuffer()
    local buffer = {}
    setmetatable(buffer, textbufferProto)
    buffer.data = {}
    buffer.scroll = 0
    return buffer
end

function textbufferProto.addLine(self, line)
    table.insert(self.data, line)
end

function textbufferProto.render(self, x, y, width, height)
    local protoBuf = {}
    local firstLine = math.max(1, #self.data - height + 1 - self.scroll)
    local lastLine = math.max(1, #self.data - self.scroll)

    for i = firstLine, lastLine do
        local line = self.data[i]
        for j = 1, math.ceil(#line / width) do
            local linePart = line:sub((j - 1) * width + 1, j * width)
            table.insert(protoBuf, linePart)
        end
    end

    local lineFill = ""
    for xPos = 1, width do
        lineFill = lineFill .. " "
    end

    for yPos = 1, height do
        term.setCursorPos(x, y + yPos - 1)
        term.write(lineFill)
    end

    for yPos = 1, math.min(height, #protoBuf) do
        local line = protoBuf[#protoBuf - height + yPos]
        if line then
            term.setCursorPos(x, y + yPos - 1)
            term.write(line)
        end
    end

end

return textbuffer
