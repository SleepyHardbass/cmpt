--        |                      exist  |          |
--        |          enabled |          |          |
-- data: {| online | offline | disabled | released |}
--            A         B          C         D
-- A: online, enabled, exist
-- B: offline, enabled, exist
-- C: offline, disabled, exist
-- D: offline, disabled, released

local NOT, AND, SAR; do
    local bit = require("bit")
    NOT = bit.bnot
    AND = bit.band
    SAR = bit.arshift
    bit = nil
end

return {
    id = function(self, index)
        return self.map[index + index + 1]
    end,
    setid = function(self, index, id)
        self.map[index + index + 1] = id
        return self
    end,
    index = function(self, id)
        return self.map[id + id]
    end,
    setindex = function(self, id, index)
        self.map[id + id] = index
        return self
    end,
    value = function(self, id)
        local index = self.map[id + id]
        return self.array[index]
    end,
    setvalue = function(self, id, value)
        local index = self.map[id + id]
        self.array[index] = value
        return self
    end,
    swap = function(self, fid, sid, findex, sindex)
        self.map[fid + fid] = sindex
        self.map[sid + sid] = findex
        self.map[findex + findex + 1] = sid
        self.map[sindex + sindex + 1] = fid
        self.array[findex], self.array[sindex] = self.array[sindex], self.array[findex]
        return self
    end,
    swapid = function(self, fid, sid)
        return self:swap(fid, sid, self.map[fid + fid], self.map[sid + sid])
    end,
    swapindex = function(self, findex, sindex)
        return self:swap(self.map[findex + findex + 1], self.map[sindex + sindex + 1], findex, sindex)
    end,
    length = function(self)
        return self.conline + self.coffline + self.cdisable
    end,
    valid = function(self, id)
        return SAR(AND(-id, id + id - self.size), 31)
    end,
    exist = function(self, id)
        local status = SAR(AND(-id, id + id - self.size), 31)
        local index = self.map[AND(id + id, status)]
        local length = self.conline + self.coffline + self.cdisable
        return AND(SAR(index - (length + 1), 31), status)
    end,
    enabled = function(self, id)
        local status = SAR(AND(-id, id + id - self.size), 31)
        local index = self.map[AND(id + id, status)]
        return AND(SAR(index - (self.conline + self.coffline + 1), 31), status)
    end,
    disabled = function(self, id)
        local status = SAR(AND(-id, id + id - self.size), 31)
        local index = self.map[AND(id + id, status)]
        return AND(SAR(self.conline + self.coffline - index, 31), status)
    end,
    online = function(self, id)
        local status = SAR(AND(-id, id + id - self.size), 31)
        local index = self.map[AND(id + id, status)]
        return AND(SAR(index - (self.conline + 1), 31), status)
    end,
    offline = function(self, id)
        local status = SAR(AND(-id, id + id - self.size), 31)
        local index = self.map[AND(id + id, status)]
        return AND(SAR(self.conline - index, 31), status)
    end,
    disconnect = function(self, id)
        local status = SAR(AND(-id, id + id - self.size), 31)
        local index = self.map[AND(id + id, status)]
        status = AND(SAR(index - (self.conline + 1), 31), status)
        self.conline = self.conline + status
        self.coffline = self.coffline - status
        return self:swapindex(AND(index, status), AND(self.conline + 1, status))
    end,
    connect = function(self, id)
        id = AND(id, SAR(AND(-id, id + id - self.size), 31))
        id = AND(id, SAR(self.map[id + id] - (self.conline + self.coffline + self.cdisable + 1), 31))
        
        local index = self.map[id + id]
        local status = SAR(self.conline + self.coffline - index, 31)
        self.cdisable = self.cdisable + status
        self.coffline = self.coffline - status
        self:swapindex(AND(index, status), AND(self.conline + self.coffline, status))
        
        index = self.map[id + id]
        status = SAR(self.conline - index, 31)
        self.coffline = self.coffline + status
        self.conline = self.conline - status
        return self:swapindex(AND(index, status), AND(self.conline, status))
    end,
    disable = function(self, id)
        local valid = SAR(AND(-id, id + id - self.size), 31)
        id = AND(id, valid)
        
        local index = self.map[id + id]
        local status = AND(SAR(index - (self.conline + 1), 31), valid)
        self.conline = self.conline + status
        self.coffline = self.coffline - status
        self:swapindex(AND(index, status), AND(self.conline + 1, status))
        
        index = self.map[id + id]
        status = AND(SAR(index - (self.conline + self.coffline + 1), 31), valid)
        self.coffline = self.coffline + status
        self.cdisable = self.cdisable - status
        return self:swapindex(AND(index, status), AND(self.conline + self.coffline + 1, status))
    end,
    enable = function(self, id)
        id = AND(id, SAR(AND(-id, id + id - self.size), 31))
        id = AND(id, SAR(self.map[id + id] - (self.conline + self.coffline + self.cdisable + 1), 31))
        
        local index = self.map[id + id]
        local status = SAR(self.conline + self.coffline - index, 31)
        self.cdisable = self.cdisable + status
        self.coffline = self.coffline - status
        return self:swapindex(AND(index, status), AND(self.conline + self.coffline, status))
    end,
    release = function(self, id)
        local valid = SAR(AND(-id, id + id - self.size), 31)
        id = AND(id, valid)
        
        local index = self.map[id + id]
        local status = AND(SAR(index - (self.conline + 1), 31), valid)
        self.conline = self.conline + status
        self.coffline = self.coffline - status
        self:swapindex(AND(index, status), AND(self.conline + 1, status))
        
        index = self.map[id + id]
        status = AND(SAR(index - (self.conline + self.coffline + 1), 31), valid)
        self.coffline = self.coffline + status
        self.cdisable = self.cdisable - status
        self:swapindex(AND(index, status), AND(self.conline + self.coffline + 1, status))
        
        index = self.map[id + id]
        local length = self.conline + self.coffline + self.cdisable
        status = AND(SAR(index - (length + 1), 31), valid)
        self.cdisable = self.cdisable + status
        return self:swapindex(AND(index, status), AND(length, status))
    end,
    clone = function(self, id)
        local value = self.array[ self.map[id + id] ]
        local index = self.conline + self.coffline + self.cdisable + 1
        id = index + index + 1
        if id > self.size then
            id = SAR(self.size + 1, 1)
            self.size = self.size + 2
        else
            id = self.map[id]
        end
        self.cdisable = self.cdisable + 1
        self.map[index + index + 1] = id
        self.map[id + id] = index
        self.array[index] = value
        -- ...
        
        return self, id
    end,
    create = function(self, value)
        local index = self.conline + self.coffline + self.cdisable + 1
        local id = index + index + 1
        if id > self.size then
            id = SAR(self.size + 1, 1)
            self.size = self.size + 2
        else
            id = self.map[id]
        end
        self.cdisable = self.cdisable + 1
        self.map[index + index + 1] = id
        self.map[id + id] = index
        self.array[index] = value
        return self, id
    end,
    getmt = function(self)
        if not self.__mt then
            self.__mt = {__index = self, __call = self.create}
        end
        return self.__mt
    end,
    new = function(self)
        return setmetatable({
            array = {[0] = 0},
            map = {[0] = 0, 0},
            size = 1,
            conline = 0,
            coffline = 0,
            cdisable = 0,
        }, self:getmt())
    end
}
