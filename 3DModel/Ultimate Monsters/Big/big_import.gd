@tool
extends EditorScenePostImport

# Called by the editor when a scene has this script set as the import script in the import tab.
func _post_import(scene: Node) -> Object:
    return scene
