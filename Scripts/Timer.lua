function CreateTimer( self )
    local TimerClass = class()
    TimerClass.Env = self
    TimerClass.ActiveTimers = {}

    function TimerClass:Delay( time, callback, params )
        table.insert(self.ActiveTimers, {t=time, c=callback, e=env, p=params})
    end

    function TimerClass:Tick()
        for _,i in pairs(self.ActiveTimers) do
            i.t = i.t - 1
            if i.t <= 0 then
                i.c(self.Env, i.p)
                table.remove(self.ActiveTimers, _)
            end
        end
    end

    self.Timer = TimerClass
end