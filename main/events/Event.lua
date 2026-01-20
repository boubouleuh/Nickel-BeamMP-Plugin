function Event(fn)
    local e = {
        callback = fn,
        timer = false,
        interval = 0,
        valid = true
    }

    function e:Every(ms)
        self.timer = true
        self.interval = ms
        return self
    end

    function e:If(condition)
        local originalCallback = self.callback
        self.callback = function(...)
            if type(condition) == "function" then
                if condition(...) then
                    return originalCallback(...)
                end
            elseif condition then
                return originalCallback(...)
            end
        end
        return self
    end

    function e:Require(condition)
        if not condition then self.valid = false end
        return self
    end


    return e
end