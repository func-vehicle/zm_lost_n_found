#using scripts\codescripts\struct;

#using scripts\shared\array_shared;
#using scripts\shared\clientfield_shared;
#using scripts\shared\system_shared;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;

#insert scripts\zm\_zm_lost_n_found.gsh;

#namespace zm_lost_n_found;


REGISTER_SYSTEM( "zm_lost_n_found", &__init__, undefined )

function __init__()
{
	clientfield::register( "clientuimodel", "zmhud.lnfPercentage", VERSION_SHIP, 7, "float", &lerp_percentage, !CF_HOST_ONLY, !CF_CALLBACK_ZERO_ON_NEW_ENT );
}

function animation_update( model, oldValue, newValue )
{
	self endon( "new_val" );
	startTime = GetRealTime();
	timeSinceLastUpdate = 0;
	
	while( timeSinceLastUpdate <= 1.0 )
	{
		timeSinceLastUpdate = ( ( GetRealTime() - startTime ) / 1000.0 );
		lerpValue = LerpFloat( oldValue, newValue, timeSinceLastUpdate );
		SetUIModelValue( model, lerpValue );
		WAIT_CLIENT_FRAME;
	}
}

function lerp_percentage( localClientNum, oldVal, newVal, bNewEnt, bInitialSnap, fieldName, bWasTimeJump )
{
	model = GetUIModel( GetUIModelForController(localClientNum), "zmhud.lnfPercentage" );
	if ( IsDefined( model ) )
	{
		if ( newVal == 1 )
		{
			SetUIModelValue( model, 1.0 );
		}
		self notify( "new_val" );
		self thread animation_update( model, newVal, newVal - 1/ZM_LOST_N_FOUND_DURATION );
	}
}