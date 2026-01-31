extends Area2D

# Definimos qué máscara otorga este objeto
enum TipoMascara { Ira, Burla, Dios }
@export var mascara_a_desbloquear: TipoMascara = TipoMascara.Ira

func _ready() -> void:
	# Conectamos la señal de cuerpo entrando a nuestra propia función
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# Verificamos si el cuerpo que entró es el jugador
	if body.is_in_group("player"):
		match mascara_a_desbloquear:
			TipoMascara.Ira:
				body.Desbloquear_Ira() 
			TipoMascara.Burla:
				body.Desbloquear_Burla() 
			TipoMascara.Dios:
				body.Desbloquear_Dios() 
		
		# Opcional: Sonido o partículas aquí
		queue_free() # El objeto desaparece al ser recogido
