local assets =
{
    Asset("ANIM", "anim/wilburnscepter.zip"),
   	Asset("ANIM", "anim/swap_wilburnscepter.zip"),

    Asset("IMAGE", "images/inventoryimages/wilburnscepter.tex"),
    Asset("ATLAS", "images/inventoryimages/wilburnscepter.xml"),
}

local function freezeLoyalty(owner)
    --This function doesn't really freeze loyalty time
    --but adds enough to prevent loyalty from decreasing.
    if owner.components.leader and owner.components.leader.followers then
        for k,v in pairs(owner.components.leader.followers) do
            if not k:HasTag("chester")
            and not k:HasTag("glommer")
            and not k:HasTag("catcoon")
            and not k:HasTag("chess") then
                k.components.follower:AddLoyaltyTime(1)
            end
        end
    end
end

local function onfinished(inst)
    inst:Remove()
end

local function onequip(inst, owner) 
    owner.AnimState:OverrideSymbol("swap_object", "swap_wilburnscepter", "swap_wilburnscepter")
    owner.AnimState:Show("ARM_carry") 
    owner.AnimState:Hide("ARM_normal") 

    --equipping the item adds a periodic task to freeze loyalty of all followers
    inst.task = inst:DoPeriodicTask (1, function() freezeLoyalty(owner) end)
end

local function onunequip(inst, owner) 
    owner.AnimState:Hide("ARM_carry") 
    owner.AnimState:Show("ARM_normal")

    --removes periodic task added on equipment
    inst.task:Cancel()
    inst.task = nil
end

local function onattack(inst, owner, target)
    --for targets that can be followers
    if target.components.follower then
        --all befriendable creatures
        if (target:HasTag("pig") and not inst:HasTag("guard"))
        or target:HasTag("manrabbit")
        or target:HasTag("rocky")
        or target:HasTag("catcoon")
        or (target:HasTag("spider") and owner:HasTag("spiderwhisperer"))
        or (target:HasTag("hound") and owner:HasTag("houndwhisperer")) then

            --make all current followers and the target non aggressive
            for k,v in pairs(owner.components.leader.followers) do
                if k.components.combat and k.components.follower then
                    k.components.combat:SetTarget(nil)
                end
            end
            target.components.combat:SetTarget(nil)

            --make the target a follower (with a special case for hounds)
            owner.components.leader:AddFollower(target)
            if target:HasTag("hound") then
                target:AddTag("companion")
            end

            --add loyalty time - specific to the Authority Symbol
            target.components.follower:AddLoyaltyTime(TUNING.WILBURNSCEPTER_PERSUASION)

            --play the friend sound
            inst.SoundEmitter:PlaySound("dontstarve/common/makeFriend")

            --entities say something to confirm friendship
            if target:HasTag("manrabbit") then                                          
                owner.components.talker:Say("Abracadabra!")
                target.components.talker:Say("YES MASTER.")
            elseif target:HasTag("rocky") then
                owner.components.talker:Say("Protect me!")
            elseif target:HasTag("pig") then
                owner.components.talker:Say("Now you do what I say!!")
                target.components.talker:Say("OKAY! OKAY!")
            elseif target:HasTag("catcoon") then
                owner.components.talker:Say("Come on little guy!")
            elseif target:HasTag("spider") then
                owner.components.talker:Say("Obey, spider!")
            elseif target:HasTag("hound") then
                owner.components.talker:Say("Be a good boy!")
            end

            --A few instants later, remake everyone non-agressive.
                --This can be useful if you have a follower that already initiated its attack animation,
                --and hitting the target after the moment you "persuade" it,
                --which would remake the target aggressive and lead to a fight among your friends.
                --This isn't a full-proof solution though, it's rather a very shy way of solving the problem.
            inst:DoTaskInTime( 0.2, function()
                for k,v in pairs(owner.components.leader.followers) do
                    if k.components.combat and k.components.follower then
                        k.components.combat:SetTarget(nil)
                    end
                end
                target.components.combat:SetTarget(nil)
            end )
        end
    end
end

local function fn(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()

    inst.entity:AddNetwork()
    
    inst.entity:AddSoundEmitter()
    MakeInventoryPhysics(inst)

    anim:SetBank("wilburnscepter")
    anim:SetBuild("wilburnscepter")
    anim:PlayAnimation("idle")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()
    
    inst:AddComponent("weapon")
    inst.components.weapon:SetOnAttack(onattack)
    inst.components.weapon:SetDamage(1)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.WILBURNSCEPTER_USES)
    inst.components.finiteuses:SetUses(TUNING.WILBURNSCEPTER_USES)
    inst.components.finiteuses:SetOnFinished( onfinished )
    
    inst:AddComponent("inspectable")
    
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "wilburnscepter"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/wilburnscepter.xml"
    
    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip( onequip )
    inst.components.equippable:SetOnUnequip( onunequip )

    MakeHauntableLaunch(inst)
    
    return inst
end

return Prefab( "common/inventory/wilburnscepter", fn, assets) 