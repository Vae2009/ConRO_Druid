ConRO.Druid = {};
ConRO.Druid.CheckTalents = function()
end
ConRO.Druid.CheckPvPTalents = function()
end
local ConRO_Druid, ids = ...;

function ConRO:EnableRotationModule(mode)
	mode = mode or 0;
	self.ModuleOnEnable = ConRO.Druid.CheckTalents;
	self.ModuleOnEnable = ConRO.Druid.CheckPvPTalents;
	if mode == 0 then
		self.Description = "Druid [No Specialization Under 10]";
		self.NextSpell = ConRO.Druid.Under10;
		self.ToggleHealer();
	end;
	if mode == 1 then
		self.Description = "Druid [Balance - Caster]";
		if ConRO.db.profile._Spec_1_Enabled then
			self.NextSpell = ConRO.Druid.Balance;
			self.ToggleDamage();
			ConROWindow:SetAlpha(ConRO.db.profile.transparencyWindow);
			ConRODefenseWindow:SetAlpha(ConRO.db.profile.transparencyWindow);
		else
			self.NextSpell = ConRO.Druid.Disabled;
			self.ToggleHealer();
			ConROWindow:SetAlpha(0);
			ConRODefenseWindow:SetAlpha(0);
		end
	end;
	if mode == 2 then
		self.Description = "Druid [Feral - Melee]";
		if ConRO.db.profile._Spec_2_Enabled then
			self.NextSpell = ConRO.Druid.Feral;
			self.ToggleDamage();
			ConROWindow:SetAlpha(ConRO.db.profile.transparencyWindow);
			ConRODefenseWindow:SetAlpha(ConRO.db.profile.transparencyWindow);
		else
			self.NextSpell = ConRO.Druid.Disabled;
			self.ToggleHealer();
			ConROWindow:SetAlpha(0);
			ConRODefenseWindow:SetAlpha(0);
		end
	end;
	if mode == 3 then
		self.Description = "Druid [Guardian - Tank]";
		if ConRO.db.profile._Spec_3_Enabled then
			self.NextSpell = ConRO.Druid.Guardian;
			self.ToggleDamage();
			self.BlockAoE();
			ConROWindow:SetAlpha(ConRO.db.profile.transparencyWindow);
			ConRODefenseWindow:SetAlpha(ConRO.db.profile.transparencyWindow);
		else
			self.NextSpell = ConRO.Druid.Disabled;
			self.ToggleHealer();
			ConROWindow:SetAlpha(0);
			ConRODefenseWindow:SetAlpha(0);
		end
	end;
	if mode == 4 then
		self.Description = "Druid [Restoration - Healer]";
		if ConRO.db.profile._Spec_4_Enabled then
			self.NextSpell = ConRO.Druid.Restoration;
			self.ToggleHealer();
			ConROWindow:SetAlpha(ConRO.db.profile.transparencyWindow);
			ConRODefenseWindow:SetAlpha(ConRO.db.profile.transparencyWindow);
		else
			self.NextSpell = ConRO.Druid.Disabled;
			self.ToggleHealer();
			ConROWindow:SetAlpha(0);
			ConRODefenseWindow:SetAlpha(0);
		end
	end;
	self:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED');
	self.lastSpellId = 0;
end

function ConRO:EnableDefenseModule(mode)
	mode = mode or 0;
	if mode == 0 then
		self.NextDef = ConRO.Druid.Under10Def;
	end;
	if mode == 1 then
		if ConRO.db.profile._Spec_1_Enabled then
			self.NextDef = ConRO.Druid.BalanceDef;
		else
			self.NextDef = ConRO.Druid.Disabled;
		end
	end;
	if mode == 2 then
		if ConRO.db.profile._Spec_2_Enabled then
			self.NextDef = ConRO.Druid.FeralDef;
		else
			self.NextDef = ConRO.Druid.Disabled;
		end
	end;
	if mode == 3 then
		if ConRO.db.profile._Spec_3_Enabled then
			self.NextDef = ConRO.Druid.GuardianDef;
		else
			self.NextDef = ConRO.Druid.Disabled;
		end
	end;
	if mode == 4 then
		if ConRO.db.profile._Spec_4_Enabled then
			self.NextDef = ConRO.Druid.RestorationDef;
		else
			self.NextDef = ConRO.Druid.Disabled;
		end
	end;
end

function ConRO:UNIT_SPELLCAST_SUCCEEDED(event, unitID, lineID, spellID)
	if unitID == 'player' then
		self.lastSpellId = spellID;
	end
end

function ConRO.Druid.Disabled(_, timeShift, currentSpell, gcd, tChosen, pvpChosen)
	return nil;
end

--Info
local _Player_Level = UnitLevel("player");
local _Player_Percent_Health = ConRO:PercentHealth('player');
local _is_PvP = ConRO:IsPvP();
local _in_combat = UnitAffectingCombat('player');
local _party_size = GetNumGroupMembers();
local _is_PC = UnitPlayerControlled("target");
local _is_Enemy = ConRO:TarHostile();
local _Target_Health = UnitHealth('target');
local _Target_Percent_Health = ConRO:PercentHealth('target');

--Resources
local _AstralPower, _AstralPower_Max = ConRO:PlayerPower('LunarPower');
local _Combo, _Combo_Max = ConRO:PlayerPower('Combo');
local _Energy, _Energy_Max = ConRO:PlayerPower('Energy');
local _Mana, _Mana_Max, _Mana_Percent = ConRO:PlayerPower('Mana');
local _Rage, _Rage_Max = ConRO:PlayerPower('Rage');

--Conditions
local _Queue = 0;
local _is_moving = ConRO:PlayerSpeed();
local _enemies_in_melee, _target_in_melee = ConRO:Targets("Melee");
local _enemies_in_10yrds, _target_in_10yrds = ConRO:Targets("10");
local _enemies_in_25yrds, _target_in_25yrds = ConRO:Targets("25");
local _enemies_in_40yrds, _target_in_40yrds = ConRO:Targets("40");
local _can_Execute = _Target_Percent_Health < 20;

--Racials
local _Berserking, _Berserking_RDY = _, _;

local HeroSpec, Racial = ids.HeroSpec, ids.Racial;

function ConRO:Stats()
	_Player_Level = UnitLevel("player");
	_Player_Percent_Health = ConRO:PercentHealth('player');
	_is_PvP = ConRO:IsPvP();
	_in_combat = UnitAffectingCombat('player');
	_party_size = GetNumGroupMembers();
	_is_PC = UnitPlayerControlled("target");
	_is_Enemy = ConRO:TarHostile();
	_Target_Health = UnitHealth('target');
	_Target_Percent_Health = ConRO:PercentHealth('target');

	_AstralPower, _AstralPower_Max = ConRO:PlayerPower('LunarPower');
	_Combo, _Combo_Max = ConRO:PlayerPower('Combo');
	_Energy, _Energy_Max = ConRO:PlayerPower('Energy');
	_Mana, _Mana_Max, _Mana_Percent = ConRO:PlayerPower('Mana');
	_Rage, _Rage_Max = ConRO:PlayerPower('Rage');

	_Queue = 0;
	_is_moving = ConRO:PlayerSpeed();
	_enemies_in_melee, _target_in_melee = ConRO:Targets("Melee");
	_enemies_in_10yrds, _target_in_10yrds = ConRO:Targets("10");
	_enemies_in_25yrds, _target_in_25yrds = ConRO:Targets("25");
	_enemies_in_40yrds, _target_in_40yrds = ConRO:Targets("40");
	_can_Execute = _Target_Percent_Health < 20;

	_Berserking, _Berserking_RDY = ConRO:AbilityReady(ids.Racial.Berserking, timeShift);
end

function ConRO.Druid.Under10(_, timeShift, currentSpell, gcd, tChosen, pvpChosen)
	wipe(ConRO.SuggestedSpells);
	ConRO:Stats();
	local Ability, Form, Buff, Debuff, PetAbility, PvPTalent = ids.Druid_Ability, ids.Druid_Form, ids.Druid_Buff, ids.Druid_Debuff, ids.Druid_PetAbility, ids.Druid_PvPTalent;

--Abilities

--Warnings

--Rotations

return nil;
end

function ConRO.Druid.Under10Def(_, timeShift, currentSpell, gcd, tChosen, pvpChosen)
	wipe(ConRO.SuggestedDefSpells);
	ConRO:Stats();
	local Ability, Form, Buff, Debuff, PetAbility, PvPTalent = ids.Druid_Ability, ids.Druid_Form, ids.Druid_Buff, ids.Druid_Debuff, ids.Druid_PetAbility, ids.Druid_PvPTalent;

--Abilities

--Warnings

--Rotations	

return nil;
end

function ConRO.Druid.Balance(_, timeShift, currentSpell, gcd, tChosen, pvpChosen)
	wipe(ConRO.SuggestedSpells);
	ConRO:Stats();
	local Ability, Form, Buff, Debuff, PetAbility, PvPTalent = ids.Bal_Ability, ids.Bal_Form, ids.Bal_Buff, ids.Bal_Debuff, ids.Bal_PetAbility, ids.Bal_PvPTalent;

--Abilities
	local _CelestialAlignment, _CelestialAlignment_RDY = ConRO:AbilityReady(Ability.CelestialAlignment, timeShift);
		local _CelestialAlignment_BUFF = ConRO:Aura(Buff.CelestialAlignment, timeShift);
	local _ConvoketheSpirits, _ConvoketheSpirits_RDY = ConRO:AbilityReady(Ability.ConvoketheSpirits, timeShift);
	local _ForceofNature, _ForceofNature_RDY = ConRO:AbilityReady(Ability.ForceofNature, timeShift);
	local _FuryofElune, _FuryofElune_RDY = ConRO:AbilityReady(Ability.FuryofElune, timeShift);
	local _IncarnationChosenofElune, _IncarnationChosenofElune_RDY = ConRO:AbilityReady(Ability.IncarnationChosenofElune, timeShift);
	local _MarkoftheWild, _MarkoftheWild_RDY = ConRO:AbilityReady(Ability.MarkoftheWild, timeShift);
	local _Moonfire, _Moonfire_RDY = ConRO:AbilityReady(Ability.Moonfire, timeShift);
		local _Moonfire_DEBUFF, _, _Moonfire_DUR = ConRO:TargetAura(Debuff.Moonfire, timeShift);
	local _MoonkinForm, _MoonkinForm_RDY = ConRO:AbilityReady(Ability.MoonkinForm, timeShift);
		local _MoonkinForm_FORM = ConRO:Form(Form.MoonkinForm);
	local _NewMoon, _NewMoon_RDY, _, _, _NewMoon_CAST = ConRO:AbilityReady(Ability.NewMoon, timeShift);
		local _HalfMoon, _, _HalfMoon_CD, _, _HalfMoon_CAST = ConRO:AbilityReady(Ability.HalfMoon, timeShift);
		local _FullMoon, _, _FullMoon_CD, _, _FullMoon_CAST = ConRO:AbilityReady(Ability.FullMoon, timeShift);
		local _NewMoon_CHARGES = ConRO:SpellCharges(_NewMoon);
	local _SolarBeam, _SolarBeam_RDY = ConRO:AbilityReady(Ability.SolarBeam, timeShift);
	local _Soothe, _Soothe_RDY = ConRO:AbilityReady(Ability.Soothe, timeShift);
	local _Starfire, _Starfire_RDY = ConRO:AbilityReady(Ability.Starfire, timeShift);
		local _Starfire_Count = C_Spell.GetSpellCastCount(_Starfire);
		local _EclipseSolar_BUFF, _, _EclipseSolar_DUR = ConRO:Aura(Buff.EclipseSolar, timeShift);
	local _Starsurge, _Starsurge_RDY = ConRO:AbilityReady(Ability.Starsurge, timeShift);
		local _, _Starlord_COUNT = ConRO:Aura(Buff.Starlord, timeShift);
		local _UmbralEmbrace_BUFF = ConRO:Aura(Buff.UmbralEmbrace, timeShift);
	local _Starfall, _Starfall_RDY = ConRO:AbilityReady(Ability.Starfall, timeShift);
		local _Starfall_BUFF, _, _Starfall_DUR = ConRO:Aura(Buff.Starfall, timeShift);
	local _StellarFlare, _StellarFlare_RDY = ConRO:AbilityReady(Ability.StellarFlare, timeShift);
		local _StellarFlare_DEBUFF, _, _StellarFlare_DUR = ConRO:TargetAura(Debuff.StellarFlare, timeShift);
	local _Sunfire, _Sunfire_RDY = ConRO:AbilityReady(Ability.Sunfire, timeShift);
		local _Sunfire_DEBUFF, _, _Sunfire_DUR = ConRO:TargetAura(Debuff.Sunfire, timeShift);
	local _WarriorofElune, _WarriorofElune_RDY = ConRO:AbilityReady(Ability.WarriorofElune, timeShift);
		local _WarriorofElune_BUFF = ConRO:Form(Form.WarriorofElune);
	local _WildMushroom, _WildMushroom_RDY = ConRO:AbilityReady(Ability.WildMushroom, timeShift);
		local _WildMushroom_CHARGES = ConRO:SpellCharges(_WildMushroom);
	local _Wrath, _Wrath_RDY = ConRO:AbilityReady(Ability.Wrath, timeShift);
		local _Wrath_Count = C_Spell.GetSpellCastCount(_Wrath);
		local _EclipseLunar_BUFF, _, _EclipseLunar_DUR = ConRO:Aura(Buff.EclipseLunar, timeShift);
		local _BalanceofAllthings_BUFF, _, _BalanceofAllthings_DUR = ConRO:Aura(Buff.BalanceofAllThings, timeShift);

--Conditions
	local _enemies_in_range, _target_in_range = ConRO:Targets(Ability.Wrath);

		if _Wrath_Count == 1 and currentSpell == _Wrath then
			_EclipseLunar_BUFF = true;
		end

		if _Starfire_Count == 1 and currentSpell == _Starfire then
			_EclipseSolar_BUFF = true;
		end

	local _Moon_COST = 10;
		if currentSpell == Ability.FullMoon then
			_Moon_COST = 40;
			_NewMoon_CHARGES = _NewMoon_CHARGES - 1;
		elseif currentSpell == Ability.NewMoon then
			_Moon_COST = 10;
			_NewMoon_CHARGES = _NewMoon_CHARGES - 1;
		elseif currentSpell == Ability.HalfMoon then
			_Moon_COST = 20;
			_NewMoon_CHARGES = _NewMoon_CHARGES - 1;
		end

		if currentSpell == Ability.Wrath then
			_AstralPower = _AstralPower + 10;
			_Wrath_Count = _Wrath_Count - 1;
		elseif currentSpell == Ability.Starfire then
			_AstralPower = _AstralPower + 12;
			_Starfire_Count = _Starfire_Count - 1;
		end

		if ConRO:IsOverride(_NewMoon) == _FullMoon then
			_NewMoon_RDY = _NewMoon_RDY and _FullMoon_CD <= 0;
			_NewMoon, _NewMoon_CAST = _FullMoon, _FullMoon_CAST;
		elseif ConRO:IsOverride(_NewMoon) == _HalfMoon then
			_NewMoon_RDY = _NewMoon_RDY and _HalfMoon_CD <= 0;
			_NewMoon, _NewMoon_CAST = _HalfMoon, _HalfMoon_CAST;
		end

		if tChosen[Ability.OrbitalStrike.talentID] then
			_CelestialAlignment, _CelestialAlignment_RDY = ConRO:AbilityReady(Ability.CelestialAlignmentOS, timeShift);
			_IncarnationChosenofElune, _IncarnationChosenofElune_RDY = ConRO:AbilityReady(Ability.IncarnationChosenofEluneOS, timeShift);
		end

		if tChosen[Ability.IncarnationChosenofElune.talentID] then
			_CelestialAlignment, _CelestialAlignment_RDY = _IncarnationChosenofElune, _IncarnationChosenofElune_RDY;
			_CelestialAlignment_BUFF = ConRO:Aura(Buff.IncarnationChosenofElune, timeShift);
		end

	local _No_Eclipse = not _EclipseSolar_BUFF and not _EclipseLunar_BUFF;

--Indicators
	ConRO:AbilityInterrupt(_SolarBeam, _SolarBeam_RDY and ConRO:Interrupt());
	ConRO:AbilityPurge(_Soothe, _Soothe_RDY and ConRO:Purgable());

	ConRO:AbilityBurst(_CelestialAlignment, _CelestialAlignment_RDY and _Moonfire_DEBUFF and _Sunfire_DEBUFF and (not tChosen[Ability.StellarFlare] or (tChosen[Ability.StellarFlare] and _StellarFlare_DEBUFF)) and (_EclipseSolar_BUFF or _EclipseLunar_BUFF) and ConRO:BurstMode(_CelestialAlignment, 120));
	ConRO:AbilityBurst(_FuryofElune, _FuryofElune_RDY and _AstralPower <= 60 and ConRO:BurstMode(_FuryofElune));
	ConRO:AbilityBurst(_ForceofNature, _ForceofNature_RDY and _AstralPower <= 80 and ConRO:BurstMode(_ForceofNature));
	ConRO:AbilityBurst(_WarriorofElune, _WarriorofElune_RDY and not _WarriorofElune_BUFF and ConRO:BurstMode(_WarriorofElune));
	ConRO:AbilityBurst(_ConvoketheSpirits, _ConvoketheSpirits_RDY and (_EclipseSolar_BUFF or _EclipseLunar_BUFF) and ConRO:BurstMode(_ConvoketheSpirits));

	ConRO:AbilityRaidBuffs(_MarkoftheWild, _MarkoftheWild_RDY and not ConRO:RaidBuff(Buff.MarkoftheWild));

--Rotations	
	repeat
		while(true) do
			if select(8, UnitChannelInfo("player")) == _ConvoketheSpirits then -- Do not break cast
				tinsert(ConRO.SuggestedSpells, _ConvoketheSpirits);
				_Queue = _Queue + 1;
				break;
			end

			if _MoonkinForm_RDY and not _MoonkinForm_FORM then
				tinsert(ConRO.SuggestedSpells, _MoonkinForm);
				_MoonkinForm_FORM = true;
				_Queue = _Queue + 1;
				break;
			end

			if not _in_combat then
				if _No_Eclipse then
					if ((ConRO_AutoButton:IsVisible() and _enemies_in_range >= 3) or ConRO_AoEButton:IsVisible()) or tChosen[Ability.LunarCalling.talentID] then
						if _Wrath_RDY and _Wrath_Count >= 1 then
							tinsert(ConRO.SuggestedSpells, _Wrath);
							_Wrath_Count = _Wrath_Count - 1;
							_EclipseLunar_BUFF = true;
							_Queue = _Queue + 1;
							break;
						end
					else
						if _Starfire_RDY and _Starfire_Count >= 1 then
							tinsert(ConRO.SuggestedSpells, _Starfire);
							_Starfire_Count = _Starfire_Count - 1;
							_EclipseSolar_BUFF = true;
							_Queue = _Queue + 1;
							break;
						end
					end
				end
			end

			if _Moonfire_RDY and (not _Moonfire_DEBUFF or _Moonfire_DUR <= 3) then
				tinsert(ConRO.SuggestedSpells, _Moonfire);
				_Moonfire_DEBUFF = true;
				_Moonfire_DUR = 16;
				_Queue = _Queue + 1;
				break;
			end

			if _Sunfire_RDY and (not _Sunfire_DEBUFF or _Sunfire_DUR <= 3) then
				tinsert(ConRO.SuggestedSpells, _Sunfire);
				_Sunfire_DEBUFF = true;
				_Sunfire_DUR = 13;
				_Queue = _Queue + 1;
				break;
			end

			if _StellarFlare_RDY and (not _StellarFlare_DEBUFF or _StellarFlare_DUR <= 3) and currentSpell ~= _StellarFlare then
				tinsert(ConRO.SuggestedSpells, _StellarFlare);
				_StellarFlare_DEBUFF = true;
				_StellarFlare_DUR = 18;
				_Queue = _Queue + 1;
				break;
			end

			if _FuryofElune_RDY and _AstralPower <= 70 and ConRO:FullMode(_FuryofElune) then
				tinsert(ConRO.SuggestedSpells, _FuryofElune);
				_FuryofElune_RDY = false;
				_Queue = _Queue + 1;
				break;
			end

			if _ForceofNature_RDY and _AstralPower <= 80 and ConRO:FullMode(_ForceofNature) then
				tinsert(ConRO.SuggestedSpells, _ForceofNature);
				_ForceofNature_RDY = false;
				_Queue = _Queue + 1;
				break;
			end

			if _CelestialAlignment_RDY and not _CelestialAlignment_BUFF and ConRO:FullMode(_CelestialAlignment, 120) then
				tinsert(ConRO.SuggestedSpells, _CelestialAlignment);
				_CelestialAlignment_RDY = false;
				_Queue = _Queue + 1;
				break;
			end

			if _WarriorofElune_RDY and not _WarriorofElune_BUFF and ConRO:FullMode(_WarriorofElune) then
				tinsert(ConRO.SuggestedSpells, _WarriorofElune);
				_WarriorofElune_RDY = false;
				_Queue = _Queue + 1;
				break;
			end

			if _No_Eclipse then
				if ((ConRO_AutoButton:IsVisible() and _enemies_in_range >= 3) or ConRO_AoEButton:IsVisible()) or tChosen[Ability.LunarCalling.talentID] then
					if _Wrath_RDY and _Wrath_Count >= 1 then
						tinsert(ConRO.SuggestedSpells, _Wrath);
						_Wrath_Count = _Wrath_Count - 1;
						_EclipseLunar_BUFF = true;
						_Queue = _Queue + 1;
						break;
					end
				else
					if _Starfire_RDY and _Starfire_Count >= 1 then
						tinsert(ConRO.SuggestedSpells, _Starfire);
						_Starfire_Count = _Starfire_Count - 1;
						_EclipseSolar_BUFF = true;
						_Queue = _Queue + 1;
						break;
					end
				end
			end

			if _ConvoketheSpirits_RDY and _AstralPower < 50 and ConRO:FullMode(_ConvoketheSpirits) then
				tinsert(ConRO.SuggestedSpells, _ConvoketheSpirits);
				_ConvoketheSpirits_RDY = false;
				_Queue = _Queue + 1;
				break;
			end

			if _Starsurge_RDY and _AstralPower >= 40 and ((_AstralPower >= _AstralPower_Max - 10) or (_BalanceofAllthings_BUFF and _BalanceofAllthings_DUR >= 5) or (_Starlord_COUNT < 3)) and ((ConRO_AutoButton:IsVisible() and _enemies_in_range <= 2) or ConRO_SingleButton:IsVisible()) then
				tinsert(ConRO.SuggestedSpells, _Starsurge);
				_AstralPower = _AstralPower - 40;
				_Queue = _Queue + 1;
				break;
			end

			if _Starfall_RDY and _AstralPower >= 50 and ((ConRO_AutoButton:IsVisible() and _enemies_in_range >= 3) or ConRO_AoEButton:IsVisible()) then
				tinsert(ConRO.SuggestedSpells, _Starfall);
				_AstralPower = _AstralPower - 50;
				_Queue = _Queue + 1;
				break;
			end

			if _NewMoon_RDY and (_NewMoon_CHARGES >= 1) and (_AstralPower <= _AstralPower_Max - _Moon_COST) and ((_NewMoon_CAST < _EclipseLunar_DUR) or (_NewMoon_CAST < _EclipseSolar_DUR)) then
				tinsert(ConRO.SuggestedSpells, _NewMoon);
				_NewMoon_CHARGES = _NewMoon_CHARGES - 1;
				_AstralPower = _AstralPower - _Moon_COST;
				_Queue = _Queue + 1;
				break;
			end

			if _WildMushroom_RDY and _WildMushroom_CHARGES >= 1 then
				tinsert(ConRO.SuggestedSpells, _WildMushroom);
				_WildMushroom_CHARGES = _WildMushroom_CHARGES - 1;
				_Queue = _Queue + 1;
				break;
			end

			if _Starfire_RDY and _EclipseLunar_BUFF then
				tinsert(ConRO.SuggestedSpells, _Starfire);
				_Queue = _Queue + 1;
				break;
			end

			if _Wrath_RDY and _EclipseSolar_BUFF then
				tinsert(ConRO.SuggestedSpells, _Wrath);
				_Queue = _Queue + 1;
				break;
			end


			tinsert(ConRO.SuggestedSpells, 289603); --Waiting Spell Icon
			_Queue = _Queue + 3;
			break;
		end
	until _Queue >= 3;
return nil;
end

function ConRO.Druid.BalanceDef(_, timeShift, currentSpell, gcd, tChosen, pvpChosen)
	wipe(ConRO.SuggestedDefSpells);
	ConRO:Stats();
	local Ability, Form, Buff, Debuff, PetAbility, PvPTalent = ids.Bal_Ability, ids.Bal_Form, ids.Bal_Buff, ids.Bal_Debuff, ids.Bal_PetAbility, ids.Bal_PvPTalent;

--Abilities	
	local _Barkskin, _Barkskin_RDY = ConRO:AbilityReady(Ability.Barkskin, timeShift);
	local _NaturesVigil, _NaturesVigil_RDY = ConRO:AbilityReady(Ability.NaturesVigil, timeShift);
	local _Regrowth, _Regrowth_RDY = ConRO:AbilityReady(Ability.Regrowth, timeShift);
	local _Renewal, _Renewal_RDY = ConRO:AbilityReady(Ability.Renewal, timeShift);

--Rotations	
	if _Renewal_RDY and _Player_Percent_Health <= 40 then
		tinsert(ConRO.SuggestedDefSpells, _Renewal);
	end

	if _NaturesVigil_RDY and _Player_Percent_Health <= 80 then
		tinsert(ConRO.SuggestedDefSpells, _NaturesVigil);
	end

	if _Regrowth_RDY and _Player_Percent_Health <= 75 then
		tinsert(ConRO.SuggestedDefSpells, _Regrowth);
	end

	if _Barkskin_RDY then
		tinsert(ConRO.SuggestedDefSpells, _Barkskin);
	end
return nil;
end

function ConRO.Druid.Feral(_, timeShift, currentSpell, gcd, tChosen, pvpChosen)
	wipe(ConRO.SuggestedSpells);
	ConRO:Stats();
	local Ability, Form, Buff, Debuff, PetAbility, PvPTalent = ids.Feral_Ability, ids.Feral_Form, ids.Feral_Buff, ids.Feral_Debuff, ids.Feral_PetAbility, ids.Feral_PvPTalent;

--Abilities	
	local _AdaptiveSwarm, _AdaptiveSwarm_RDY = ConRO:AbilityReady(Ability.AdaptiveSwarm, timeShift);
		local _AdaptiveSwarm_DEBUFF, _AdaptiveSwarm_COUNT = ConRO:TargetAura(Debuff.AdaptiveSwarm, timeShift);
	local _Berserk, _Berserk_RDY = ConRO:AbilityReady(Ability.Berserk, timeShift);
		local _Berserk_BUFF = ConRO:Aura(Buff.Berserk, timeShift);
	local _CatForm, _CatForm_RDY = ConRO:AbilityReady(Ability.CatForm, timeShift);
		local _BearForm_FORM = ConRO:Form(Form.BearForm);
		local _CatForm_FORM	= ConRO:Form(Form.CatForm);
	local _ConvoketheSpirits, _ConvoketheSpirits_RDY = ConRO:AbilityReady(Ability.ConvoketheSpirits, timeShift);
	local _FeralFrenzy, _FeralFrenzy_RDY = ConRO:AbilityReady(Ability.FeralFrenzy, timeShift);
	local _FerociousBite, _FerociousBite_RDY = ConRO:AbilityReady(Ability.FerociousBite, timeShift);
		local _ApexPredatorsCraving_BUFF = ConRO:Aura(Buff.ApexPredatorsCraving, timeShift);
		local _Ravage_BUFF = ConRO:Aura(Buff.Ravage, timeShift);
	local _Maim, _Maim_RDY = ConRO:AbilityReady(Ability.Maim, timeShift);
	local _Mangle, _Mangle_RDY = ConRO:AbilityReady(Ability.Mangle, timeShift);
	local _MarkoftheWild, _MarkoftheWild_RDY = ConRO:AbilityReady(Ability.MarkoftheWild, timeShift);
	local _Moonfire, _Moonfire_RDY = ConRO:AbilityReady(Ability.Moonfire, timeShift);
		local _Moonfire_DEBUFF = ConRO:TargetAura(Debuff.Moonfire, timeShift);
	local _PrimalWrath, _PrimalWrath_RDY = ConRO:AbilityReady(Ability.PrimalWrath, timeShift);
	local _Prowl, _Prowl_RDY = ConRO:AbilityReady(Ability.Prowl, timeShift);
		local _Prowl_FORM = ConRO:Form(Form.Prowl);
	local _Rake, _Rake_RDY = ConRO:AbilityReady(Ability.Rake, timeShift);
		local _Rake_DEBUFF, _, _Rake_DUR = ConRO:TargetAura(Debuff.Rake, timeShift);
		local _RakeStun_DEBUFF = ConRO:TargetAura(Debuff.RakeStun, timeShift);
	local _Rip, _Rip_RDY = ConRO:AbilityReady(Ability.Rip, timeShift);
		local _Rip_DEBUFF, _, _Rip_DUR = ConRO:TargetAura(Debuff.Rip, timeShift);
	local _Shred, _Shred_RDY = ConRO:AbilityReady(Ability.Shred, timeShift);
		local _Clearcasting_BUFF = ConRO:Aura(Buff.Clearcasting, timeShift);
		local _Bloodtalons_BUFF = ConRO:Aura(Buff.Bloodtalons, timeShift);
		local _SuddenAmbush_BUFF = ConRO:Aura(Buff.SuddenAmbush, timeShift);
	local _SkullBash, _SkullBash_RDY = ConRO:AbilityReady(Ability.SkullBash, timeShift);
	local _Soothe, _Soothe_RDY = ConRO:AbilityReady(Ability.Soothe, timeShift);
	local _Swipe, _Swipe_RDY = ConRO:AbilityReady(Ability.Swipe, timeShift);
		local _BrutalSlash_CHARGES, _BrutalSlash_MaxCHARGES, _BrutalSlash_CCD = ConRO:SpellCharges(Ability.BrutalSlash.spellID);
	local _Thrash, _Thrash_RDY = ConRO:AbilityReady(Ability.Thrash, timeShift);
		local _ThrashBF_DEBUFF, _ThrashBF_COUNT = ConRO:TargetAura(Debuff.ThrashBF, timeShift);
		local _ThrashCF_DEBUFF, _, _ThrashCF_DUR = ConRO:TargetAura(Debuff.ThrashCF, timeShift);
	local _TigersFury, _TigersFury_RDY = ConRO:AbilityReady(Ability.TigersFury, timeShift);
		local _TigersFury_BUFF = ConRO:Aura(Buff.TigersFury, timeShift);
	local _WildCharge, _WildCharge_RDY = ConRO:AbilityReady(Ability.WildCharge, timeShift);
		local _, _WildCharge_RANGE = ConRO:Targets(Ability.WildCharge);

--Conditions
	if _BearForm_FORM then
		_WildCharge = ConRO:AbilityReady(Ability.WildChargeBF, timeShift);
		_Thrash, _Thrash_RDY = ConRO:AbilityReady(Ability.ThrashBF, timeShift);
		_Swipe, _Swipe_RDY = ConRO:AbilityReady(Ability.SwipeBF, timeShift);
	end

	if _CatForm_FORM then
		_WildCharge = ConRO:AbilityReady(Ability.WildChargeCF, timeShift);
		_Thrash, _Thrash_RDY = ConRO:AbilityReady(Ability.ThrashCF, timeShift);
		_Swipe, _Swipe_RDY = ConRO:AbilityReady(Ability.SwipeCF, timeShift);
	end

	if tChosen[Ability.LunarInspiration.talentID] then
		_Moonfire, _Moonfire_RDY = ConRO:AbilityReady(Ability.MoonfireCF, timeShift);
	end

	if tChosen[Ability.IncarnationAvatarofAshmane.talentID] then
		_Berserk, _Berserk_RDY = ConRO:AbilityReady(Ability.IncarnationAvatarofAshmane, timeShift);
		_Berserk_BUFF = ConRO:Aura(Buff.IncarnationAvatarofAshmane, timeShift);
	end

	if tChosen[Ability.BrutalSlash.talentID] then
		_Swipe, _Swipe_RDY = ConRO:AbilityReady(Ability.BrutalSlash, timeShift);
	end

	if _Ravage_BUFF then
		_, _FerociousBite_RDY = ConRO:AbilityReady(Ability.Ravage, timeShift);
	end

--Indicators		
	ConRO:AbilityInterrupt(_SkullBash, _SkullBash_RDY and ConRO:Interrupt());
	ConRO:AbilityPurge(_Soothe, _Soothe_RDY and ConRO:Purgable());
	ConRO:AbilityMovement(_WildCharge, _WildCharge_RDY and _WildCharge_RANGE);

	ConRO:AbilityBurst(_Berserk, _Berserk_RDY and ConRO:BurstMode(_Berserk));
	ConRO:AbilityBurst(_FeralFrenzy, _FeralFrenzy_RDY and _Combo <= 0 and ConRO:BurstMode(_FeralFrenzy));
	ConRO:AbilityBurst(_ConvoketheSpirits, _ConvoketheSpirits_RDY and _Combo <= 2 and _Energy <= 30 and ConRO:BurstMode(_ConvoketheSpirits));

	ConRO:AbilityRaidBuffs(_MarkoftheWild, _MarkoftheWild_RDY and not ConRO:RaidBuff(Buff.MarkoftheWild));

--Rotations	
	repeat
		while(true) do
			if _BearForm_FORM then
				if _Thrash_RDY and _ThrashBF_COUNT < 3 then
					tinsert(ConRO.SuggestedSpells, _Thrash);
					_Queue = _Queue + 1;
					break;
				end

				if _Mangle_RDY then
					tinsert(ConRO.SuggestedSpells, _Mangle);
					_Queue = _Queue + 1;
					break;
				end

				if _Swipe_RDY then
					tinsert(ConRO.SuggestedSpells, _Swipe);
					_Queue = _Queue + 1;
					break;
				end
			return nil;
			end

			if _CatForm_RDY and not _CatForm_FORM then
				tinsert(ConRO.SuggestedSpells, _CatForm);
				_CatForm_FORM = true;
				_Queue = _Queue + 1;
				break;
			end

			if not _in_combat or _Prowl_FORM then
				if _Prowl_RDY and not _Prowl_FORM then
					tinsert(ConRO.SuggestedSpells, _Prowl);
					_Prowl_RDY = false;
					_Queue = _Queue + 1;
					break;
				end

				if _Rake_RDY and not _Rake_DEBUFF then
					tinsert(ConRO.SuggestedSpells, _Rake);
					_Rake_DEBUFF = true;
					_Rake_DUR = 15;
					_Combo = _Combo + 1;
					_Queue = _Queue + 1;
					break;
				end
			end

			if _PrimalWrath_RDY and _Combo >= 5 and (not _Rip_DEBUFF or _Rip_DUR <= 7) and ((ConRO_AutoButton:IsVisible() and _enemies_in_melee >= 3) or ConRO_AoEButton:IsVisible()) then
				tinsert(ConRO.SuggestedSpells, _PrimalWrath);
				_Rip_DUR = 24;
				_Combo = 0;
				_Queue = _Queue + 1;
				break;
			end

			if _FerociousBite_RDY and _Combo >= 5 and _Ravage_BUFF and ((ConRO_AutoButton:IsVisible() and _enemies_in_melee >= 3) or ConRO_AoEButton:IsVisible()) then
				tinsert(ConRO.SuggestedSpells, _FerociousBite);
				_Ravage_BUFF = false;
				_Combo = 0;
				_Queue = _Queue + 1;
				break;
			end

			if _PrimalWrath_RDY and _Combo >= 5 and ((ConRO_AutoButton:IsVisible() and _enemies_in_melee >= 8) or ConRO_AoEButton:IsVisible()) then
				tinsert(ConRO.SuggestedSpells, _PrimalWrath);
				_Rip_DUR = 24;
				_Combo = 0;
				_Queue = _Queue + 1;
				break;
			end

			if _FerociousBite_RDY and _ApexPredatorsCraving_BUFF then
				tinsert(ConRO.SuggestedSpells, _FerociousBite);
				_Ravage_BUFF = false;
				_ApexPredatorsCraving_BUFF = false;
				_Queue = _Queue + 1;
				break;
			end

			if _TigersFury_RDY and not _TigersFury_BUFF and _Energy <= 50 then
				tinsert(ConRO.SuggestedSpells, _TigersFury);
				_TigersFury_RDY = false;
				_Queue = _Queue + 1;
				break;
			end

			if _Rip_RDY and (not _Rip_DEBUFF or _Rip_DUR <= 7) and _Combo >= 5 then
				tinsert(ConRO.SuggestedSpells, _Rip);
				_Rip_DUR = 24;
				_Combo = 0;
				_Queue = _Queue + 1;
				break;
			end

			if _Thrash_RDY and (not _ThrashCF_DEBUFF or _ThrashCF_DUR <= 4) and ((ConRO_AutoButton:IsVisible() and _enemies_in_melee >= 3) or ConRO_AoEButton:IsVisible()) then
				tinsert(ConRO.SuggestedSpells, _Thrash);
				_ThrashCF_DUR = 15;
				_Combo = _Combo + 1;
				_Queue = _Queue + 1;
				break;
			end

			if _Rake_RDY and (not _Rake_DEBUFF or _Rake_DUR <= 4) then
				tinsert(ConRO.SuggestedSpells, _Rake);
				_Rake_DEBUFF = true;
				_Rake_DUR = 15;
				_Combo = _Combo + 1;
				_Queue = _Queue + 1;
				break;
			end

			if _Swipe_RDY and tChosen[Ability.BrutalSlash.talentID] and _BrutalSlash_CHARGES == _BrutalSlash_MaxCHARGES and ((ConRO_AutoButton:IsVisible() and _enemies_in_melee >= 3) or ConRO_AoEButton:IsVisible()) then
				tinsert(ConRO.SuggestedSpells, _Swipe);
				_BrutalSlash_CHARGES = _BrutalSlash_CHARGES - 1;
				_Combo = _Combo + 1;
				_Queue = _Queue + 1;
				break;
			end

			if _Moonfire_RDY and not _Moonfire_DEBUFF and tChosen[Ability.LunarInspiration.talentID] then
				tinsert(ConRO.SuggestedSpells, _Moonfire);
				_Moonfire_DEBUFF = true;
				_Combo = _Combo + 1;
				_Queue = _Queue + 1;
				break;
			end

			if _Swipe_RDY and _Combo <= 4 and ((ConRO_AutoButton:IsVisible() and _enemies_in_melee >= 3) or ConRO_AoEButton:IsVisible()) then
				tinsert(ConRO.SuggestedSpells, _Swipe);
				_BrutalSlash_CHARGES = _BrutalSlash_CHARGES - 1;
				_Combo = _Combo + 1;
				_Queue = _Queue + 1;
				break;
			end

			if _Thrash_RDY and (not _ThrashCF_DEBUFF or _ThrashCF_DUR <= 4) then
				tinsert(ConRO.SuggestedSpells, _Thrash);
				_ThrashCF_DUR = 15;
				_Combo = _Combo + 1;
				_Queue = _Queue + 1;
				break;
			end

			if _AdaptiveSwarm_RDY and (not _AdaptiveSwarm_DEBUFF or _AdaptiveSwarm_COUNT < 3) then
				tinsert(ConRO.SuggestedSpells, _AdaptiveSwarm);
				_AdaptiveSwarm_RDY = false;
				_Queue = _Queue + 1;
				break;
			end

			if _FeralFrenzy_RDY and _Combo <= 1 and ConRO:FullMode(_FeralFrenzy) then
				tinsert(ConRO.SuggestedSpells, _FeralFrenzy);
				_FeralFrenzy_RDY = false;
				_Combo = _Combo + 5;
				_Queue = _Queue + 1;
				break;
			end

			if _Berserk_RDY and ConRO:FullMode(_Berserk) then
				tinsert(ConRO.SuggestedSpells, _Berserk);
				_Berserk_RDY = false;
				_Queue = _Queue + 1;
				break;
			end

			if _ConvoketheSpirits_RDY and _Combo <= 1 and ConRO:FullMode(_ConvoketheSpirits) then
				tinsert(ConRO.SuggestedSpells, _ConvoketheSpirits);
				_ConvoketheSpirits_RDY = false;
				_Queue = _Queue + 1;
				break;
			end

			if _FerociousBite_RDY and _Rip_DUR >= 6 and _Combo >= 5 then
				tinsert(ConRO.SuggestedSpells, _FerociousBite);
				_Ravage_BUFF = false;
				_Combo = 0;
				_Queue = _Queue + 1;
				break;
			end

			if _Swipe_RDY and tChosen[Ability.BrutalSlash.talentID] and _BrutalSlash_CHARGES == _BrutalSlash_MaxCHARGES then
				tinsert(ConRO.SuggestedSpells, _Swipe);
				_BrutalSlash_CHARGES = _BrutalSlash_CHARGES - 1;
				_Combo = _Combo + 1;
				_Queue = _Queue + 1;
				break;
			end

			if _Shred_RDY and _Combo <= 4 then
				tinsert(ConRO.SuggestedSpells, _Shred);
				_Combo = _Combo + 1;
				_Queue = _Queue + 1;
				break;
			end

			tinsert(ConRO.SuggestedSpells, 289603); --Waiting Spell Icon
			_Queue = _Queue + 3;
			break;
		end
	until _Queue >= 3;
return nil;
end

function ConRO.Druid.FeralDef(_, timeShift, currentSpell, gcd, tChosen, pvpChosen)
	wipe(ConRO.SuggestedDefSpells);
	ConRO:Stats();
	local Ability, Form, Buff, Debuff, PetAbility, PvPTalent = ids.Feral_Ability, ids.Feral_Form, ids.Feral_Buff, ids.Feral_Debuff, ids.Feral_PetAbility, ids.Feral_PvPTalent;

--Abilities
	local _SurvivalInstincts, _SurvivalInstincts_RDY = ConRO:AbilityReady(Ability.SurvivalInstincts, timeShift);
	local _Barkskin, _Barkskin_RDY = ConRO:AbilityReady(Ability.Barkskin, timeShift);
	local _Renewal, _Renewal_RDY = ConRO:AbilityReady(Ability.Renewal, timeShift);
	local _Regrowth, _Regrowth_RDY = ConRO:AbilityReady(Ability.Regrowth, timeShift);
		local _PredatorySwiftness_BUFF = ConRO:Aura(Buff.PredatorySwiftness, timeShift);

--Rotations	
	if _Regrowth_RDY and _PredatorySwiftness_BUFF and _Player_Percent_Health <= 95 then
		tinsert(ConRO.SuggestedDefSpells, _Regrowth);
	end

	if _Renewal_RDY and _Player_Percent_Health <= 60 then
		tinsert(ConRO.SuggestedDefSpells, _Renewal);
	end

	if _Barkskin_RDY then
		tinsert(ConRO.SuggestedDefSpells, _Barkskin);
	end

	if _SurvivalInstincts_RDY then
		tinsert(ConRO.SuggestedDefSpells, _SurvivalInstincts);
	end
return nil;
end

function ConRO.Druid.Guardian(_, timeShift, currentSpell, gcd, tChosen, pvpChosen)
	wipe(ConRO.SuggestedSpells);
	ConRO:Stats();
	local Ability, Form, Buff, Debuff, PetAbility, PvPTalent = ids.Guard_Ability, ids.Guard_Form, ids.Guard_Buff, ids.Guard_Debuff, ids.Guard_PetAbility, ids.Guard_PvPTalent;

--Abilities	
	local _BearForm, _BearForm_RDY = ConRO:AbilityReady(Ability.BearForm, timeShift);
		local _BearForm_FORM = ConRO:Form(Form.BearForm);
	local _Berserk, _Berserk_RDY = ConRO:AbilityReady(Ability.BerserkPersistence, timeShift);
	local _ConvoketheSpirits, _ConvoketheSpirits_RDY = ConRO:AbilityReady(Ability.ConvoketheSpirits, timeShift);
	local _Growl, _Growl_RDY = ConRO:AbilityReady(Ability.Growl, timeShift);
	local _HeartoftheWild, _HeartoftheWild_RDY = ConRO:AbilityReady(Ability.HeartoftheWild, timeShift);
	local _LunarBeam, _LunarBeam_RDY = ConRO:AbilityReady(Ability.LunarBeam, timeShift);
	local _Mangle, _Mangle_RDY = ConRO:AbilityReady(Ability.Mangle, timeShift);
	local _MarkoftheWild, _MarkoftheWild_RDY = ConRO:AbilityReady(Ability.MarkoftheWild, timeShift);
	local _Maul, _Maul_RDY = ConRO:AbilityReady(Ability.Maul, timeShift);
		local _Ravage_BUFF = ConRO:Aura(Buff.Ravage, timeShift);
		local _ToothandClaw_BUFF = ConRO:Aura(Buff.ToothandClaw, timeShift);
	local _Moonfire, _Moonfire_RDY = ConRO:AbilityReady(Ability.Moonfire, timeShift);
		local _GalacticGuardian_BUFF = ConRO:Aura(Buff.GalacticGuardian, timeShift);
		local _Moonfire_DEBUFF = ConRO:TargetAura(Debuff.Moonfire, timeShift);
	local _Pulverize, _Pulverize_RDY = ConRO:AbilityReady(Ability.Pulverize, timeShift);
		local _Pulverize_BUFF = ConRO:Aura(Buff.Pulverize, timeShift + 3);
	local _RageoftheSleeper, _RageoftheSleeper_RDY = ConRO:AbilityReady(Ability.RageoftheSleeper, timeShift);
	local _SkullBash, _SkullBash_RDY = ConRO:AbilityReady(Ability.SkullBash, timeShift);
	local _Soothe, _Soothe_RDY = ConRO:AbilityReady(Ability.Soothe, timeShift);
	local _Swipe, _Swipe_RDY = ConRO:AbilityReady(Ability.Swipe, timeShift);
	local _Thrash, _Thrash_RDY = ConRO:AbilityReady(Ability.Thrash, timeShift);
		local _ThrashCF_DEBUFF, _, _ThrashCF_DUR = ConRO:TargetAura(Debuff.ThrashCF, timeShift);
		local _ThrashBF_DEBUFF, _ThrashBF_COUNT = ConRO:TargetAura(Debuff.ThrashBF, timeShift);
	local _WildCharge, _WildCharge_RDY = ConRO:AbilityReady(Ability.WildCharge, timeShift);
		local _, _WildCharge_RANGE = ConRO:Targets(Ability.WildCharge)

--Conditions
	if _BearForm_FORM then
		_WildCharge = ConRO:AbilityReady(Ability.WildChargeBF, timeShift);
		_Thrash, _Thrash_RDY = ConRO:AbilityReady(Ability.ThrashBF, timeShift);
		_Swipe, _Swipe_RDY = ConRO:AbilityReady(Ability.SwipeBF, timeShift);
	end

	if _CatForm_FORM then
		_WildCharge = ConRO:AbilityReady(Ability.WildChargeCF, timeShift);
		_Thrash, _Thrash_RDY = ConRO:AbilityReady(Ability.ThrashCF, timeShift);
		_Swipe, _Swipe_RDY = ConRO:AbilityReady(Ability.SwipeCF, timeShift);
	end

	if tChosen[Ability.IncarnationGuardianofUrsoc.talentID] then
		_Berserk, _Berserk_RDY = ConRO:AbilityReady(Ability.IncarnationGuardianofUrsoc, timeShift);
	end

	if not _Ravage_BUFF and ((ConRO_AutoButton:IsVisible() and _enemies_in_melee >= 3) or ConRO_AoEButton:IsVisible()) then
		_Maul, _Maul_RDY = ConRO:AbilityReady(Ability.Raze, timeShift);
	end

--Indicators
	ConRO:AbilityInterrupt(_SkullBash, _SkullBash_RDY and ConRO:Interrupt());
	ConRO:AbilityPurge(_Soothe, _Soothe_RDY and ConRO:Purgable());
	ConRO:AbilityMovement(_WildCharge, _WildCharge_RDY and _WildCharge_RANGE);

	ConRO:AbilityTaunt(_Growl, _Growl_RDY and (not ConRO:InRaid() or (ConRO:InRaid() and ConRO:TarYou())));

	ConRO:AbilityBurst(_RageoftheSleeper, _RageoftheSleeper_RDY and ConRO:BurstMode(_RageoftheSleeper));
	ConRO:AbilityBurst(_HeartoftheWild, _HeartoftheWild_RDY and ConRO:BurstMode(_HeartoftheWild));
	ConRO:AbilityBurst(_ConvoketheSpirits, _ConvoketheSpirits_RDY and ConRO:BurstMode(_ConvoketheSpirits));
	ConRO:AbilityBurst(_Berserk, _Berserk_RDY and ConRO:BurstMode(_Berserk));

	ConRO:AbilityRaidBuffs(_MarkoftheWild, _MarkoftheWild_RDY and not ConRO:RaidBuff(Buff.MarkoftheWild));

--Rotations	
	repeat
		while(true) do
			if _BearForm_RDY and not _BearForm_FORM then
				tinsert(ConRO.SuggestedSpells, _BearForm);
				_BearForm_FORM = true;
				_Queue = _Queue + 1;
				break;
			end

			if _HeartoftheWild_RDY and ConRO:FullMode(_HeartoftheWild) then
				tinsert(ConRO.SuggestedSpells, _HeartoftheWild);
				_HeartoftheWild_RDY = false;
				_Queue = _Queue + 1;
				break;
			end

			if _Moonfire_RDY and not _Moonfire_DEBUFF then
				tinsert(ConRO.SuggestedSpells, _Moonfire);
				_Moonfire_DEBUFF = true;
				_Queue = _Queue + 1;
				break;
			end

			if _Maul_RDY and _Ravage_BUFF then
				tinsert(ConRO.SuggestedSpells, _Maul);
				_Ravage_BUFF = false;
				_Queue = _Queue + 1;
				break;
			end

			if _Thrash_RDY then
				tinsert(ConRO.SuggestedSpells, _Thrash);
				_Thrash_RDY = false;
				_Queue = _Queue + 1;
				break;
			end

			if _Mangle_RDY then
				tinsert(ConRO.SuggestedSpells, _Mangle);
				_Mangle_RDY = false;
				_Queue = _Queue + 1;
				break;
			end

			if _Berserk_RDY and ConRO:FullMode(_Berserk) then
				tinsert(ConRO.SuggestedSpells, _Berserk);
				_Berserk_RDY = false;
				_Queue = _Queue + 1;
				break;
			end

			if _ConvoketheSpirits_RDY and ConRO:FullMode(_ConvoketheSpirits) then
				tinsert(ConRO.SuggestedSpells, _ConvoketheSpirits);
				_ConvoketheSpirits_RDY = false;
				_Queue = _Queue + 1;
				break;
			end

			if _LunarBeam_RDY and ConRO:FullMode(_LunarBeam) then
				tinsert(ConRO.SuggestedSpells, _LunarBeam);
				_LunarBeam_RDY = false;
				_Queue = _Queue + 1;
				break;
			end

			if _RageoftheSleeper_RDY and ConRO:FullMode(_RageoftheSleeper) then
				tinsert(ConRO.SuggestedSpells, _RageoftheSleeper);
				_RageoftheSleeper_RDY = false;
				_Queue = _Queue + 1;
				break;
			end

			if _Maul_RDY and _Rage >= 80 then
				tinsert(ConRO.SuggestedSpells, _Maul);
				_Rage = _Rage - 40;
				_Queue = _Queue + 1;
				break;
			end

			if _Maul_RDY and _ToothandClaw_BUFF then
				tinsert(ConRO.SuggestedSpells, _Maul);
				_ToothandClaw_BUFF = false;
				_Queue = _Queue + 1;
				break;
			end

			if _Moonfire_RDY and _GalacticGuardian_BUFF then
				tinsert(ConRO.SuggestedSpells, _Moonfire);
				_GalacticGuardian_BUFF = false;
				_Queue = _Queue + 1;
				break;
			end

			if _Pulverize_RDY and not _Pulverize_BUFF and _Thrash_COUNT >= 2 then
				tinsert(ConRO.SuggestedSpells, _Pulverize);
				_Pulverize_RDY = false;
				_Queue = _Queue + 1;
				break;
			end

			tinsert(ConRO.SuggestedSpells, _Swipe); --Waiting Spell Icon  289603
			_Queue = _Queue + 3;
			break;
		end
	until _Queue >= 3;
return nil;
end

function ConRO.Druid.GuardianDef(_, timeShift, currentSpell, gcd, tChosen, pvpChosen)
	wipe(ConRO.SuggestedDefSpells);
	ConRO:Stats();
	local Ability, Form, Buff, Debuff, PetAbility, PvPTalent = ids.Guard_Ability, ids.Guard_Form, ids.Guard_Buff, ids.Guard_Debuff, ids.Guard_PetAbility, ids.Guard_PvPTalent;

--Abilities
	local _Barkskin, _Barkskin_RDY = ConRO:AbilityReady(Ability.Barkskin, timeShift);
		local _Barkskin_BUFF = ConRO:Aura(Buff.Barkskin, timeShift);
	local _BristlingFur, _BristlingFur_RDY = ConRO:AbilityReady(Ability.BristlingFur, timeShift);
	local _FrenziedRegeneration, _FrenziedRegeneration_RDY = ConRO:AbilityReady(Ability.FrenziedRegeneration, timeShift);
	local _Ironfur, _Ironfur_RDY = ConRO:AbilityReady(Ability.Ironfur, timeShift);
		local _Ironfur_BUFF, _Ironfur_COUNT = ConRO:Aura(Buff.Ironfur, timeShift);
	local _SurvivalInstincts, _SurvivalInstincts_RDY = ConRO:AbilityReady(Ability.SurvivalInstincts, timeShift);
		local _SurvivalInstincts_BUFF = ConRO:Aura(Buff.SurvivalInstincts, timeShift);

--Rotations	
	if _FrenziedRegeneration_RDY and _Player_Percent_Health <= 60 then
		tinsert(ConRO.SuggestedDefSpells, _FrenziedRegeneration);
	end

	if _BristlingFur_RDY and ConRO:TarYou() then
		tinsert(ConRO.SuggestedDefSpells, _BristlingFur);
	end

	if _Barkskin_RDY and not _IncarnationGuardianofUrsoc_BUFF and not _SurvivalInstincts_BUFF and _Player_Percent_Health <= 75 then
		tinsert(ConRO.SuggestedDefSpells, _Barkskin);
	end

	if _SurvivalInstincts_RDY and not _Barkskin_BUFF and not _IncarnationGuardianofUrsoc_BUFF and _Player_Percent_Health <= 75 then
		tinsert(ConRO.SuggestedDefSpells, _SurvivalInstincts);
	end

	if _Ironfur_RDY and ConRO:TarYou() and _Ironfur_COUNT < 7 then
		tinsert(ConRO.SuggestedDefSpells, _Ironfur);
	end
return nil;
end

function ConRO.Druid.Restoration(_, timeShift, currentSpell, gcd, tChosen, pvpChosen)
	wipe(ConRO.SuggestedSpells);
	ConRO:Stats();
	local Ability, Form, Buff, Debuff, PetAbility, PvPTalent = ids.Resto_Ability, ids.Resto_Form, ids.Resto_Buff, ids.Resto_Debuff, ids.Resto_PetAbility, ids.Resto_PvPTalent;

--Abilities
	local _BearForm, _BearForm_RDY = ConRO:AbilityReady(Ability.BearForm, timeShift);
		local _BearForm_FORM = ConRO:Form(Form.BearForm);
		local _CatForm_FORM	= ConRO:Form(Form.CatForm);
	local _ConvoketheSpirits, _ConvoketheSpirits_RDY = ConRO:AbilityReady(Ability.ConvoketheSpirits, timeShift);
	local _FerociousBite, _FerociousBite_RDY = ConRO:AbilityReady(Ability.FerociousBite, timeShift);
	local _Lifebloom, _Lifebloom_RDY = ConRO:AbilityReady(Ability.Lifebloom, timeShift);
		local _Lifebloom_BUFF = ConRO:Aura(Buff.Lifebloom, timeShift);
	local _Mangle, _Mangle_RDY = ConRO:AbilityReady(Ability.Mangle, timeShift);
	local _MarkoftheWild, _MarkoftheWild_RDY = ConRO:AbilityReady(Ability.MarkoftheWild, timeShift);
		local _MarkoftheWild_BUFF = ConRO:Aura(Buff.MarkoftheWild, timeShift);
	local _Moonfire, _Moonfire_RDY = ConRO:AbilityReady(Ability.Moonfire, timeShift);
		local _Moonfire_DEBUFF = ConRO:TargetAura(Debuff.Moonfire, timeShift + 2);
	local _Rake, _Rake_RDY = ConRO:AbilityReady(Ability.Rake, timeShift);
		local _Rake_DEBUFF, _, _Rake_DUR = ConRO:TargetAura(Debuff.Rake, timeShift);
	local _Regrowth, _Regrowth_RDY = ConRO:AbilityReady(Ability.Regrowth, timeShift);
	local _Rip, _Rip_RDY = ConRO:AbilityReady(Ability.Rip, timeShift);
		local _Rip_DEBUFF, _, _Rip_DUR = ConRO:TargetAura(Debuff.Rip, timeShift);
	local _Shred, _Shred_RDY = ConRO:AbilityReady(Ability.Shred, timeShift);
	local _SkullBash, _SkullBash_RDY = ConRO:AbilityReady(Ability.SkullBash, timeShift);
	local _Soothe, _Soothe_RDY = ConRO:AbilityReady(Ability.Soothe, timeShift);
	local _Starfire, _Starfire_RDY = ConRO:AbilityReady(Ability.Starfire, timeShift);
		local _EclipseSolar_BUFF, _, _EclipseSolar_DUR = ConRO:Aura(Buff.EclipseSolar, timeShift);
	local _Starsurge, _Starsurge_RDY = ConRO:AbilityReady(Ability.Starsurge, timeShift);
	local _Sunfire, _Sunfire_RDY = ConRO:AbilityReady(Ability.Sunfire, timeShift);
		local _Sunfire_DEBUFF = ConRO:TargetAura(Debuff.Sunfire, timeShift + 2);
	local _Swipe, _Swipe_RDY = ConRO:AbilityReady(Ability.Swipe, timeShift);
	local _Thrash, _Thrash_RDY = ConRO:AbilityReady(Ability.Thrash, timeShift);
		local _ThrashCF_DEBUFF, _, _ThrashCF_DUR = ConRO:TargetAura(Debuff.ThrashCF, timeShift);
		local _ThrashBF_DEBUFF, _ThrashBF_COUNT = ConRO:TargetAura(Debuff.ThrashBF, timeShift);
	local _Tranquility, _Tranquility_RDY = ConRO:AbilityReady(Ability.Tranquility, timeShift);
	local _Typhoon, _Typhoon_RDY = ConRO:AbilityReady(Ability.Typhoon, timeShift);
	local _WildCharge, _WildCharge_RDY = ConRO:AbilityReady(Ability.WildCharge, timeShift);
		local _, _WildCharge_RANGE = ConRO:Targets(Ability.WildCharge)
	local _Wrath, _Wrath_RDY = ConRO:AbilityReady(Ability.Wrath, timeShift);
		local _EclipseLunar_BUFF, _, _EclipseLunar_DUR = ConRO:Aura(Buff.EclipseLunar, timeShift);

--Conditions
	if _BearForm_FORM then
		_WildCharge = ConRO:AbilityReady(Ability.WildChargeBF, timeShift);
		_Thrash, _Thrash_RDY = ConRO:AbilityReady(Ability.ThrashBF, timeShift);
		_Swipe, _Swipe_RDY = ConRO:AbilityReady(Ability.SwipeBF, timeShift);
	end

	if _CatForm_FORM then
		_WildCharge = ConRO:AbilityReady(Ability.WildChargeCF, timeShift);
		_Thrash, _Thrash_RDY = ConRO:AbilityReady(Ability.ThrashCF, timeShift);
		_Swipe, _Swipe_RDY = ConRO:AbilityReady(Ability.SwipeCF, timeShift);
	end

--Indicators
	ConRO:AbilityInterrupt(_SkullBash, _SkullBash_RDY and (_BearForm_FORM or _CatForm_FORM) and ConRO:Interrupt());
	ConRO:AbilityPurge(_Soothe, _Soothe_RDY and ConRO:Purgable());

	ConRO:AbilityBurst(_ConvoketheSpirits, _ConvoketheSpirits_RDY and _in_combat);
	ConRO:AbilityBurst(_Tranquility, _Tranquility_RDY);

	ConRO:AbilityRaidBuffs(_Lifebloom, _Lifebloom_RDY and not ConRO:OneBuff(Buff.Lifebloom));
	ConRO:AbilityRaidBuffs(_MarkoftheWild, _MarkoftheWild_RDY and not ConRO:RaidBuff(Buff.MarkoftheWild));

	ConRO:AbilityMovement(_WildCharge, _WildCharge_RDY and (_BearForm_FORM or _CatForm_FORM) and _WildCharge_RANGE);

--Rotations
	repeat
		while(true) do
			if _is_Enemy then
				if _BearForm_FORM then
					if _Thrash_RDY and _ThrashBF_COUNT < 3 then
						tinsert(ConRO.SuggestedSpells, _Thrash);
						_ThrashBF_COUNT = _ThrashBF_COUNT + 1;
						_Queue = _Queue + 1;
						break;
					end

					if _Mangle_RDY then
						tinsert(ConRO.SuggestedSpells, _Mangle);
						_Mangle_RDY = false;
						_Queue = _Queue + 1;
						break;
					end

					tinsert(ConRO.SuggestedSpells, _Swipe); --Waiting Spell Icon  289603
					_Queue = _Queue + 3;
					break;
				end

				if _CatForm_FORM then
					if _Rip_RDY and _Energy >= 20 and (not _Rip_DEBUFF or _Rip_DUR <= 7) and _Combo >= 5 then
						tinsert(ConRO.SuggestedSpells, _Rip);
						_Rip_DEBUFF = true;
						_Rip_DUR = 24;
						_Energy = _Energy - 20;
						_Combo = 0;
						_Queue = _Queue + 1;
						break;
					end

					if _FerociousBite_RDY and _Energy >= 25 and _Combo >= 5 then
						tinsert(ConRO.SuggestedSpells, _FerociousBite);
						_Energy = _Energy - 25;
						_Combo = 0;
						_Queue = _Queue + 1;
						break;
					end

					if _Thrash_RDY and _Energy >= 40 and (not _ThrashCF_DEBUFF or _ThrashCF_DUR <= 4) and _enemies_in_melee >= 3 then
						tinsert(ConRO.SuggestedSpells, _Thrash);
						_ThrashCF_DUR = 15;
						_Energy = _Energy - 40;
						_Combo = _Combo + 1;
						_Queue = _Queue + 1;
						break;
					end

					if _Rake_RDY and _Energy >= 35 and (not _Rake_DEBUFF or _Rake_DUR <= 4) then
						tinsert(ConRO.SuggestedSpells, _Rake);
						_Rake_DEBUFF = true;
						_Rake_DUR = 15;
						_Energy = _Energy - 35;
						_Combo = _Combo + 1;
						_Queue = _Queue + 1;
						break;
					end

					if _Swipe_RDY and _Energy >= 35 and _Combo <= 4 and _enemies_in_melee >= 3 then
						tinsert(ConRO.SuggestedSpells, _Swipe);
						_Energy = _Energy - 35;
						_Combo = _Combo + 1;
						_Queue = _Queue + 1;
						break;
					end

					if _Shred_RDY and _Energy >= 40 and _Combo <= 4 then
						tinsert(ConRO.SuggestedSpells, _Shred);
						_Energy = _Energy - 40;
						_Combo = _Combo + 1;
						_Queue = _Queue + 1;
						break;
					end

					tinsert(ConRO.SuggestedSpells, 289603); --Waiting Spell Icon
					_Queue = _Queue + 3;
					break;
				end

				if _Moonfire_RDY and not _Moonfire_DEBUFF then
					tinsert(ConRO.SuggestedSpells, _Moonfire);
					_Moonfire_DEBUFF = true;
					_Queue = _Queue + 1;
					break;
				end

				if _Sunfire_RDY and not _Sunfire_DEBUFF then
					tinsert(ConRO.SuggestedSpells, _Sunfire);
					_Sunfire_DEBUFF = true;
					_Queue = _Queue + 1;
					break;
				end

				if _Starsurge_RDY then
					tinsert(ConRO.SuggestedSpells, _Starsurge);
					_Starsurge_RDY = false;
					_Queue = _Queue + 1;
					break;
				end

				if _Starfire_RDY then
					tinsert(ConRO.SuggestedSpells, _Starfire);
					_Queue = _Queue + 1;
					break;
				end

				if _Wrath_RDY then
					tinsert(ConRO.SuggestedSpells, _Wrath);
					_Queue = _Queue + 1;
					break;
				end
			end

			tinsert(ConRO.SuggestedSpells, 289603); --Waiting Spell Icon
			_Queue = _Queue + 3;
			break;
		end
	until _Queue >= 3;
return nil;
end

function ConRO.Druid.RestorationDef(_, timeShift, currentSpell, gcd, tChosen, pvpChosen)
	wipe(ConRO.SuggestedDefSpells);
	ConRO:Stats();
	local Ability, Form, Buff, Debuff, PetAbility, PvPTalent = ids.Resto_Ability, ids.Resto_Form, ids.Resto_Buff, ids.Resto_Debuff, ids.Resto_PetAbility, ids.Resto_PvPTalent;

--Abilities
	local _Barkskin, _Barkskin_RDY = ConRO:AbilityReady(Ability.Barkskin, timeShift);
	local _Renewal, _Renewal_RDY = ConRO:AbilityReady(Ability.Renewal, timeShift);

--Rotations	
	if _Renewal_RDY and _Player_Percent_Health <= 60 then
		tinsert(ConRO.SuggestedDefSpells, _Renewal);
	end

	if _Barkskin_RDY then
		tinsert(ConRO.SuggestedDefSpells, _Barkskin);
	end
return nil;
end
