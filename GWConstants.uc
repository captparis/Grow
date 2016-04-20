class GWConstants extends Object;

enum EForm {
	FORM_NONE,
	FORM_BABY,
	FORM_POWER, FORM_SKILL, FORM_SPEED,
	FORM_POWER_MAX, FORM_SKILL_MAX, FORM_SPEED_MAX,
	FORM_SKILL_POWER, FORM_SPEED_POWER, FORM_SKILL_SPEED
};
enum EFood {
	FOOD_NONE,
	FOOD_MEAT_SMALL, FOOD_MEAT_MEDIUM, FOOD_MEAT_LARGE,
	FOOD_FRUIT_SMALL, FOOD_FRUIT_MEDIUM, FOOD_FRUIT_LARGE,
	FOOD_CANDY_SMALL, FOOD_CANDY_MEDIUM, FOOD_CANDY_LARGE,
	//Special Foods
	FOOD_CHILLI, FOOD_HEAVY, FOOD_LIGHT, FOOD_GRENADE,
	FOOD_SEED, FOOD_SUPER
};
enum EFireMode {
	FIREMODE_ATTACK, FIREMODE_ABILITY,
	FIREMODE_EAT, FIREMODE_CHEW, FIREMODE_SPIT, FIREMODE_SPEW
};

enum EStatusEffects {
	// Generic Effects
	EFFECT_STUN, // Stunned
	EFFECT_FLINCH,
	// Self Effects
	EFFECT_NOM_FRENZY,
	EFFECT_GROWL_RAGE,
	EFFECT_SCAMPER_BOOST,
	EFFECT_DART_CLOAK,
	EFFECT_POKEY_CHARGE,
	// Inflicted Effects
	EFFECT_NEWT_HEAL,
	EFFECT_SCAMPER_STINK,
	EFFECT_BUBBLES_BUBBLE,
	EFFECT_BUBBLES_AEGIS,
	EFFECT_TOOT_BLIND,
	// Food Effects
	EFFECT_FOOD_NONE,
	EFFECT_FOOD_BURN,
	EFFECT_FOOD_HEAVY,
	EFFECT_FOOD_LIGHT
};

struct SFoodInfo {
	var int HealAmount;
	var int FoodAmount;
	var int Size;
	var name StatName;
	var StaticMesh Mesh;
	var class<GWProj_Food> ProjClass;
	var EStatusEffects EffectType;
	structdefaultproperties {
		FoodAmount=5
		HealAmount=5
		ProjClass=class'GWProj_Food_Normal'
		EffectType=EFFECT_FOOD_NONE
	}
};

var SFoodInfo FoodStats[EFood];

DefaultProperties
{
	FoodStats[FOOD_MEAT_SMALL] = (FoodAmount=3, StatName=PICKUPS_POWER, HealAmount=5, Size=2, Mesh=StaticMesh'G_P_Meat.Mesh.SM_Meat_Small')
	FoodStats[FOOD_MEAT_MEDIUM] = (FoodAmount=5, StatName=PICKUPS_POWER, HealAmount=5, Size=4, Mesh=StaticMesh'G_P_Meat.Mesh.SM_Meat_Medium')
	FoodStats[FOOD_MEAT_LARGE] = (FoodAmount=7, StatName=PICKUPS_POWER, HealAmount=5, Size=6, Mesh=StaticMesh'G_P_Meat.Mesh.SM_Meat_Large')
	FoodStats[FOOD_FRUIT_SMALL] = (FoodAmount=3, StatName=PICKUPS_SKILL, HealAmount=5, Size=2, Mesh=StaticMesh'G_P_Fruit.Mesh.SM_Fruit_Small')
	FoodStats[FOOD_FRUIT_MEDIUM] = (FoodAmount=5, StatName=PICKUPS_SKILL, HealAmount=5, Size=4, Mesh=StaticMesh'G_P_Fruit.Mesh.SM_Fruit_Medium')
	FoodStats[FOOD_FRUIT_LARGE] = (FoodAmount=7, StatName=PICKUPS_SKILL, HealAmount=5, Size=6, Mesh=StaticMesh'G_P_Fruit.Mesh.SM_Fruit_Large')
	FoodStats[FOOD_CANDY_SMALL] = (FoodAmount=3, StatName=PICKUPS_SPEED, HealAmount=5, Size=2, Mesh=StaticMesh'G_P_Candy.Mesh.SM_Candy_Small')
	FoodStats[FOOD_CANDY_MEDIUM] = (FoodAmount=5, StatName=PICKUPS_SPEED, HealAmount=5, Size=4, Mesh=StaticMesh'G_P_Candy.Mesh.SM_Candy_Medium')
	FoodStats[FOOD_CANDY_LARGE] = (FoodAmount=7, StatName=PICKUPS_SPEED, HealAmount=5, Size=6, Mesh=StaticMesh'G_P_Candy.Mesh.SM_Candy_Large')
	FoodStats[FOOD_CHILLI] = (FoodAmount=0, HealAmount=0, StatName=PICKUPS_NONE, Size=1, EffectType=EFFECT_FOOD_BURN, Mesh=StaticMesh'Grow_John_Assets.Meshes.Chilli_Mesh', ProjClass=class'GWProj_Food_Chilli')
	FoodStats[FOOD_GRENADE] = (FoodAmount=0, HealAmount=30, StatName=PICKUPS_NONE, Size=1, Mesh=StaticMesh'Grow_John_Assets.Meshes.pomegranite', ProjClass=class'GWProj_Food_Grenade')
	FoodStats[FOOD_SEED] = (FoodAmount=0, HealAmount=0, StatName=PICKUPS_NONE, Size=1, Mesh=StaticMesh'Grow_John_Assets.Meshes.pomegranite', ProjClass=class'GWProj_Food_Seed')
	FoodStats[FOOD_SUPER] = (FoodAmount=100, HealAmount=0, StatName=PICKUPS_ALL, Size=10, Mesh=StaticMesh'G_P_Meat.Mesh.SM_Meat_Large')
}
