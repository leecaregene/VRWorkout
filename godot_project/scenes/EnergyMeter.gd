extends Spatial

export var debug = false
var gu = GameUtilities.new()

var update_throttle = 0

var small_scale = Vector3(0.1,0.1,0.1)
var big_scale = Vector3(0.3,0.3,0.3)

var input = 0
var difficulty = 2


func update_meter():
	var score = 4.0 + 8.0 * (difficulty / 2.0)
	if GameVariables.energy_level_max > 0:
		var value = 100*input/(score * 1.5)	
		$Viewport/CanvasLayer/TextureProgress.value = clamp(value,0,100)	
		$Viewport/CanvasLayer/Label.text = "%.1f"%(gu.get_current_energy())
		$MeshInstance/stars/star.scale = small_scale
		$MeshInstance/stars/star2.scale = small_scale
		$MeshInstance/stars/star3.scale = small_scale
		
		if input > (score * (7.0 / 12.0)):
			$MeshInstance/stars/star.scale = big_scale
			
		if input > (score * (10.0 / 12.0)):
			$MeshInstance/stars/star2.scale = big_scale

		if input > score:
			$MeshInstance/stars/star3.scale = big_scale

	$Viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	
	
func _ready():
	if debug:
		$Viewport/CanvasLayer/ColorRect.show()
		$Viewport/CanvasLayer/Label.show()
	else:
		$Viewport/CanvasLayer/ColorRect.hide()
		$Viewport/CanvasLayer/Label.hide()
	
	if GameVariables.energy_level_max > 0:
		var total = $MeshInstance.mesh.size[0]

		var tmp = 7.0 / (12.0 * 1.5)
		$MeshInstance/stars/star.translation.x = tmp * total
		tmp = 10.0 / (12.0 * 1.5)
		$MeshInstance/stars/star2.translation.x = tmp * total
		tmp = 12.0 / (12.0 * 1.5)
		$MeshInstance/stars/star3.translation.x = tmp * total
	
		

func _process(delta):
	update_throttle += 1
	if update_throttle > 20:
		update_meter()
		update_throttle = 0
		
