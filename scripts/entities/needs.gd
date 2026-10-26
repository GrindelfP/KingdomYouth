class_name Needs
extends Node

signal ticked
signal hunger_critical
signal starving
signal died

const TICK_INTERVAL := 1.0
const MAX_VALUE := 100.0
const CRITICAL_HUNGER := 85.0
const EAT_HUNGER := 60.0
const HUNGER_PER_SECOND := 1.0
const MEAL_RESTORE := 60.0
const FOOD_PER_MEAL := 1
const REST_DRAIN_PER_SECOND := 0.25
const REST_RECOVERY_PER_SECOND := 4.0
const STARVE_DAMAGE_PER_SECOND := 1.0
const EXPOSURE_DAMAGE_PER_SECOND := 0.2
const REGEN_PER_SECOND := 0.5
const WARMTH_DRAIN_PER_SECOND := 1.5
const WARMTH_RECOVER_PER_SECOND := 5.0
const COLD_DAMAGE_PER_SECOND := 1.5
const COLD_CALL := 40.0
const WARM_FULL := 90.0
const DIET_BONUS := 0.2
const DIET_PENALTY := 0.15

var hunger := 50.0
var rest := MAX_VALUE
var warmth := MAX_VALUE
var health := MAX_VALUE
var at_home := false
var warm := false
var sheltered := false
var diet_modifier := 0.0
var meal_provider := Callable()

var _accumulated := 0.0
var _was_critical := false
var _was_starving := false
var _is_dead := false


func _process(delta: float) -> void:
	_accumulated += delta
	while _accumulated >= TICK_INTERVAL:
		_accumulated -= TICK_INTERVAL
		_tick(TICK_INTERVAL)


func is_critical() -> bool:
	return hunger >= CRITICAL_HUNGER


func is_starving() -> bool:
	return hunger >= MAX_VALUE


func try_eat() -> bool:
	if not meal_provider.is_valid():
		return false
	var source: Inventory = meal_provider.call()
	return source != null and eat_from(source)


func eat_from(source: Inventory) -> bool:
	if source.take_best(ResourceDef.Category.FOOD, FOOD_PER_MEAL) < FOOD_PER_MEAL:
		return false
	hunger = maxf(hunger - MEAL_RESTORE, 0.0)
	return true


func _tick(dt: float) -> void:
	if _is_dead:
		return
	hunger = minf(hunger + HUNGER_PER_SECOND * dt, MAX_VALUE)
	var rest_change := REST_RECOVERY_PER_SECOND if at_home else -REST_DRAIN_PER_SECOND
	rest = clampf(rest + rest_change * dt, 0.0, MAX_VALUE)
	_update_warmth(dt)
	if hunger >= EAT_HUNGER:
		try_eat()
	_apply_health(dt)
	if is_critical() and not _was_critical:
		hunger_critical.emit()
	if is_starving() and not _was_starving:
		starving.emit()
	_was_critical = is_critical()
	_was_starving = is_starving()
	ticked.emit()


func _update_warmth(dt: float) -> void:
	if TimeManager.is_cold() and not warm:
		warmth = maxf(warmth - WARMTH_DRAIN_PER_SECOND * dt, 0.0)
	else:
		warmth = minf(warmth + WARMTH_RECOVER_PER_SECOND * dt, MAX_VALUE)


func _apply_health(dt: float) -> void:
	if is_starving():
		health -= STARVE_DAMAGE_PER_SECOND * dt
	elif warmth <= 0.0:
		health -= COLD_DAMAGE_PER_SECOND * dt
	elif not sheltered:
		health -= EXPOSURE_DAMAGE_PER_SECOND * dt
	else:
		health = minf(health + maxf(REGEN_PER_SECOND + diet_modifier, 0.05) * dt, MAX_VALUE)
	health = maxf(health, 0.0)
	if health <= 0.0 and not _is_dead:
		_is_dead = true
		died.emit()
