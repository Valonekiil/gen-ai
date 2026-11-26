# CameraDirector.gd
# class_name CameraDirector — swap active camera (Splitbound)
# S1-06: Arsitektur §11.2; Mekanik v2.0 §2.5

class_name CameraDirector
extends Node

@export var camera_a: Camera2D
@export var camera_b: Camera2D

# PiP dihapus: kamera realita tidak lagi dicerminkan ke SubViewport.
# Ekspor camera_a/camera_b tetap ada untuk kompatibilitas scene lama.
