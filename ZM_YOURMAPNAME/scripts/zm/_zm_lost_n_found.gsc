#using scripts\codescripts\struct;

#using scripts\shared\array_shared;
#using scripts\shared\clientfield_shared;
#using scripts\shared\callbacks_shared;
#using scripts\shared\flag_shared;
#using scripts\shared\gameobjects_shared;
#using scripts\shared\laststand_shared;
#using scripts\shared\math_shared;
#using scripts\shared\system_shared;
#using scripts\shared\util_shared;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;

#using scripts\zm\_zm_audio;
#using scripts\zm\_zm_bgb;
#using scripts\zm\_zm_equipment;
#using scripts\zm\_zm_pack_a_punch_util;
#using scripts\zm\_zm_perks;
#using scripts\zm\_zm_score;
#using scripts\zm\_zm_unitrigger;
#using scripts\zm\_zm_utility;
#using scripts\zm\_zm_weapons;
#using scripts\zm\_zm_weap_riotshield;

#insert scripts\zm\_zm_perks.gsh;

#insert scripts\zm\_zm_lost_n_found.gsh;

#precache( "objective", "zm_lnf_waypoint" );

#precache( "triggerstring", "LOSTNFOUND_RECOVER_WEAPONS", "2000" );

#namespace zm_lost_n_found;


function autoexec __init__sytem__()
{
	reqs = [];
	reqs[0] = "zm_bgb_ephemeral_enhancement";
	reqs[1] = "zm_bgb_disorderly_combat";
	system::register("zm_lost_n_found", &__init__, &__main__, reqs);
}

function __init__()
{
	callback::on_connect(&on_player_connect);

	clientfield::register( "clientuimodel", "zmhud.lnfPercentage", VERSION_SHIP, 7, "float" );
}

function __main__()
{
	level.lnf_recover_points = struct::get_array( "lnf_recover_point", "targetname" );
	
	if (level.lnf_recover_points.size == 0)
	{
		callback::remove_on_connect(&on_player_connect);
		return;
	}
	
	level.lnf_active_players = [];
	
	lnf_init();

	// Override Ephemeral Enhancement validation function to save weapon and ammo
	level.original_ephemeral_enhancement_validation_func = level.bgb["zm_bgb_ephemeral_enhancement"].validation_func;
	level.bgb["zm_bgb_ephemeral_enhancement"].validation_func = &ephemeral_enhancement_validation_func_override;

	// Override Disorderly Combat enable function to save weapons and ammo
	level.original_disorderly_combat_enable_func = level.bgb["zm_bgb_disorderly_combat"].enable_func;
	level.bgb["zm_bgb_disorderly_combat"].enable_func = &disorderly_combat_enable_func_override;
	// Override Disorderly Combat disable function
	level.original_disorderly_combat_disable_func = level.bgb["zm_bgb_disorderly_combat"].disable_func;
	level.bgb["zm_bgb_disorderly_combat"].disable_func = &disorderly_combat_disable_func_override;

	//thread debug_lnf();
}

function private ephemeral_enhancement_validation_func_override()
{
	will_activate = self [[level.original_ephemeral_enhancement_validation_func]]();
	if (will_activate)
	{
		self.ephemeral_original_weapon = self GetCurrentWeapon();
		self.ephemeral_original_weapon_clipAmmo = self GetWeaponAmmoClip(self.ephemeral_original_weapon);
		self.ephemeral_original_weapon_leftClipAmmo = 0;
		dual_wield_weapon = self.ephemeral_original_weapon.dualWieldWeapon;
		if ( level.weaponNone != dual_wield_weapon )
		{
			self.ephemeral_original_weapon_leftClipAmmo = self GetWeaponAmmoClip( dual_wield_weapon );
		}
		self.ephemeral_original_weapon_stockAmmo = self GetWeaponAmmoStock(self.ephemeral_original_weapon);

		self thread ephemeral_on_complete();
	}
	return will_activate;
}

// TODO: Validation is run twice when using BGB, once on press and once when the bubble animation finishes
//       If second check fails, the activation is cancelled and this will never run after saving info!
function private ephemeral_on_complete()
{
	self waittill("activation_complete");
	self.ephemeral_original_weapon = undefined;
	self.ephemeral_original_weapon_clipAmmo = undefined;
	self.ephemeral_original_weapon_leftClipAmmo = undefined;
	self.ephemeral_original_weapon_stockAmmo = undefined;
}

function private disorderly_combat_enable_func_override()
{
	self.disorderly_original_weapons = self GetWeaponsListPrimaries();
	self [[level.original_disorderly_combat_enable_func]]();
}

function private disorderly_combat_disable_func_override()
{
	self.disorderly_original_weapons = undefined;
	self [[level.original_disorderly_combat_disable_func]]();
}

function debug_lnf()
{
	level flag::wait_till( "initial_blackscreen_passed" );
	wait(1.0);

	foreach (player in GetPlayers())
	{
		player thread show_lnf();
	}
}

function lnf_init()
{
	foreach(point in level.lnf_recover_points)
	{
		point setup_unitrigger();
		thread zm_unitrigger::register_static_unitrigger(point.unitrigger_stub, &lnf_unitrigger_think);
	}
	
	array::thread_all( level.lnf_recover_points, &lnf_recover_point_think );
}

// Run when player connects
function private on_player_connect()
{
	self endon("disconnect");

	// Watch for downs
	self thread save_loadout_on_down();
	
	// Ignore initial spawn
	self waittill("spawned_player");
	
	// Show LnF on every subsequent respawn
	for(;;)
	{
		self waittill("spawned_player");
		self on_respawn();
		wait(0.1);  // Short wait to fix double notify
	}
}

function private on_respawn()
{
	self thread show_lnf();
}

function private save_loadout_on_down()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("player_downed");
		loadout = [];
		loadout_ammo = [];

		foreach (weapon in self GetWeaponsList( true ))
		{
			w_base = zm_weapons::get_base_weapon(weapon);

			// Skip hero weapons
			if ( zm_utility::is_hero_weapon( weapon ) )
			{
				continue;
			}
			// Skip flourish weapons
			if ( weapon.isFlourishWeapon || weapon.isPerkBottle )
			{
				continue;
			}
			// Skip last stand pistol if the player did not have it
			if ( IsDefined( self.hadpistol ) && !self.hadpistol && IsDefined( self.laststandpistol ) && weapon == self.laststandpistol )
			{
				continue;
			}
			// Riot shield
			if ( IsDefined(self.weaponRiotshield) && weapon == self.weaponRiotshield )
			{
				health = self DamageRiotShield(0); 
				array::add(loadout, weapon);
				loadout_ammo[weapon] = SpawnStruct();
				loadout_ammo[weapon].clipAmmo = self GetWeaponAmmoClip(weapon);
				loadout_ammo[weapon].health = health;
				continue;
			}
			// Use unupgraded weapon if is Ephemeral Enhancement upgraded weapon
			if (IsDefined(self.ephemeral_original_weapon) && self.ephemeral_original_weapon == w_base)
			{
				array::add(loadout, self.ephemeral_original_weapon);
				loadout_ammo[self.ephemeral_original_weapon] = SpawnStruct();
				loadout_ammo[self.ephemeral_original_weapon].clipAmmo = self.ephemeral_original_weapon_clipAmmo;
				loadout_ammo[self.ephemeral_original_weapon].leftClipAmmo = self.ephemeral_original_weapon_leftClipAmmo;
				loadout_ammo[self.ephemeral_original_weapon].stockAmmo = self.ephemeral_original_weapon_stockAmmo;
				continue;
			}
			// Only look at original primaries if Disorderly Combat active
			if ( weapon.isPrimary && IsDefined(self.disorderly_original_weapons) && !array::contains(self.disorderly_original_weapons, weapon) )
			{
				continue;
			}
			// A regular weapon
			array::add(loadout, weapon);
			loadout_ammo[weapon] = SpawnStruct();
			// If weapon is the last stand pistol, use pre-downed ammo values
			if (IsDefined(self.laststandpistol) && weapon == self.laststandpistol && IsDefined(self.stored_weapon_info) && IsDefined(self.stored_weapon_info[ weapon ]))
			{
				loadout_ammo[weapon].clipAmmo = self.stored_weapon_info[ weapon ].clip_amt;
				loadout_ammo[weapon].leftClipAmmo = self.stored_weapon_info[ weapon ].left_clip_amt;
				loadout_ammo[weapon].stockAmmo = self.stored_weapon_info[ weapon ].stock_amt;
			}
			else
			{
				loadout_ammo[weapon].clipAmmo = self GetWeaponAmmoClip(weapon);
				loadout_ammo[weapon].leftClipAmmo = 0;
				dual_wield_weapon = weapon.dualWieldWeapon;
				if ( level.weaponNone != dual_wield_weapon )
				{
					loadout_ammo[weapon].leftClipAmmo = self GetWeaponAmmoClip( dual_wield_weapon );
				}
				loadout_ammo[weapon].stockAmmo = self GetWeaponAmmoStock(weapon);
			}
		}
		// Tactical grenade
		tactical = self zm_utility::get_player_tactical_grenade();
		if (tactical != level.weaponNone)
		{
			array::add(loadout, tactical);
			loadout_ammo[tactical] = SpawnStruct();
			loadout_ammo[tactical].clipAmmo = self.lsgsar_tactical_nade_amt;
		}
		// Lethal grenade
		lethal = self zm_utility::get_player_lethal_grenade();
		if (lethal != level.weaponNone)
		{
			array::add(loadout, lethal);
			loadout_ammo[lethal] = SpawnStruct();
			loadout_ammo[lethal].clipAmmo = self.lsgsar_lethal_nade_amt;
		}
		// Mule kick weapon has lowest priority in being returned
		if (IsDefined(self.weapon_taken_by_losing_specialty_additionalprimaryweapon) && self.weapon_taken_by_losing_specialty_additionalprimaryweapon != level.weaponNone)
		{
			weapon = self.weapon_taken_by_losing_specialty_additionalprimaryweapon;
			weapondata = self.weapons_taken_by_losing_specialty_additionalprimaryweapon[weapon];
			array::add(loadout, weapon);
			if (IsDefined(weapondata))
			{
				loadout_ammo[weapon] = SpawnStruct();
				loadout_ammo[weapon].clipAmmo = weapondata["clip"];
				loadout_ammo[weapon].leftClipAmmo = weapondata["lh_clip"];
				loadout_ammo[weapon].stockAmmo = weapondata["stock"];
			}
		}

		self.lnf_saved_loadout = loadout;
		self.lnf_saved_loadout_ammo = loadout_ammo;
	}
}

function show_lnf()
{
	self endon("disconnect");
	self endon("lnf_recovered_weapons");

	// Copy saved loadout + ammo so it is not overwritten if player downs getting to LnF
	self.lnf_active_loadout = self.lnf_saved_loadout;
	self.lnf_active_loadout_ammo = self.lnf_saved_loadout_ammo;
	// Store grenade player had prior to Widow's Wine
	if (IsDefined(self.w_widows_wine_prev_grenade) && array::contains(self.lnf_active_loadout, level.w_widows_wine_grenade))
	{
		self.lnf_widows_wine_prev_grenade = self.w_widows_wine_prev_grenade;
	}
	
	// Enable hint and show UI element for Lost 'n' Found
	array::add(level.lnf_active_players, self, false);

	self.lnf_objID_array = [];
	for (i = 0; i < level.lnf_recover_points.size; i++)
	{
		self.lnf_objID_array[i] = gameobjects::get_next_obj_id();
		Objective_Add( self.lnf_objID_array[i], "active", level.lnf_recover_points[i].origin, &"zm_lnf_waypoint" );
		Objective_SetInvisibleToAll( self.lnf_objID_array[i] );
		Objective_SetVisibleToPlayer( self.lnf_objID_array[i], self );
	}
	
	self thread run_timer();
	
	// Wait for timeout / bleed out
	reason = self util::waittill_any_timeout( ZM_LOST_N_FOUND_DURATION, "bled_out" );
	
	// Player did not recover weapons from Lost 'n' Found in time
	self end_lnf();
}

function end_lnf()
{
	// Clear active LnF loadout
	self.lnf_active_loadout = undefined;
	self.lnf_active_loadout_ammo = undefined;
	self.lnf_widows_wine_prev_grenade = undefined;

	// Disable hint and hide UI element for Lost 'n' Found
	level.lnf_active_players = array::exclude(level.lnf_active_players, self);

	//Objective_State( self.lnf_objID, "done" );
	//wait(1.0);
	for (i = 0; i < self.lnf_objID_array.size; i++)
	{
		gameobjects::release_obj_id( self.lnf_objID_array[i] );
		Objective_Delete( self.lnf_objID_array[i] );
	}
	
	self.lnf_objID_array = undefined;
}

function run_timer()
{
	self endon("disconnect");
	self endon("lnf_recovered_weapons");
	self endon("bled_out");
	
	for (time = ZM_LOST_N_FOUND_DURATION; time > 0; time--)
	{
		self clientfield::set_player_uimodel( "zmhud.lnfPercentage", time / ZM_LOST_N_FOUND_DURATION );
		wait(1.0);
	}
}

function setup_unitrigger()
{
	self.unitrigger_stub = SpawnStruct();
	self.unitrigger_stub.origin = self.origin;
	self.unitrigger_stub.angles = self.angles;
	self.unitrigger_stub.script_unitrigger_type = "unitrigger_box_use";
	self.unitrigger_stub.script_width = 45;
	self.unitrigger_stub.script_height = 72;
	self.unitrigger_stub.script_length = 45;
	self.unitrigger_stub.trigger_target = self;
	
	zm_unitrigger::unitrigger_force_per_player_triggers(self.unitrigger_stub, true);
	self.unitrigger_stub.prompt_and_visibility_func = &lnf_trigger_update_prompt;
}

function lnf_trigger_update_prompt( player )
{
	can_use = self lnf_stub_update_prompt( player );
	if( IsDefined(self.hint_string) )
	{
		if ( IsDefined(self.hint_parm1) )
			self SetHintString( self.hint_string, self.hint_parm1 );
		else
			self SetHintString( self.hint_string );
	}
	return can_use;
}

function lnf_stub_update_prompt( player )
{
	if (!self trigger_visible_to_player( player ))
		return false;
	
	cost = determine_cost(player);

	if (true)
	{
		self setCursorHint( "HINT_NOICON" );
		self.hint_parm1 = cost;
		self.hint_string = &"LOSTNFOUND_RECOVER_WEAPONS";
	}
	else {
		return false;
	}
	
	return true;
}

function trigger_visible_to_player(player)
{
	self SetInvisibleToPlayer(player);

	visible = true;
	
	if ( !array::contains(level.lnf_active_players, player) )
	{
		visible = false;
	}
	else if( !zm_perks::vending_trigger_can_player_use(player) )
	{
		visible = false;
	}
	else if ( player bgb::is_enabled( "zm_bgb_disorderly_combat" ) )
	{
		visible = false;
	}
	
	if( !visible )
	{
		return false;
	}
	
	self SetVisibleToPlayer(player);
	return true;
}

function lnf_unitrigger_think()
{
	self endon("kill_trigger");

	for(;;)
	{
		self waittill( "trigger", player );
		self.stub.trigger_target notify("trigger", player);
	}
}

function determine_cost(player)
{	
	return 2000;
}

function lnf_recover_point_think()
{
	for(;;)
	{
		// LnF recover point idle
		self waittill( "trigger", player );
		if (player == level)
			continue;
		
		// Player interacts with the point
		cost = determine_cost(player);
		if (cost === false)
			continue;
		
		if( !player zm_score::can_player_purchase( cost ) )
		{
			zm_utility::play_sound_at_pos("no_purchase", self.origin);
			player zm_audio::create_and_play_dialog( "general", "outofmoney" );
			continue;
		}
		
		// Player has paid to reclaim their weapons
		thread zm_unitrigger::unregister_unitrigger(self.unitrigger_stub);
		player zm_score::minus_to_player_score(cost);
		zm_utility::play_sound_at_pos("purchase", self.origin);
		player thread return_weapons();

		wait(0.05);
		thread zm_unitrigger::register_static_unitrigger(self.unitrigger_stub, &lnf_unitrigger_think);
	}
}

function return_weapons()
{
	pap_triggers = zm_pap_util::get_triggers();
	weapon_limit = zm_utility::get_player_weapon_limit(self);
	weapons_given = 0;
	weapon_switched = false;
	
	// Take their current weapons if not in saved loadout
	foreach(weapon in self GetWeaponsListPrimaries())
	{
		if ( !array::contains(self.lnf_active_loadout, weapon) )
		{
			self zm_weapons::weapon_take(weapon);
		}
	}
	
	// Give them their old loadout!
	// TODO: test underbarrels

	// TESTED:
	// Gobblegums (Disorderly Combat, Ephemeral Enhancement, etc)
	// Weapon restoration (+ Mule Kick w/ lower priority)
	// Ammo restoration (incl. Dual Wield)
	// Tactical grenade restoration
	// Lethal grenade restoration
	// Shield restoration
	// Knife restoration
	// Trip mine restoration
	// Downing with Death Machine, BGB animation weapons, perk bottles, flourish weapons
	// Hero weapons are ignored (kept through death is default behaviour)
	// Widow's Wine knife downgrade / upgrade
	// Widow's Wine grenade downgrade / upgrade
	foreach(weapon in self.lnf_active_loadout)
	{
		weapon_to_give = undefined;
		w_base = zm_weapons::get_base_weapon(weapon);
		
		// Return melee
		if (zm_utility::is_melee_weapon(weapon))
		{
			// Account for Widow's Wine melees
			if (StrEndsWith(weapon.name, "_widows_wine"))
			{
				str = GetSubStr(weapon.name, 0, weapon.name.size - 12);
				base_melee = GetWeapon(str);
				widows_wine_melee = weapon;
			}
			else
			{
				base_melee = weapon;
				widows_wine_melee = GetWeapon(weapon.name + "_widows_wine");
			}
			
			if (self HasPerk( PERK_WIDOWS_WINE ) && widows_wine_melee != level.weaponNone)
			{
				self.w_widows_wine_prev_knife = base_melee;
				self zm_weapons::weapon_give(widows_wine_melee, 0, 0, 1, 0);
			}
			else
			{
				self zm_weapons::weapon_give(base_melee, 0, 0, 1, 0);
			}

			continue;
		}
		// Return trip mines
		if (zm_utility::is_placeable_mine(weapon))
		{
			// The player will get a full set of mines
			self zm_weapons::weapon_give(weapon, 0, 0, 1, 0);
			continue;
		}
		// Return tactical grenades
		if (zm_utility::is_tactical_grenade(weapon))
		{
			// The player will have as many tacticals as they died with
			self zm_weapons::weapon_give(weapon, 0, 0, 1, 0);
			if (IsDefined(self.lnf_active_loadout_ammo[weapon]))
			{
				self SetWeaponAmmoClip(weapon, self.lnf_active_loadout_ammo[weapon].clipAmmo);
			}
			continue;
		}
		// Return lethal grenades
		if (zm_utility::is_lethal_grenade(weapon))
		{
			// Account for Widow's Wine grenades
			grenade = weapon;
			if (self HasPerk( PERK_WIDOWS_WINE ))
			{
				grenade = level.w_widows_wine_grenade;
			}
			// Player does not have Widow's Wine now but saved grenade was Widow's Wine grenade
			else if (weapon == level.w_widows_wine_grenade)
			{
				// Try giving the grenade they had before Widow's Wine
				if (IsDefined(self.lnf_widows_wine_prev_grenade))
				{
					grenade = self.lnf_widows_wine_prev_grenade;
				}
				// Use default level grenade
				else
				{
					grenade = level.zombie_lethal_grenade_player_init;
				}
			}
			self zm_weapons::weapon_give(grenade, 0, 0, 1, 0);

			// The player will have as many lethals as they died with
			if (IsDefined(self.lnf_active_loadout_ammo[weapon]))
			{
				self SetWeaponAmmoClip(grenade, self.lnf_active_loadout_ammo[weapon].clipAmmo);
			}
			continue;
		}
		// Return riot shield
		if (weapon.isRiotshield)
		{
			maxHealth = weapon.weaponstarthitpoints;
			self zm_weapons::weapon_give(weapon, 0, 0, 1, 0);
			self SetWeaponAmmoClip(weapon, self.lnf_active_loadout_ammo[weapon].clipAmmo);
			shieldHealth = self DamageRiotShield(maxHealth - self.lnf_active_loadout_ammo[weapon].health);
			self riotshield::UpdateRiotShieldModel();
			self clientfield::set_player_uimodel( "zmInventory.shield_health", shieldHealth / maxHealth );
			continue;
		}
		// Beyond this point, we are dealing with a regular weapon
		// Ensure the player cannot use the LnF to bypass the wonder weapon limit
		if (zm_weapons::limited_weapon_below_quota(w_base, self, pap_triggers))
		{
			weapon_to_give = weapon;
		}
		// Give the weapon if under the limit
		if (IsDefined(weapon_to_give) && weapons_given < weapon_limit)
		{
			if (!self HasWeapon(weapon_to_give))
			{
				self zm_weapons::weapon_give(weapon_to_give, 0, 0, 1, !weapon_switched);
				weapon_switched = true;
			}
			weapons_given++;
			if (IsDefined(self.lnf_active_loadout_ammo[weapon_to_give]))
			{
				self SetWeaponAmmoClip(weapon_to_give, self.lnf_active_loadout_ammo[weapon_to_give].clipAmmo);
				dual_wield_weapon = weapon_to_give.dualWieldWeapon;
				if ( level.weaponNone != dual_wield_weapon )
				{
					self setWeaponAmmoClip(dual_wield_weapon, self.lnf_active_loadout_ammo[weapon_to_give].leftClipAmmo);
				}
				self SetWeaponAmmoStock(weapon_to_give, self.lnf_active_loadout_ammo[weapon_to_give].stockAmmo);
			}
		}
	}
	
	self notify("lnf_recovered_weapons");
	self end_lnf();
}