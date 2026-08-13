--!strict

export type TransitionMap = { [string]: { [string]: boolean } }

local StateMachine = {}
StateMachine.__index = StateMachine

export type StateMachine = typeof(setmetatable({} :: {
    _state: string,
    _transitions: TransitionMap,
    _history: { string },
}, StateMachine))

function StateMachine.new(initialState: string, transitions: TransitionMap): StateMachine
    assert(initialState ~= "", "initialState must not be empty")

    return setmetatable({
        _state = initialState,
        _transitions = transitions,
        _history = { initialState },
    }, StateMachine)
end

function StateMachine:getState(): string
    return self._state
end

function StateMachine:canTransition(nextState: string): boolean
    local allowed = self._transitions[self._state]
    return allowed ~= nil and allowed[nextState] == true
end

function StateMachine:transition(nextState: string)
    if not self:canTransition(nextState) then
        error(string.format("invalid transition: %s -> %s", self._state, nextState), 2)
    end

    self._state = nextState
    table.insert(self._history, nextState)
end

function StateMachine:getHistory(): { string }
    return table.clone(self._history)
end

return StateMachine
