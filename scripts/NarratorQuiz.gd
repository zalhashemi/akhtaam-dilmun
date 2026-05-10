extends CanvasLayer

const PASS_THRESHOLD := 2
const TYPE_SPEED     := 0.06
const FEEDBACK_PAUSE := 0.9

@onready var quiz_root      : Control          = $QuizRoot
@onready var narrator_bust  : AnimatedSprite2D = $QuizRoot/NarratorBust
@onready var dialogue_label : Label            = $QuizRoot/DialogPanel/MarginContainer/DialogVBox/DialogueLabel
@onready var progress_label : Label            = $QuizRoot/DialogPanel/MarginContainer/DialogVBox/ProgressLabel
@onready var choices_hbox   : HBoxContainer    = $QuizRoot/DialogPanel/MarginContainer/DialogVBox/ChoicesHBox
@onready var choice_btn_1   : Button           = $QuizRoot/DialogPanel/MarginContainer/DialogVBox/ChoicesHBox/ChoiceButton1
@onready var choice_btn_2   : Button           = $QuizRoot/DialogPanel/MarginContainer/DialogVBox/ChoicesHBox/ChoiceButton2
@onready var choice_btn_3   : Button           = $QuizRoot/DialogPanel/MarginContainer/DialogVBox/ChoicesHBox/ChoiceButton3
@onready var result_panel   : PanelContainer   = $ResultPanel
@onready var result_label   : Label            = $ResultPanel/MarginContainer/ResultVBox/ResultLabel
@onready var seal_sprite    : AnimatedSprite2D = $ResultPanel/MarginContainer/ResultVBox/SealSprite
@onready var continue_btn   : TextureButton    = $ResultPanel/MarginContainer/ResultVBox/ContinueButton

const SEAL_ANIMATIONS := {
	1: "seal_water",
	2: "seal_earth",
	3: "seal_pearls",
	4: "seal_harvest",
	5: "seal_unity",
	6: "seal_memory",
}

const SEAL_NAMES := {
	1: {"en": "Seal of Water",   "ar": "ختم الماء"},
	2: {"en": "Seal of Earth",   "ar": "ختم الأرض"},
	3: {"en": "Seal of Pearls",  "ar": "ختم اللؤلؤ"},
	4: {"en": "Seal of Harvest", "ar": "ختم الحصاد"},
	5: {"en": "Seal of Unity",   "ar": "ختم الوحدة"},
	6: {"en": "Seal of Memory",  "ar": "ختم الذاكرة"},
}

var questions     : Array = []
var current_index : int   = 0
var correct_count : int   = 0
var typing        : bool  = false
var finished      : bool  = false
var quest_number  : int   = 0
var rng := RandomNumberGenerator.new()
var _next_btn     : Button = null

const INTRO_LINES := {
	1: {
		"en": "Well done! You have restored the ancient water channels of Dilmun. The people can now water their crops and trade across the seas once more. But before I grant you the Seal of Water, let me ask you three questions…",
		"ar": "أحسنت! لقد أعدت قنوات المياه القديمة في دلمون. يستطيع الناس الآن ري محاصيلهم والتجارة عبر البحار من جديد. لكن قبل أن أمنحك ختم الماء، دعني أسألك ثلاثة أسئلة…"
	},
	2: {
		"en": "Magnificent! The broken artifacts of Dilmun are whole again. The stones remember their stories, and so must you. Answer these questions to claim the Seal of Earth…",
		"ar": "رائع! قطع الأثر المكسورة في دلمون أصبحت كاملة من جديد. الحجارة تتذكر قصصها، وعليك أنت أيضاً. أجب عن هذه الأسئلة للحصول على ختم الأرض…"
	},
	3: {
		"en": "Brave sailor! You have guided the ship through the waters and gathered the precious pearls of Bahrain. Pearl diving was the heart of this land for centuries. Now answer wisely for the Seal of Pearls…",
		"ar": "أيها البحار الشجاع! لقد قدت السفينة عبر المياه وجمعت لؤلؤ البحرين الثمين. كان الغوص على اللؤلؤ قلب هذه الأرض لقرون. أجب بحكمة للحصول على ختم اللؤلؤ…"
	},
	4: {
		"en": "Well harvested! The crops of Dilmun are gathered and the people will not go hungry. Ancient Bahrain thrived on the gifts of its fertile land. Prove your knowledge to earn the Seal of Harvest…",
		"ar": "أحسنت الحصاد! محاصيل دلمون جُمعت والناس لن يجوعوا. ازدهرت البحرين القديمة بخيرات أرضها الخصبة. أثبت معرفتك لتحصل على ختم الحصاد…"
	},
	5: {
		"en": "A true leader of Dilmun! You have shown the community the power of cooperation and kindness. Unity is what made this civilisation great. Answer these questions for the Seal of Unity…",
		"ar": "قائد دلمون الحقيقي! لقد أريت المجتمع قوة التعاون واللطف. الوحدة هي ما جعلت هذه الحضارة عظيمة. أجب عن هذه الأسئلة للحصول على ختم الوحدة…"
	},
	6: {
		"en": "You have done it — all the wisdom of Dilmun lives in you now! Before I seal your journey with the final mark, let us see how well you remember everything you have learned…",
		"ar": "لقد فعلتها — كل حكمة دلمون تعيش فيك الآن! قبل أن أختم رحلتك بالعلامة الأخيرة، دعنا نرى مدى تذكرك لكل ما تعلمته…"
	},
}

const QUESTION_BANK := {
	1: [
		{
			"prompt"  : {"en": "Why was water so important to the Dilmun civilization?",        "ar": "لماذا كان الماء مهماً جداً لحضارة دلمون؟"},
			"choices" : [{"en": "For farming and trade", "ar": "للزراعة والتجارة"},             {"en": "For decoration", "ar": "للزينة"},            {"en": "For games", "ar": "للألعاب"}],
			"correct" : 0
		},
		{
			"prompt"  : {"en": "What natural feature made Dilmun a thriving land?",             "ar": "ما الميزة الطبيعية التي جعلت دلمون أرضاً مزدهرة؟"},
			"choices" : [{"en": "Its deserts", "ar": "صحاريها"},                                {"en": "Its freshwater springs", "ar": "ينابيعها العذبة"}, {"en": "Its tall mountains", "ar": "جبالها الشاهقة"}],
			"correct" : 1
		},
		{
			"prompt"  : {"en": "Which modern place stands where Dilmun once flourished?",       "ar": "أي مكان حديث يقوم حيث ازدهرت دلمون؟"},
			"choices" : [{"en": "Bahrain", "ar": "البحرين"},                                    {"en": "Egypt", "ar": "مصر"},                           {"en": "Oman", "ar": "عُمان"}],
			"correct" : 0
		},
	],
	2: [
		{
			"prompt"  : {"en": "What material did ancient Bahrainis use to build houses and forts?", "ar": "ما المواد التي استخدمها البحرينيون القدماء لبناء البيوت والحصون؟"},
			"choices" : [{"en": "Wood", "ar": "الخشب"},                                         {"en": "Stone and clay", "ar": "الحجر والطين"},         {"en": "Metal", "ar": "المعدن"}],
			"correct" : 1
		},
		{
			"prompt"  : {"en": "What is Qal'at al-Bahrain famous for today?",                   "ar": "بم تشتهر قلعة البحرين اليوم؟"},
			"choices" : [{"en": "Being a shopping center", "ar": "كونها مركز تسوق"},            {"en": "Being a UNESCO World Heritage Site", "ar": "كونها موقع تراث عالمي لليونسكو"}, {"en": "Having the tallest tower", "ar": "امتلاكها أعلى برج"}],
			"correct" : 1
		},
		{
			"prompt"  : {"en": "What do archaeologists find inside Qal'at al-Bahrain?",         "ar": "ماذا يجد علماء الآثار داخل قلعة البحرين؟"},
			"choices" : [{"en": "Ancient settlements", "ar": "مستوطنات قديمة"},                 {"en": "Toys", "ar": "ألعاب"},                          {"en": "Nothing special", "ar": "لا شيء مميز"}],
			"correct" : 0
		},
	],
	3: [
		{
			"prompt"  : {"en": "Why were pearls so valuable in Bahrain?",                       "ar": "لماذا كان اللؤلؤ ثميناً جداً في البحرين؟"},
			"choices" : [{"en": "They were rare and beautiful", "ar": "كان نادراً وجميلاً"},    {"en": "They could sing", "ar": "كان يستطيع الغناء"},   {"en": "They grew on trees", "ar": "كان ينمو على الأشجار"}],
			"correct" : 0
		},
		{
			"prompt"  : {"en": "How did divers find pearls long ago?",                          "ar": "كيف كان الغواصون يجدون اللؤلؤ قديماً؟"},
			"choices" : [{"en": "Using machines", "ar": "باستخدام الآلات"},                     {"en": "By diving deep with no oxygen tanks", "ar": "بالغوص العميق بدون خزانات أكسجين"}, {"en": "By fishing nets", "ar": "بشباك الصيد"}],
			"correct" : 1
		},
		{
			"prompt"  : {"en": "What quality did pearl divers need most?",                      "ar": "ما الصفة التي احتاجها الغواصون أكثر من غيرها؟"},
			"choices" : [{"en": "Bravery", "ar": "الشجاعة"},                                    {"en": "Anger", "ar": "الغضب"},                         {"en": "Laziness", "ar": "الكسل"}],
			"correct" : 0
		},
	],
	4: [
		{
			"prompt"  : {"en": "What crop was most important to ancient Dilmun farmers?",       "ar": "ما المحصول الأهم لمزارعي دلمون القدماء؟"},
			"choices" : [{"en": "Dates", "ar": "التمر"},                                        {"en": "Apples", "ar": "التفاح"},                       {"en": "Rice", "ar": "الأرز"}],
			"correct" : 0
		},
		{
			"prompt"  : {"en": "Why did ancient Bahrainis need to store their harvest carefully?", "ar": "لماذا احتاج البحرينيون القدماء إلى تخزين محاصيلهم بعناية؟"},
			"choices" : [{"en": "To survive dry seasons", "ar": "للبقاء في المواسم الجافة"},    {"en": "To sell it for gold", "ar": "لبيعه بالذهب"},    {"en": "To feed wild animals", "ar": "لإطعام الحيوانات البرية"}],
			"correct" : 0
		},
		{
			"prompt"  : {"en": "What helped ancient Bahraini farmers water their crops?",       "ar": "ما الذي ساعد مزارعي البحرين القدماء على ري محاصيلهم؟"},
			"choices" : [{"en": "Freshwater springs and channels", "ar": "الينابيع العذبة والقنوات"}, {"en": "Rainwater only", "ar": "مياه الأمطار فقط"}, {"en": "The sea", "ar": "البحر"}],
			"correct" : 0
		},
	],
	5: [
		{
			"prompt"  : {"en": "What values made Bahraini communities strong?",                 "ar": "ما القيم التي جعلت مجتمعات البحرين قوية؟"},
			"choices" : [{"en": "Kindness and cooperation", "ar": "اللطف والتعاون"},            {"en": "Greed", "ar": "الجشع"},                         {"en": "Silence", "ar": "الصمت"}],
			"correct" : 0
		},
		{
			"prompt"  : {"en": "If someone drops a coin in the souq, what should you do?",     "ar": "إذا أسقط شخص ما عملة معدنية في السوق، ماذا يجب أن تفعل؟"},
			"choices" : [{"en": "Keep it", "ar": "تحتفظ بها"},                                  {"en": "Return it", "ar": "تُعيدها"},                   {"en": "Ignore it", "ar": "تتجاهلها"}],
			"correct" : 1
		},
		{
			"prompt"  : {"en": "Why did people help each other in old Bahrain?",                "ar": "لماذا كان الناس يتعاونون في البحرين القديمة؟"},
			"choices" : [{"en": "Because they cared for one another", "ar": "لأنهم كانوا يهتمون ببعضهم"}, {"en": "Because they had to", "ar": "لأنهم كانوا مضطرين"}, {"en": "Because they wanted fame", "ar": "لأنهم أرادوا الشهرة"}],
			"correct" : 0
		},
	],
	6: [
		{
			"prompt"  : {"en": "What connects all the Seals of Dilmun?",                        "ar": "ما الذي يربط جميع أختام دلمون؟"},
			"choices" : [{"en": "They protect Bahrain's heritage", "ar": "تحمي تراث البحرين"},  {"en": "They are just pretty gems", "ar": "هي مجرد أحجار كريمة جميلة"}, {"en": "They give superpowers", "ar": "تمنح قوى خارقة"}],
			"correct" : 0
		},
		{
			"prompt"  : {"en": "What is the message of Akhtaam Dilmun?",                        "ar": "ما رسالة أختام دلمون؟"},
			"choices" : [{"en": "To remember and protect our history", "ar": "لتذكر وحماية تاريخنا"}, {"en": "To fight monsters", "ar": "لمحاربة الوحوش"}, {"en": "To forget the past", "ar": "لنسيان الماضي"}],
			"correct" : 0
		},
		{
			"prompt"  : {"en": "What was the goal of this journey?",                            "ar": "ما كان هدف هذه الرحلة؟"},
			"choices" : [{"en": "To stay connected with our history", "ar": "للبقاء على تواصل مع تاريخنا"}, {"en": "To collect gems", "ar": "لجمع الأحجار الكريمة"}, {"en": "To defeat enemies", "ar": "لهزيمة الأعداء"}],
			"correct" : 0
		},
	],
}

const FEEDBACK_CORRECT := {
	"en": [
		"That is right! The wisdom of Dilmun flows through you.",
		"Excellent! You honour the memory of this great land.",
		"Well answered! The ancients would be proud.",
		"Correct! Knowledge is the greatest treasure.",
		"Yes! You are proving yourself a true guardian of Dilmun.",
	],
	"ar": [
		"صحيح! حكمة دلمون تتدفق من خلالك.",
		"ممتاز! أنت تكرم ذاكرة هذه الأرض العظيمة.",
		"إجابة رائعة! الأقدمون سيكونون فخورين.",
		"صحيح! المعرفة هي أعظم كنز.",
		"نعم! أنت تثبت أنك حارس دلمون الحقيقي.",
	]
}

const FEEDBACK_WRONG := {
	"en": [
		"Not quite… but do not be discouraged. Every mistake is a lesson.",
		"Hmm, that is not right. Remember what you saw on your quest.",
		"That is incorrect, but knowledge grows with every attempt.",
		"Not this time. Think back on the stories of Dilmun…",
		"Close, but not quite. The answer lies in what you explored.",
	],
	"ar": [
		"ليس تماماً… لكن لا تستسلم. كل خطأ هو درس.",
		"هممم، هذا ليس صحيحاً. تذكر ما رأيته في مهمتك.",
		"هذا غير صحيح، لكن المعرفة تنمو مع كل محاولة.",
		"ليس هذه المرة. فكر في قصص دلمون…",
		"قريب، لكن ليس تماماً. الإجابة تكمن فيما استكشفته.",
	]
}


func _loc() -> String:
	return Global.current_locale


func _t(dict) -> String:
	if dict is String:
		return dict
	if dict is Dictionary:
		return str(dict.get(_loc(), dict.get("en", "")))
	return ""


func _ready() -> void:
	self.visible            = false
	result_panel.visible    = false
	choices_hbox.visible    = false
	seal_sprite.visible     = false
	progress_label.visible  = false  # hidden until a question is actually shown

	choice_btn_1.pressed.connect(_on_choice_pressed.bind(0))
	choice_btn_2.pressed.connect(_on_choice_pressed.bind(1))
	choice_btn_3.pressed.connect(_on_choice_pressed.bind(2))
	continue_btn.pressed.connect(_on_continue)
	_create_next_button()



#  PUBLIC
func start_quiz(quest_n: int) -> void:
	quest_number  = quest_n
	current_index = 0
	correct_count = 0
	typing        = false
	finished      = false

	questions = QUESTION_BANK.get(quest_n, [])
	if questions.is_empty():
		push_error("NarratorQuiz: no questions found for quest %d" % quest_n)
		return

	rng.randomize()
	result_panel.visible   = false
	seal_sprite.visible    = false
	choices_hbox.visible   = false
	progress_label.visible = false
	if _next_btn != null:
		_next_btn.visible  = false
	quiz_root.visible      = true
	self.visible           = true

	_apply_arabic_font_if_needed()
	_show_intro()


func _show_intro() -> void:
	choices_hbox.visible   = false
	progress_label.visible = false
	narrator_bust.play("narratorTalk")
	var line : String = _t(INTRO_LINES.get(quest_number, {"en": "Let us test your knowledge…", "ar": "دعنا نختبر معرفتك…"}))
	await _type_text(line, true)
	narrator_bust.play("narratorIdle")
	_show_current_question()


func _show_current_question() -> void:
	choices_hbox.visible   = false
	progress_label.visible = false  # hide while typing the question

	if current_index >= questions.size():
		_finish_quiz()
		return

	var q : Dictionary = questions[current_index]

	narrator_bust.play("narratorTalk")
	await _type_text(_t(q["prompt"]))
	narrator_bust.play("narratorIdle")

	_update_progress_label()
	progress_label.visible = true

	var choices : Array = q["choices"]
	choice_btn_1.text = _t(choices[0])
	choice_btn_2.text = _t(choices[1])
	choice_btn_3.text = _t(choices[2])

	_set_buttons_disabled(false)
	choices_hbox.visible = true


func _on_choice_pressed(chosen_index: int) -> void:
	if typing or finished:
		return
	_handle_answer(chosen_index)


func _handle_answer(chosen: int) -> void:
	choices_hbox.visible   = false
	progress_label.visible = false  # hide during feedback
	_set_buttons_disabled(true)

	var q           : Dictionary = questions[current_index]
	var was_correct : bool       = (chosen == int(q["correct"]))
	if was_correct:
		correct_count += 1

	await _show_feedback(was_correct)

	_set_buttons_disabled(false)
	current_index += 1
	_show_current_question()


func _show_feedback(was_correct: bool) -> void:
	var pool : Array  = FEEDBACK_CORRECT[_loc()] if was_correct else FEEDBACK_WRONG[_loc()]
	var msg  : String = str(pool[rng.randi_range(0, pool.size() - 1)])
	narrator_bust.play("narratorTalk")
	await _type_text(msg, true)
	narrator_bust.play("narratorIdle")


func _finish_quiz() -> void:
	if finished:
		return
	finished               = true
	choices_hbox.visible   = false
	progress_label.visible = false

	var passed    : bool   = correct_count >= PASS_THRESHOLD
	var seal_name : String = _t(SEAL_NAMES.get(quest_number, {"en": "Seal", "ar": "ختم"}))

	if passed:
		Global.award_seal(quest_number)
		var msg : String
		if _loc() == "ar":
			var ts := TextServerManager.get_primary_interface()
			msg = "أجبت على %s من %s بشكل صحيح.\n%s لك! أحسنت يا حارس دلمون." % [
				ts.format_number("%d" % correct_count),
				ts.format_number("%d" % questions.size()),
				seal_name
			]
		else:
			msg = "You answered %d out of %d correctly.\nThe %s is yours! Well done, guardian of Dilmun." % [
				correct_count, questions.size(), seal_name
			]
		_show_result(msg, true)
	else:
		var msg : String
		if _loc() == "ar":
			var ts := TextServerManager.get_primary_interface()
			msg = "أجبت على %s من %s بشكل صحيح.\nتحتاج إلى %s على الأقل للحصول على %s.\nحاول مجدداً!" % [
				ts.format_number("%d" % correct_count),
				ts.format_number("%d" % questions.size()),
				ts.format_number("%d" % PASS_THRESHOLD),
				seal_name
			]
		else:
			msg = "You answered %d out of %d correctly.\nYou need at least %d correct to earn the %s.\nTry again!" % [
				correct_count, questions.size(), PASS_THRESHOLD, seal_name
			]
		_show_result(msg, false)


func _show_result(msg: String, passed: bool) -> void:
	quiz_root.visible    = false
	result_panel.visible = true
	result_label.text    = msg

	if passed:
		var anim : String = SEAL_ANIMATIONS.get(quest_number, "")
		if anim != "" and seal_sprite.sprite_frames != null \
				and seal_sprite.sprite_frames.has_animation(anim):
			seal_sprite.visible = true
			seal_sprite.play(anim)
		else:
			seal_sprite.visible = false
			push_warning("NarratorQuiz: seal animation '%s' not found in SpriteFrames." % anim)
	else:
		seal_sprite.visible = false

	var lbl := _get_continue_label()
	if lbl != null:
		if _loc() == "ar":
			lbl.text = "متابعة" if passed else "حاول مجدداً"
		else:
			lbl.text = "Continue" if passed else "Try Again"


func _on_continue() -> void:
	var passed : bool = correct_count >= PASS_THRESHOLD
	if passed:
		self.visible         = false
		result_panel.visible = false
		quiz_root.visible    = false
		seal_sprite.visible  = false
		get_parent().call("_on_narrator_quiz_finished")
	else:
		current_index        = 0
		correct_count        = 0
		finished             = false
		result_panel.visible = false
		seal_sprite.visible  = false
		quiz_root.visible    = true
		_show_intro()


func _type_text(full_text: String, show_next: bool = false) -> void:
	typing              = true
	dialogue_label.text = ""
	for i in range(full_text.length()):
		dialogue_label.text = full_text.substr(0, i + 1)
		await get_tree().create_timer(TYPE_SPEED).timeout
	typing = false
	if show_next and _next_btn != null:
		_next_btn.visible = true
		await _next_btn.pressed
		_next_btn.visible = false


func _update_progress_label() -> void:
	if _loc() == "ar":
		var ts := TextServerManager.get_primary_interface()
		progress_label.text = "السؤال %s من %s" % [
			ts.format_number("%d" % (current_index + 1)),
			ts.format_number("%d" % questions.size())
		]
	else:
		progress_label.text = "Question %d of %d" % [current_index + 1, questions.size()]


func _set_buttons_disabled(state: bool) -> void:
	choice_btn_1.disabled = state
	choice_btn_2.disabled = state
	choice_btn_3.disabled = state


func _get_continue_label() -> Label:
	for child in continue_btn.get_children():
		if child is Label:
			return child as Label
	push_warning("NarratorQuiz: ContinueButton has no Label child.")
	return null


func _create_next_button() -> void:
	var is_ar := Global.current_locale == "ar"
	_next_btn = Button.new()
	if is_ar:
		_next_btn.text = "◄ التالي"
		_next_btn.text_direction = Control.TEXT_DIRECTION_RTL
		if Global.arabic_font != null:
			_next_btn.add_theme_font_override("font", Global.arabic_font)
			_next_btn.add_theme_font_size_override("font_size", 18 + Global.ARABIC_SIZE_BONUS)
		_next_btn.anchor_left   = 0.0
		_next_btn.anchor_right  = 0.0
		_next_btn.anchor_top    = 1.0
		_next_btn.anchor_bottom = 1.0
		_next_btn.offset_left   = 16.0
		_next_btn.offset_right  = 180.0
		_next_btn.offset_top    = -60.0
		_next_btn.offset_bottom = -16.0
	else:
		_next_btn.text = "Next ►"
		_next_btn.add_theme_font_size_override("font_size", 18)
		_next_btn.anchor_left   = 1.0
		_next_btn.anchor_right  = 1.0
		_next_btn.anchor_top    = 1.0
		_next_btn.anchor_bottom = 1.0
		_next_btn.offset_left   = -180.0
		_next_btn.offset_right  = -16.0
		_next_btn.offset_top    = -60.0
		_next_btn.offset_bottom = -16.0
	_next_btn.layout_mode = 1
	_next_btn.custom_minimum_size = Vector2(140, 44)
	_next_btn.visible = false
	quiz_root.add_child(_next_btn)


func _apply_arabic_font_if_needed() -> void:
	if _loc() != "ar" or Global.arabic_font == null:
		return
	var nodes : Array = [
		dialogue_label,
		progress_label,
		result_label,
		choice_btn_1,
		choice_btn_2,
		choice_btn_3,
	]
	var cont_lbl := _get_continue_label()
	if cont_lbl != null:
		nodes.append(cont_lbl)
	for node in nodes:
		if node != null and is_instance_valid(node):
			node.add_theme_font_override("font", Global.arabic_font)
			node.add_theme_font_size_override("font_size", node.get_theme_font_size("font_size") + Global.ARABIC_SIZE_BONUS)
			if node is Label:
				node.text_direction        = Control.TEXT_DIRECTION_RTL
				node.layout_direction      = Control.LAYOUT_DIRECTION_LTR
				node.horizontal_alignment  = HORIZONTAL_ALIGNMENT_RIGHT
			elif node is Button:
				node.text_direction = Control.TEXT_DIRECTION_RTL
	if cont_lbl != null and is_instance_valid(cont_lbl):
		cont_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cont_lbl.layout_direction     = Control.LAYOUT_DIRECTION_LTR
