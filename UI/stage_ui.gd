extends Control

class_name StageUI

@onready var box_count_label: Label = $HBoxContainer/BoxCountLabel
@onready var score_label: Label = $HBoxContainer/ScoreLabel
@onready var info_label: Label = $HBoxContainer/InfoLabel

@export var box_num : int = 0
@export var max_box_num : int = 0
@export var box_counter : String = ""

@export var score : int = 0
@export var better_score : int = 100000

signal better_score_entered
signal all_box_breaked

func set_box_label(counted:int = 0) -> void:
	if max_box_num == 0:
		max_box_num = counted
	box_count_label.text = "{count}/{max_box_num}".format({"count":box_num,"max_box_num":max_box_num})
	box_num += 1
	if box_num >= max_box_num:
		all_box_breaked.emit()

func set_score(score_num : int=0) -> void:
	score += score_num
	score_label.text = "SCORE:{score_num}".format({"score_num":score})
	if score > better_score:
		better_score_entered.emit()
