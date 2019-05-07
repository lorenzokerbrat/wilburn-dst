local MakePlayerCharacter = require "prefabs/player_common"

local assets = {
    Asset( "ANIM", "anim/wilburn.zip" ),
     Asset("ANIM", "anim/ghost_wilburn_build.zip"),
}

local prefabs = {
    "wilburnbell",
    "wilburnscepter",
    "wilburncrown",
}

local function OnEat(inst, food)

    --these operations only ADD UP to the normal operation that is done when the character eats.
    if food.entity:HasTag("preparedfood") then
        --added to total gain.
        inst.components.hunger:DoDelta(food.components.edible:GetHunger(inst) * TUNING.PREPARED_FOOD_BONUS)
    else
        --substracted from total gain.
        inst.components.hunger:DoDelta(-food.components.edible:GetHunger(inst) * TUNING.NON_PREPARED_FOOD_MALUS)
    end

end

local function sanityDrops(inst, dt)

    if inst.components.leader then
        --checking if Chester is there
        local hasChester = false
        for k,v in pairs(inst.components.leader.followers) do
            if k:HasTag("chester") then
                hasChester = true
            end
        end

        --Decrease sanity if Wilburn has no follower OR only Chester
        if inst.components.leader.numfollowers == 0
        or (inst.components.leader.numfollowers == 1 and hasChester) then
            inst.components.sanity.dapperness = -TUNING.DAPPERNESS_SMALL
        else
            inst.components.sanity.dapperness = 0
        end
    end

end

local function common_postinit(inst)
    inst.soundsname = "wilburn"
    inst:AddTag("ghostwithhat")

--SANITY DROPS
    inst:DoPeriodicTask(0.2, function() sanityDrops(inst, 0.2) end)
end

local function master_postinit(inst)
	inst.MiniMapEntity:SetIcon( "wilburn.tex" )

--CAN CRAFT TWO SPECIAL ITEMS
    inst:AddTag("wilburn")

    inst.components.health:SetMaxHealth(TUNING.WILBURN_HEALTH)
    inst.components.sanity:SetMax(TUNING.WILBURN_SANITY)
    inst.components.hunger:SetMax(TUNING.WILBURN_HUNGER)

--WILBURN PREFERS WELL-COOKED FOOD
    inst.components.eater:SetOnEatFn(OnEat)

--DAMAGE MULTIPLIER
    inst.components.combat.damagemultiplier = TUNING.WENDY_DAMAGE_MULT
end

STRINGS.CHARACTER_TITLES.wilburn = "The Heir"
STRINGS.CHARACTER_NAMES.wilburn = "Wilburn"
STRINGS.CHARACTER_DESCRIPTIONS.wilburn = "*Is used to a much easier life.\n*Will rule everything.\n*Hates ruling nothing."
STRINGS.CHARACTER_QUOTES.wilburn = "\"You stay with me. You fight. I watch.\""
STRINGS.CHARACTERS.WILBURN = require "speech_wilburn"

STRINGS.NAMES.WILBURN = "Wilburn"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.WILBURN = 
{
    GENERIC = "It's Wilburn!",
    ATTACKER = "Go play somewhere else, kid!",
    MURDERER = "Wealth really made you evil.",
    REVIVER = "Well... Sure, I owe you one.",
    GHOST = "A heart? But he never had one in the first place!",
}

return MakePlayerCharacter("wilburn", prefabs, assets, common_postinit, master_postinit)