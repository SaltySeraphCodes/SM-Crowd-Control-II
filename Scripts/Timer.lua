function CreateTimer( self )
    TimerClass = class()
    TimerClass.Env = self
    TimerClass.ActiveTimers = {}

    function TimerClass:Delay( time, callback, params )
        table.insert(self.ActiveTimers, {t=time, c=callback, e=env, p=params})
    end

    function TimerClass:Tick()
        for _,i in pairs(self.ActiveTimers) do
            i.t = i.t - 1
            if i.t <= 0 then
                i.c(i.p)
                table.remove(self.ActiveTimers, i)
            end
        end
    end

    self.Timer = TimerClass
    self.Delay = Delay
end