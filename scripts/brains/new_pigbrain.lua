require "behaviours/wander"
require "behaviours/follow"
require "behaviours/faceentity"
require "behaviours/chaseandattack"
require "behaviours/runaway"
require "behaviours/doaction"
require "behaviours/findlight"
require "behaviours/panic"
require "behaviours/chattynode"
require "behaviours/leash"


local MIN_FOLLOW_DIST = 2
local TARGET_FOLLOW_DIST = 5
local MAX_FOLLOW_DIST = 9
local MAX_WANDER_DIST = 20

local LEASH_RETURN_DIST = 10
local LEASH_MAX_DIST = 30

local START_RUN_DIST = 3
local STOP_RUN_DIST = 5
local MAX_CHASE_TIME = 10
local MAX_CHASE_DIST = 30
local SEE_LIGHT_DIST = 20
local TRADE_DIST = 20
local SEE_TREE_DIST = 15
local SEE_TARGET_DIST = 20
local SEE_FOOD_DIST = 10

local KEEP_CHOPPING_DIST = 10

local RUN_AWAY_DIST = 5
local STOP_RUN_AWAY_DIST = 8

local function ShouldRunAway(inst, target)
    return not inst.components.trader:IsTryingToTradeWithMe(target)
end

local function GetTraderFn(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local players = FindPlayersInRange(x, y, z, TRADE_DIST, true)
    for i, v in ipairs(players) do
        if inst.components.trader:IsTryingToTradeWithMe(v) then
            return v
        end
    end
end

local function KeepTraderFn(inst, target)
    return inst.components.trader:IsTryingToTradeWithMe(target)
end

local function FindFoodAction(inst)
    local target = nil

	if inst.sg:HasStateTag("busy") then
		return
	end
    
    if inst.components.inventory and inst.components.eater then
        target = inst.components.inventory:FindItem(function(item) return inst.components.eater:CanEat(item) end)
    end
    
    local time_since_eat = inst.components.eater:TimeSinceLastEating()
    local noveggie = time_since_eat and time_since_eat < TUNING.PIG_MIN_POOP_PERIOD*4
    
    if not target and (not time_since_eat or time_since_eat > TUNING.PIG_MIN_POOP_PERIOD*2) then
        target = FindEntity(inst, SEE_FOOD_DIST, function(item) 
				if item:GetTimeAlive() < 8 then return false end
				if item.prefab == "mandrake" then return false end
				if noveggie and item.components.edible and item.components.edible.foodtype ~= FOODTYPE.MEAT then
					return false
				end
				if not item:IsOnValidGround() then
					return false
				end
				return inst.components.eater:CanEat(item) 
			end)
    end
    if target then
        return BufferedAction(inst, target, ACTIONS.EAT)
    end

    if not target and (not time_since_eat or time_since_eat > TUNING.PIG_MIN_POOP_PERIOD*2) then
        target = FindEntity(inst, SEE_FOOD_DIST, function(item) 
                if not item.components.shelf then return false end
                if not item.components.shelf.itemonshelf or not item.components.shelf.cantakeitem then return false end
                if noveggie and item.components.shelf.itemonshelf.components.edible and item.components.shelf.itemonshelf.components.edible.foodtype ~= FOODTYPE.MEAT then
                    return false
                end
                if not item:IsOnValidGround() then
                    return false
                end
                return inst.components.eater:CanEat(item.components.shelf.itemonshelf) 
            end)
    end

    if target then
        return BufferedAction(inst, target, ACTIONS.TAKEITEM)
    end

end


local function KeepChoppingAction(inst)
    return inst.components.follower.leader and inst.components.follower.leader:GetDistanceSqToInst(inst) <= KEEP_CHOPPING_DIST*KEEP_CHOPPING_DIST
end

local function StartChoppingCondition(inst)
    return inst.components.follower.leader and inst.components.follower.leader.sg and inst.components.follower.leader.sg:HasStateTag("chopping")
end


local function FindTreeToChopAction(inst)
    local target = FindEntity(inst, SEE_TREE_DIST, function(item) return item.components.workable and item.components.workable.action == ACTIONS.CHOP end)
    if target then
        return BufferedAction(inst, target, ACTIONS.CHOP)
    end
end

local function HasValidHome(inst)
    return inst.components.homeseeker and 
       inst.components.homeseeker.home and 
       inst.components.homeseeker.home:IsValid()
end

local function GoHomeAction(inst)
    if not inst.components.follower.leader and
        HasValidHome(inst) and
        not inst.components.combat.target then
            return BufferedAction(inst, inst.components.homeseeker.home, ACTIONS.GOHOME)
    end
end

local function GetLeader(inst)
    return inst.components.follower.leader 
end

local function GetHomePos(inst)
    return HasValidHome(inst) and inst.components.homeseeker:GetHomePos()
end

local function GetNoLeaderHomePos(inst)
    if GetLeader(inst) then
        return nil
    end
    return GetHomePos(inst)
end

local function RescueLeaderAction(inst)
    return BufferedAction(inst, GetLeader(inst), ACTIONS.UNPIN)
end

local function GetFaceTargetFn(inst)
    return inst.components.follower.leader
end

local function KeepFaceTargetFn(inst, target)
    return inst.components.follower.leader == target
end

local PigBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

-- Tests if 'Guy' has the Authority Symbol in hand.
local function GuyHasWilburnScepter(guy)
    if guy then
        return guy.components.inventory
            and guy.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            and guy.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS).prefab == "wilburnscepter"
    else
        return false
    end
end
-- Supposed to prevent pigs from attacking your target. It doesn't work so I'm not using it.
-- (HELP NEEDED !!!)
local function NoFight(inst)
    if inst and inst.components.combat then
        inst.components.combat.target = nil
        if inst.components.combat.retargettask ~= nil then
            inst.components.combat.retargettask:Cancel()
            inst.components.combat.retargettask = nil
        end
    else
        return
    end
end

function PigBrain:OnStart()
    --print(self.inst, "PigBrain:OnStart")
    local day = WhileNode( function() return TheWorld.state.isday end, "IsDay",
        PriorityNode{
            ChattyNode(self.inst, STRINGS.PIG_TALK_FIND_MEAT,
                DoAction(self.inst, FindFoodAction )),
            IfNode(function() return StartChoppingCondition(self.inst) end, "chop", 
                WhileNode(function() return KeepChoppingAction(self.inst) end, "keep chopping",
                    LoopNode{ 
                        ChattyNode(self.inst, STRINGS.PIG_TALK_HELP_CHOP_WOOD,
                            DoAction(self.inst, FindTreeToChopAction ))})),
            ChattyNode(self.inst, STRINGS.PIG_TALK_FOLLOWWILSON, 
                Follow(self.inst, GetLeader, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST)),
            IfNode(function() return GetLeader(self.inst) end, "has leader",
				ChattyNode(self.inst, STRINGS.PIG_TALK_FOLLOWWILSON,
					FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn ))),

            Leash(self.inst, GetNoLeaderHomePos, LEASH_MAX_DIST, LEASH_RETURN_DIST),

            -- Added a condition to the RunAway node. It prevents pigs from running away if the player
            --has the Authority Symbol in hand. Note that creatures following you will still back off.
            ChattyNode(self.inst, STRINGS.PIG_TALK_RUNAWAY_WILSON,
                RunAway(self.inst, "player", START_RUN_DIST, STOP_RUN_DIST, function(guy) return not GuyHasWilburnScepter(guy) end)),
            ChattyNode(self.inst, STRINGS.PIG_TALK_LOOKATWILSON,
                FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn)),
            Wander(self.inst, GetNoLeaderHomePos, MAX_WANDER_DIST)
        },.5)
        
    
    local night = WhileNode( function() return not TheWorld.state.isday end, "IsNight",
        PriorityNode{
            ChattyNode(self.inst, STRINGS.PIG_TALK_RUN_FROM_SPIDER,
                RunAway(self.inst, "spider", 4, 8)),
            ChattyNode(self.inst, STRINGS.PIG_TALK_FIND_MEAT,
                DoAction(self.inst, FindFoodAction )),
            RunAway(self.inst, "player", START_RUN_DIST, STOP_RUN_DIST, function(target) return ShouldRunAway(self.inst, target) end ),
            -- added the IfNode for the bell that calls pigmen out of their homes.
            -- this prevents them from going back home instantly after they get out.
            IfNode(function() return self.inst.cangobackhome end, "allowed to go home",
                ChattyNode(self.inst, STRINGS.PIG_TALK_GO_HOME,
                    DoAction(self.inst, GoHomeAction, "go home", true ))),
            ChattyNode(self.inst, STRINGS.PIG_TALK_FIND_LIGHT,
                FindLight(self.inst)),
            ChattyNode(self.inst, STRINGS.PIG_TALK_PANIC,
                Panic(self.inst)),
        },1)
    
    
    local root = 
        PriorityNode(
        {
            WhileNode( function() return self.inst.components.hauntable and self.inst.components.hauntable.panic end, "PanicHaunted", 
                ChattyNode(self.inst, STRINGS.PIG_TALK_PANICHAUNT,
                    Panic(self.inst))),
            WhileNode(function() return self.inst.components.health.takingfiredamage end, "OnFire",
				ChattyNode(self.inst, STRINGS.PIG_TALK_PANICFIRE,
					Panic(self.inst))),
            ChattyNode(self.inst, STRINGS.PIG_TALK_FIGHT,
                WhileNode( function() return self.inst.components.combat.target == nil or not self.inst.components.combat:InCooldown() end, "AttackMomentarily",
                    ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST) )),
            ChattyNode(self.inst, STRINGS.PIG_TALK_RESCUE,
                WhileNode( function() return GetLeader(self.inst) and GetLeader(self.inst).components.pinnable and GetLeader(self.inst).components.pinnable:IsStuck() end, "Leader Phlegmed",
                    DoAction(self.inst, RescueLeaderAction, "Rescue Leader", true) )),
            ChattyNode(self.inst, STRINGS.PIG_TALK_FIGHT,
                WhileNode( function() return self.inst.components.combat.target and self.inst.components.combat:InCooldown() end, "Dodge",
                    RunAway(self.inst, function() return self.inst.components.combat.target end, RUN_AWAY_DIST, STOP_RUN_AWAY_DIST) )),
            RunAway(self.inst, function(guy) return guy:HasTag("pig") and guy.components.combat and guy.components.combat.target == self.inst end, RUN_AWAY_DIST, STOP_RUN_AWAY_DIST ),
            ChattyNode(self.inst, STRINGS.PIG_TALK_ATTEMPT_TRADE,
                FaceEntity(self.inst, GetTraderFn, KeepTraderFn)),            
            day,
            night
        }, .5)
    
    self.bt = BT(self.inst, root)
    
end

return PigBrain
