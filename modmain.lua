-- VERSION 0.9.8.1 : "Less lines of code"

local require = GLOBAL.require

-- DST specific variable.
local ThePlayer = GLOBAL.ThePlayer
--

local GetClosestInstWithTag = GLOBAL.GetClosestInstWithTag

local FindEntity = GLOBAL.FindEntity

local IsDLCEnabled = GLOBAL.IsDLCEnabled
local REIGN_OF_GIANTS = GLOBAL.REIGN_OF_GIANTS

local STRINGS = GLOBAL.STRINGS
local EQUIPSLOTS = GLOBAL.EQUIPSLOTS

local wilson_health = 150 --same as in tuning.lua
local seg_time = 30 --same as in tuning.lua
local total_day_time = seg_time*16 --same as in tuning.lua

TUNING = GLOBAL.TUNING

TUNING.WILBURN_HEALTH = 150
TUNING.WILBURN_SANITY = 100
TUNING.WILBURN_HUNGER = 150

TUNING.WILBURN_PERSUASION_MULT = 2

TUNING.PREPARED_FOOD_BONUS = 0.1
TUNING.NON_PREPARED_FOOD_MALUS = 0.1

TUNING.WILBURNSCEPTER_PERSUASION = 200
TUNING.WILBURNSCEPTER_USES = 35

TUNING.WILBURNBELL_EFFECT_RANGE = 30
TUNING.WILBURNBELL_EFFECT_LENGTH = 15
TUNING.WILBURNBELL_USES = 10

TUNING.SPIDER_LOYALTY_PER_HUNGER = total_day_time/25 --same as in tuning.lua
TUNING.HOUND_LOYALTY_PER_HUNGER = total_day_time/25

Assets = {
    Asset( "IMAGE", "images/saveslot_portraits/wilburn.tex" ),
    Asset( "ATLAS", "images/saveslot_portraits/wilburn.xml" ),

    Asset( "IMAGE", "images/selectscreen_portraits/wilburn.tex" ),
    Asset( "ATLAS", "images/selectscreen_portraits/wilburn.xml" ),

    Asset( "IMAGE", "bigportraits/wilburn.tex" ),
    Asset( "ATLAS", "bigportraits/wilburn.xml" ),

    Asset( "IMAGE", "images/map_icon/wilburn.tex" ),
    Asset( "ATLAS", "images/map_icon/wilburn.xml" ),

    -- These are DST-only, don't forget them.
    Asset( "IMAGE", "images/avatars/avatar_wilburn.tex" ),
    Asset( "ATLAS", "images/avatars/avatar_wilburn.xml" ),

    Asset( "IMAGE", "images/avatars/avatar_ghost_wilburn.tex" ),
    Asset( "ATLAS", "images/avatars/avatar_ghost_wilburn.xml" ),
    --

    Asset("SOUNDPACKAGE", "sound/wilburn.fev"),
    Asset("SOUND", "sound/wilburn_bank56.fsb"),
}

PrefabFiles = {
    "wilburn",
    "wilburnbell",
    "wilburnscepter",
    "wilburncrown",
}



--*******--
--RECIPES--
--*******--

local Recipe = GLOBAL.Recipe
local RECIPETABS = GLOBAL.RECIPETABS
local TECH = GLOBAL.TECH

-- Declaring Wilburn's own recipes as locals
-- BEFORE adding them to the mod's new recipes.
-- This allows me to assign their crafting tab images here as well.
local wilburnbell_Recipe = Recipe("wilburnbell",
    { Ingredient("pigskin", 1),
      Ingredient("nitre", 1),
      Ingredient("marble", 1) },
    RECIPETABS.SURVIVAL, TECH.SCIENCE_ONE, nil, nil, nil, nil, "wilburn")

local wilburnscepter_Recipe = Recipe("wilburnscepter",
    { Ingredient("goldnugget", 4),
      Ingredient("purplegem", 1),
      Ingredient("nightmarefuel", 4)},
    RECIPETABS.MAGIC, TECH.MAGIC_TWO, nil, nil, nil, nil, "wilburn")

local wilburncrown_Recipe = Recipe("wilburncrown",
    { Ingredient("goldnugget", 8),  
      Ingredient("tentaclespike", 1),
      Ingredient("deerclops_eyeball", 1) },
    RECIPETABS.MAGIC, TECH.MAGIC_TWO, nil, nil, nil, nil, "wilburn")

-- Adding them to the mod's new recipes.
local recipes = {
    wilburnbell_Recipe,
    wilburnscepter_Recipe,
    wilburncrown_Recipe,
}

-- Assigning them their crafting tab images.
wilburnbell_Recipe.atlas = "images/inventoryimages/wilburnbell.xml"
wilburnscepter_Recipe.atlas = "images/inventoryimages/wilburnscepter.xml"
wilburncrown_Recipe.atlas = "images/inventoryimages/wilburncrown.xml"


--****--
--MISC--
--****--

RemapSoundEvent( "dontstarve/characters/wilburn/death_voice", "wilburn/characters/wilburn/death_voice" )
RemapSoundEvent( "dontstarve/characters/wilburn/hurt", "wilburn/characters/wilburn/hurt" )
RemapSoundEvent( "dontstarve/characters/wilburn/talk_LP", "wilburn/characters/wilburn/talk_LP" )

STRINGS.NAMES.WILBURNBELL = "Call of Dirty"
STRINGS.RECIPE_DESC.WILBURNBELL = "Step out, little piggies..."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.WILBURNBELL = "It should call them out, I suppose."

STRINGS.NAMES.WILBURNSCEPTER = "Authority Symbol"
STRINGS.RECIPE_DESC.WILBURNSCEPTER = "Has the magic power to make friends!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.WILBURNSCEPTER = "It can magically convince creatures to join me."

STRINGS.NAMES.WILBURNCROWN = "Overlord's Crown"
STRINGS.RECIPE_DESC.WILBURNCROWN = "A crown to rule them all."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.WILBURNCROWN = "It's a bit too big for me."

table.insert(GLOBAL.CHARACTER_GENDERS.MALE, "wilburn")

AddMinimapAtlas("images/map_icon/wilburn.xml")



--********************************--
--ADDING NEW VERSIONS OF FUNCTIONS--
--********************************--

--*** COMPONENTS ***--

------- COMBAT -------

-- Here I want to add a condition in the function that tells if a creature should attack another creature.
-- it's basically "if the player is Wilburn, then his followers should never attack one another".
-- that situation would never happen with any character, except for Wilburn if he uses his crown and
-- recruits two creatures that would naturally fight each other, such as pigmen and spiders.

AddComponentPostInit("combat", function(inst)
    --(I don't know whether I should change SuggestTarget or TryRetarget.)
    local old_SuggestTarget = inst.SuggestTarget
    function inst:SuggestTarget(target)

        if not self.target and target ~= nil
        and target.prefab == "wilburn"
        and (self.inst.components.follower and target.components.follower
        and (self.inst.components.follower.leader and target.components.follower.leader
        and (self.inst.components.follower.leader == target.components.follower.leader))) then
            return false
        end
        
        return old_SuggestTarget(self, target)
    end
end)

--TRADER.LUA
--All I did there was adding a parameter 'giver' to CanAccept. The base game doesn't have that.
--I end up with the same functions as they appear in the Reign Of Giants version of trader.lua.
local Trader = require "components/trader"
    
local Base_Trader_CanAccept = Trader.CanAccept
    function Trader:CanAccept(item , giver)
        return self.enabled and (not self.test or self.test(self.inst, item, giver))
    end

local Base_Trader_AcceptGift = Trader.AcceptGift
    function Trader:AcceptGift( giver, item )
        if not self.enabled then
            return false
        end
        
        --CanAccept is called here
        if self:CanAccept(item, giver) then

            if item.components.stackable and item.components.stackable.stacksize > 1 then
                item = item.components.stackable:Get()
            else
                item.components.inventoryitem:RemoveFromOwner()
            end
            
            if self.inst.components.inventory then
                self.inst.components.inventory:GiveItem(item)
            else
                item:Remove()
            end
            
            if self.onaccept then
                self.onaccept(self.inst, giver, item)
            end
            
            self.inst:PushEvent("trade", {giver = giver, item = item})

            return true
        end

        if self.onrefuse then
            self.onrefuse(self.inst, giver, item)
        end
    end


--*** BRAINS ***--

--PIGBRAIN.LUA
--Only change I made to the pigs' brain is that they won't run away from a character who has
--the Authority Symbol in hand. This will make recruiting them with the scepter less tricky and awkward.
AddPrefabPostInit("pigman", function(inst)
    local new_brain = require "brains/new_pigbrain"
    inst:SetBrain(new_brain)
end)


--*** PREFABS ***--

------- PIGMEN -------

AddPrefabPostInit("pigman", function(inst)

    if not GLOBAL.TheWorld.ismastersim then
        return inst
    end

--"trader"
    --In case you want to know what I'm doing in the next line, I store in a variable the original version
    --of the function that I want to change, so I can still use it when I've done what I wanted.
    --In this simple example, I do the few things that only happen IF you are Wilburn, and then I call the
    --original function that does what happens for every character.
    --If you're not Wilburn, then I ONLY call the original function. So the change only happens if I play as
    --my character (the game doesn't know that in modmain.lua !)

    --There are a lot of cases where it's not as simple as here and I just can't find a way to make use of
    --the original function. Like up there in the component post inits. That means I am forced to copy-paste
    --their contents. Which is bad because if a future Don't Starve update changes the original functions,
    --the changes will not be applied in my mod, since I override the original with an old version of the
    --original.

    --tl;dr This code for the function down there is update-proof and you should always do this in a mod !!!

    local old_onaccept = inst.components.trader.onaccept
    --Now that the original "old" function is stored, I can edit the prefab directly.
    inst.components.trader.onaccept = (function(inst, giver, item)

        if giver.prefab == "wilburn" and item.components.edible then
            --here I will put all the things that need to happen when a pig accepts an item from Wilburn.
            if item.components.edible.foodtype == "MEAT" or item.components.edible.foodtype == "HORRIBLE"
            and giver.components.leader and not inst:HasTag("guard") then
                inst.components.combat:SetTarget(nil)
                -- persuasion multiplier
                -- (applied in a weird way : the -1 counters the loyalty time added later, in old_onaccept.)
                inst.components.follower:AddLoyaltyTime(item.components.edible:GetHunger()
                    * TUNING.PIG_LOYALTY_PER_HUNGER * (TUNING.WILBURN_PERSUASION_MULT -1))

            --Recruiting a creature as Wilburn often leads to messy situations.
            --First, because the scepter item works by attacking a creature to recruit them,
                --so it will make your target aggressive towards you and your followers towards your target.
                --This issue is solved directly in the scepter's code.

            --Second, because if you wear the crown and befriend both monsters and non-monsters, they will
                --already be fighting each other before you can recruit them. This is what the next lines fix :

                -- if you are wearing the crown (which means you have the houndwhisperer tag),
                if giver:HasTag("houndwhisperer") then
                    -- your team should also stop attacking the creature you're recruiting.
                    for k,v in pairs(giver.components.leader.followers) do
                        if k.components.combat and k.components.follower then
                            k.components.combat:SetTarget(nil)
                        end
                    end
                end
            end
        end

        --Then, we call the usual onaccept function that we stored before. (At this point nothing has
        --happened yet for any character in the game except Wilburn.)
        return old_onaccept(inst, giver, item)
    end)

--"sanityaura"
    local old_aurafn = inst.components.sanityaura.aurafn
    inst.components.sanityaura.aurafn = (function(inst, observer)

        --This reduces the sanity bonus that Wilburn receives when he is close to his PIG followers. (It's a nerf)
        if observer.prefab == "wilburn"
        and inst.components.werebeast and not inst.components.werebeast:IsInWereState() then
            return old_aurafn(inst, observer) / 3
        end

        return old_aurafn(inst, observer)
    end)

--"cangobackhome" : I use this new boolean value for my bell item.
-- I add it to the initialization of a pigman, because each pig needs to have his own cangobackhome.
    inst.cangobackhome = true
end)

------- BUNNYMEN -------

AddPrefabPostInit("bunnyman", function(inst)

    if not GLOBAL.TheWorld.ismastersim then
        return inst
    end

--"trader"
    local old_onaccept = inst.components.trader.onaccept
    inst.components.trader.onaccept = (function(inst, giver, item)

        if giver.prefab == "wilburn"
        and item.components.edible and (item.prefab == "carrot" or item.prefab == "carrot_cooked")
        and giver.components.leader then
            inst.components.combat:SetTarget(nil)
            inst.components.follower:AddLoyaltyTime(TUNING.RABBIT_CARROT_LOYALTY * (TUNING.WILBURN_PERSUASION_MULT - 1))
            if giver:HasTag("houndwhisperer") then
                for k,v in pairs(giver.components.leader.followers) do
                    if k.components.combat and k.components.follower then
                        k.components.combat:SetTarget(nil)
                    end
                end
            end
        end

        return old_onaccept(inst, giver, item)
    end)
end)

------- ROCK LOBSTERS -------

AddPrefabPostInit("rocky", function(inst)

    if not GLOBAL.TheWorld.ismastersim then
        return inst
    end

--"trader"
    local old_onaccept = inst.components.trader.onaccept
    inst.components.trader.onaccept = (function(inst, giver, item)

        if giver.prefab == "wilburn"
        and item.components.edible and item.components.edible.foodtype == "ELEMENTAL"
        and giver.components.leader then
            inst.components.combat:SetTarget(nil)
            inst.components.follower:AddLoyaltyTime(TUNING.ROCKY_LOYALTY * (TUNING.WILBURN_PERSUASION_MULT - 1))
            if giver:HasTag("houndwhisperer") then
                for k,v in pairs(giver.components.leader.followers) do
                    if k.components.combat and k.components.follower then
                        k.components.combat:SetTarget(nil)
                    end
                end
            end
        end

        return old_onaccept(inst, giver, item)
    end)
end)

------- SPIDERS -------

local function Spider_General_PostInit(inst)
--this big function is the post init function that I will apply to both spiders and spider warriors (different entities).
--so its whole purpose is to avoid writing the same big chunk of code twice.

    if not GLOBAL.TheWorld.ismastersim then
        return inst
    end

--"combat"
    local old_keeptargetfn = inst.components.combat.keeptargetfn
    inst.components.combat:SetKeepTargetFunction(function(inst, target)
        --Here we add a bit of condition to prevent a spider that follows the player
        --from being hostile towards a creature that also follows the player.
        return old_keeptargetfn(inst, target)
            and not (inst.components.follower and inst.components.follower.leader == ThePlayer and target:HasTag("companion"))
    end)

--"follower"
    inst.components.follower.maxfollowtime = TUNING.TOTAL_DAY_TIME

--"trader"
    --In RoG.
    if not inst.components.trader then
        --Not in RoG.
        inst:AddComponent("trader")
    end

    local old_tradertest = inst.components.trader.test
    inst.components.trader:SetAcceptTest(function(inst, item, giver)
        --this function will make spiders accept or refuse items from the player.
        if giver.prefab == "wilburn" then
            --if we are Wilburn then we have to use the current version of the trader test.
            -- *** this means that if an update changes this function, Wilburn will be broken.
            if not giver:HasTag("spiderwhisperer") then
                --the spiderwhisperer tag is normally given to Webber only.
                --Wilburn has this tag only when he wears the Overlord's Crown.
                return false
            end
            if inst.components.sleeper:IsAsleep() then
                return false
            end
            if inst.components.eater:CanEat(item) then
                return true
            end
        else
            --if we are not Wilburn then we stick to what's in the game files.
            if old_tradertest then
                return old_tradertest(inst, item, giver)
            end
        end
    end)

    local old_onaccept = inst.components.trader.onaccept
    inst.components.trader.onaccept = (function (inst, giver, item)
        if giver.prefab == "wilburn" then
            if inst.components.eater:CanEat(item) then
                local playedfriendsfx = false
                inst.components.combat:SetTarget(nil)
                if giver.components.leader then
                    inst.SoundEmitter:PlaySound("dontstarve/common/makeFriend")
                    playedfriendsfx = true
                    giver.components.leader:AddFollower(inst)
                    local loyaltyTime = item.components.edible:GetHunger()
                        * TUNING.SPIDER_LOYALTY_PER_HUNGER * TUNING.WILBURN_PERSUASION_MULT
                    for k,v in pairs(giver.components.leader.followers) do
                        if k.components.combat and k.components.follower then
                            k.components.combat:SetTarget(nil)
                        end
                    end
                    inst.components.follower:AddLoyaltyTime(loyaltyTime)
                end
            end

        else
            --Not in RoG
            if old_onaccept then
                --In RoG
                return old_onaccept(inst, giver, item)
            end
        end
    end)

    local old_onrefuse = inst.components.trader.onrefuse
    inst.components.trader.onrefuse = (function(inst, item)
        --Not in RoG
        if old_onrefuse then
            --In RoG
            return old_onrefuse(inst, item)
        else
            --this is the RoG function copy-pasted. I don't really have a choice here. I can't tell the game
            --to use the original function if you didn't buy RoG and you don't even have the file...
            inst.sg:GoToState("taunt")
            if inst.components.sleeper:IsAsleep() then
                inst.components.sleeper:WakeUp()
            end

        end
    end)

--"sanityaura"
    local old_aura = inst.components.sanityaura.aura -- not RoG
    local old_aurafn = inst.components.sanityaura.aurafn -- RoG
    inst.components.sanityaura.aurafn = (function(inst, observer)
        if observer:HasTag("spiderwhisperer") then
            --if the observer is Webber or Wilburn with his crown,
            --(the spiderwhisperer tag is common to them in that case) then no effect on aura.
            return 0
        end
        if old_aura then
            --Not in RoG
            return old_aura
        end
        if old_aurafn then
            --In RoG
            return old_aurafn
        end
    end)
end

AddPrefabPostInit("spider", Spider_General_PostInit)
AddPrefabPostInit("spider_warrior", Spider_General_PostInit)

AddPrefabPostInit("spider_hider", Spider_General_PostInit)
AddPrefabPostInit("spider_spitter", Spider_General_PostInit)
AddPrefabPostInit("spider_dropper", Spider_General_PostInit)

------- HOUNDS -------

    -- *** Functions giving hounds the ability to "trade" items.
    -- Hounds normally don't have that so I just add them, based on how they look in other prefabs.
    local function Hound_ShouldAcceptItem(inst, item, giver)
        --added the tag 'houndwhisperer' for Wilburn (same as spiderwhisperer for Webber).
        --just like the spiderwhisperer one, he has it only when he wears the Overlord's Crown.
        if not giver:HasTag("houndwhisperer") then
            return false
        end
        if inst.components.sleeper:IsAsleep() then
            return false
        end
        if inst.components.eater:CanEat(item) then
            return true
        end
    end
    local function Hound_OnGetItemFromPlayer(inst, giver, item)
        if inst.components.eater:CanEat(item) then  
            local playedfriendsfx = false
            if giver.components.leader then
                inst.SoundEmitter:PlaySound("dontstarve/common/makeFriend")
                playedfriendsfx = true
                inst.components.combat:SetTarget(nil)
                giver.components.leader:AddFollower(inst)
                --the companion tag already exists in the game : it will mark befriended hounds for Wilburn.
                --Note: McTusk has "pet_hound"s instead of "companion"s. It has to be different.
                inst:AddTag("companion")
                for k,v in pairs(giver.components.leader.followers) do
                    if k.components.combat and k.components.follower then
                        k.components.combat:SetTarget(nil)
                    end
                end

                inst.components.follower:AddLoyaltyTime(item.components.edible:GetHunger() * TUNING.HOUND_LOYALTY_PER_HUNGER)
            end
        end
    end
    local function Hound_OnRefuseItem(inst, item)
        if inst.components.sleeper:IsAsleep() then
            inst.components.sleeper:WakeUp()
        end
    end

local function Hound_General_PostInit(inst)

    if not GLOBAL.TheWorld.ismastersim then
        return inst
    end

--"combat"
    local old_targetfn = inst.components.combat.targetfn
    inst.components.combat:SetRetargetFunction(3, function(inst)
        if inst:HasTag("companion") then
            --this will be the retarget function for companion hounds.
            return FindEntity(inst, TUNING.HOUND_FOLLOWER_TARGET_DIST, function(guy)
                return not guy:HasTag("wall")
                    and not guy:HasTag("houndmound")
                    and not (guy:HasTag("hound") or guy:HasTag("houndfriend"))
                    --With this line, the hound will not retarget its leader. (unfortunately there is still a bug)
                    and not (inst.components.follower and inst.components.follower.leader
                            and guy == inst.components.follower.leader)
                    and inst.components.combat:CanTarget(guy)
            end)
        else
            return old_targetfn(inst)
        end
    end)

--"follower"
    if not inst.components.follower then
        inst:AddComponent("follower")
    end
    inst.components.follower.maxfollowtime = TUNING.TOTAL_DAY_TIME * 2.5

--"trader"
    if not inst.components.trader then
        inst:AddComponent("trader")
    end
    inst.components.trader:SetAcceptTest(Hound_ShouldAcceptItem)
    inst.components.trader.onaccept = Hound_OnGetItemFromPlayer
    inst.components.trader.onrefuse = Hound_OnRefuseItem

--"sleeper"
    if GLOBAL.TheWorld.ismastersim then
        local old_sleeptestfn = inst.components.sleeper.sleeptestfn
        inst.components.sleeper:SetSleepTest(function(inst)
            if not inst:HasTag("companion") then
                return old_sleeptestfn(inst)
            else
                --They're very cute when they sleep.
                return not GLOBAL.TheWorld.state.isday
                    and not (inst.components.combat and inst.components.combat.target)
                    and not (inst.components.burnable and inst.components.burnable:IsBurning() )
                    and (not inst.components.homeseeker or inst:IsNear(inst.components.homeseeker.home, SLEEP_NEAR_HOME_DISTANCE))
            end
        end)
    end

--"sanityaura"
    local old_sanityaura = inst.components.sanityaura.aura
    inst.components.sanityaura.aurafn = (function(inst)
        if inst:HasTag("companion") then
            --reduce the insanity aura of follower hounds from MED to SMALL.
            return -TUNING.SANITYAURA_SMALL
        end
        return old_sanityaura
    end)

--"saving game"
    local old_OnSave = inst.OnSave
    inst.OnSave = (function(inst, data)
        --the OnSave function saves some information about the hound for the next time we load the game.
        --so I add an informative boolean, telling whether the hound was a follower or not at the moment we saved.
        data.iscompanion = inst:HasTag("companion")
        return old_OnSave(inst, data)
    end)
    local old_OnLoad = inst.OnLoad
    inst.OnLoad = (function(inst, data)
        if data then 
            if data.iscompanion then
                inst:AddTag("companion")
                if inst.sg then
                    inst.sg:GoToState("idle")
                end
            else
                return old_OnLoad(inst, data)
            end
        end
    end)
end

AddPrefabPostInit("hound", Hound_General_PostInit)
AddPrefabPostInit("firehound", Hound_General_PostInit)
AddPrefabPostInit("icehound", Hound_General_PostInit)

------- YELLOW AMULET -------

AddPrefabPostInit("yellowamulet", function(inst)

    if not GLOBAL.TheWorld.ismastersim then
        return inst
    end

    -- ensuring that unequipping Magiluminescence doesn't remove the Overlord Crown's new bloom effect.
    -- also, it seems that unequipping the amulet while being under the glow berry effect does remove the bloom effect,
    -- so I'm fixing that too because why not.
    -- (I don't think I'll make a new mod just for fixing that... you can if you want.)
    local old_onunequipfn = inst.components.equippable.onunequipfn
    inst.components.equippable:SetOnUnequip(function(inst, owner)
        local headitem = nil
        if owner.components.inventory and owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD) then
            headitem = owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD).prefab
        end

        if not (headitem and headitem == "wilburncrown") and not owner.wormlight then
            return old_onunequipfn(inst, owner)
        else
            -- onunequip without the Bloom effect clearing.
            owner.AnimState:ClearOverrideSymbol("swap_body")
            if inst.components.fueled then
                inst.components.fueled:StopConsuming()
            end
            inst.Light:Enable(false)
        end
    end)
end)



-- *** STATEGRAPHS *** --

local State = GLOBAL.State
local Action = GLOBAL.Action
local ActionHandler = GLOBAL.ActionHandler
local TimeEvent = GLOBAL.TimeEvent
local EventHandler = GLOBAL.EventHandler
local ACTIONS = GLOBAL.ACTIONS
local FRAMES = GLOBAL.FRAMES

-- Changing the bell ringing stategraph handler to add Wilburn's bell.
local bell_handler = ActionHandler(ACTIONS.PLAY, function(inst, action)
    if action.invobject then
        if action.invobject:HasTag("flute") then
            return "play_flute"
        elseif action.invobject:HasTag("horn") then
            return "play_horn"
        elseif action.invobject:HasTag("bell") then
            if action.invobject.prefab == "wilburnbell" then
                return "play_wilburnbell"
            end
            return "play_bell"
        end
    end
end)

local wilburnbell_state = State{
    name = "play_wilburnbell",
    tags = {"doing", "playing"},
    
    onenter = function(inst)
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("bell")
        inst.AnimState:OverrideSymbol("bell01", "bell", "bell01")
        inst.AnimState:Show("ARM_normal")
        if inst.components.inventory.activeitem and inst.components.inventory.activeitem.components.instrument then
            inst.components.inventory:ReturnActiveItem()
        end
    end,
    
    onexit = function(inst)
        if inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
            inst.AnimState:Show("ARM_carry")
            inst.AnimState:Hide("ARM_normal")
        end
    end,
    
    timeline=
    {
        TimeEvent(15*FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/pig/PigKingThrowGold")
        end),

        TimeEvent(30*FRAMES, function(inst)
            inst:PerformBufferedAction()
        end),
    },
    
    events=
    {
        EventHandler("animover", function(inst)
            inst.sg:GoToState("idle")
        end),
    },
}

AddStategraphActionHandler("wilson", bell_handler)
AddStategraphState("wilson", wilburnbell_state)

--********************--

AddModCharacter("wilburn")