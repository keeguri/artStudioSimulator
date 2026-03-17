extends Resource
class_name StatueResource

enum StatueDifficulty{
	Easy,
	Normal,
	Hard
}

@export var statue_name : String
@export var statue_reward : int
@export var statue_difficulty : StatueDifficulty
@export_multiline var voxel_data : String