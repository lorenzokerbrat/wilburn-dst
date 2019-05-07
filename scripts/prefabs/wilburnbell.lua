local assets =
{
	Asset("ANIM", "anim/bell.zip"),
    Asset("IMAGE", "images/inventoryimages/wilburnbell.tex"),
    Asset("ATLAS", "images/inventoryimages/wilburnbell.xml"),
}

local function SetTimer(inst)
    -- this boolean value is set to false to signify "you're not allowed to go back home"
    -- the value is used in brains/new_pigbrain.lua in an if statement, to prevent them from going home.
    inst.cangobackhome = false
    
    if inst.task then
        inst.task:Cancel()
        inst.task = nil
    end
    -- the value is set back to true after a while. This is done by assigning a task to inst, so it has to be cleaned up before.
    inst.task = inst:DoTaskInTime(TUNING.WILBURNBELL_EFFECT_LENGTH, function(inst)
        inst.cangobackhome = true
    end)
end

-- copy of the LightsOff function in pighouse.lua.
local function PigHouseLightsOff(inst)
    inst.Light:Enable(false)
    inst.AnimState:PlayAnimation("idle", true)
    inst.SoundEmitter:PlaySound("dontstarve/pig/pighut_lightoff")
    inst.lightson = false
end

local function OnPlayed(musician)
    -- the game will look for pigs and pig houses in a certain perimeter around the user of the bell, 
    local x,y,z = musician.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x,y,z, TUNING.WILBURNBELL_EFFECT_RANGE)
    for k,v in pairs(ents) do
        if v.prefab == "pighouse" then
            -- each pig will be released from his house (don't forget to turn off the lights to save the planet),
            PigHouseLightsOff(v)
            v.components.spawner:ReleaseChild()
            -- and a timer will be applied to him, preventing him to go home for a while.
            SetTimer(v.components.spawner.child)
        end
        if v.prefab == "pigman" then
            -- each pig around will also be applied the same timer if they're already out.
            SetTimer(v)
        end
    end
end

local function OnPutInInv(inst, owner)
    if owner.prefab == "mole" or owner.prefab == "krampus" then
        inst.SoundEmitter:PlaySound("dontstarve/pig/PigKingThrowGold")
        OnPlayed(owner)
        if inst.components.finiteuses then inst.components.finiteuses:Use() end
    end
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()

    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("bell")
	inst.AnimState:SetBuild("bell")
	inst.AnimState:PlayAnimation("idle")

    if not TheWorld.ismastersim then
        return inst
    end
    inst.entity:SetPristine()

	inst:AddTag("bell")
    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/wilburnbell.xml"

    inst:AddTag("molebait")
    inst:ListenForEvent( "onstolen", function(inst, data) 
        if data.thief.components.inventory then
            data.thief.components.inventory:GiveItem(inst)
        end 
    end)
    inst.components.inventoryitem:SetOnPutInInventoryFn(OnPutInInv)
    
    inst:AddComponent("instrument")
    inst.components.instrument.onplayed = OnPlayed

    inst:AddComponent("tool")
    inst.components.tool:SetAction(ACTIONS.PLAY)
    
    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.WILBURNBELL_USES)
    inst.components.finiteuses:SetUses(TUNING.WILBURNBELL_USES)
    inst.components.finiteuses:SetConsumption(ACTIONS.PLAY, 1)

    MakeHauntableLaunch(inst)
    inst:AddComponent("hauntable")
    inst.components.hauntable:SetOnHauntFn( OnPlayed )

	return inst
end

return Prefab("wilburnbell", fn, assets)
