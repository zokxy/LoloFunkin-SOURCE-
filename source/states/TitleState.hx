package states;

import backend.WeekData;

import flixel.input.keyboard.FlxKey;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.util.FlxColor;
import haxe.Json;

import openfl.Assets;
import openfl.display.Bitmap;
import openfl.display.BitmapData;

import states.StoryMenuState;
import states.MainMenuState;

class TitleState extends MusicBeatState
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	public static var initialized:Bool = false;
	public static var closedState:Bool = false;

	static var LOADING_STEPS:Array<{type:String, path:String}> = [
		{type: "image", path: "mojangLogo"},
		{type: "image", path: "menuDesat"},
		{type: "image", path: "menuBG"},
		{type: "image", path: "alphabet"},
		{type: "image", path: "mainmenu/menu_freeplay"},
		{type: "image", path: "mainmenu/menu_credits"},
		{type: "image", path: "mainmenu/menu_options"},
		{type: "music", path: "freakyMenu"},
		{type: "sound", path: "confirmMenu"},
		{type: "sound", path: "scrollMenu"},
		{type: "sound", path: "cancelMenu"},
	];

	var bgRed:FlxSprite;
	var mojangLogo:FlxSprite;

	var barBack:FlxSprite;
	var barFill:FlxSprite;

	var barX:Float = 0;
	var barY:Float = 0;
	var barWidth:Float = 0;
	var barHeight:Float = 0;
	var barPadding:Float = 5;

	var loadedSteps:Int = 0;
	var totalSteps:Int = 0;
	var loadingDone:Bool = false;

	var transitioning:Bool = false;

	override public function create():Void
	{
		Paths.clearStoredMemory();
		super.create();
		Paths.clearUnusedMemory();

		if (!initialized)
		{
			ClientPrefs.loadPrefs();
			Language.reloadPhrases();
		}

		if (!initialized)
		{
			if (FlxG.save.data != null && FlxG.save.data.fullscreen)
			{
				FlxG.fullscreen = FlxG.save.data.fullscreen;
			}
			persistentUpdate = true;
			persistentDraw = true;
		}

		if (FlxG.save.data.weekCompleted != null)
		{
			StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
		}

		FlxG.mouse.visible = false;

		#if FREEPLAY
		MusicBeatState.switchState(new FreeplayState());
		#elseif CHARTING
		MusicBeatState.switchState(new ChartingState());
		#else
		buildMojangScreen();
		startLoading();
		#end
	}

	function buildMojangScreen():Void
	{
		bgRed = new FlxSprite().makeGraphic(1, 1, 0xFFF0313B);
		bgRed.scale.set(FlxG.width, FlxG.height);
		bgRed.updateHitbox();
		bgRed.scrollFactor.set();
		add(bgRed);

		mojangLogo = new FlxSprite();
		mojangLogo.loadGraphic(Paths.image('mojangLogo'));
		mojangLogo.antialiasing = ClientPrefs.data.antialiasing;
		mojangLogo.screenCenter();
		mojangLogo.setGraphicSize(Std.int(mojangLogo.width * 0.3));
		mojangLogo.y -= 30;
		mojangLogo.scrollFactor.set();
		add(mojangLogo);

		barWidth = FlxG.width * 0.6;
		barHeight = 28;
		barX = (FlxG.width - barWidth) / 2;
		barY = FlxG.height * 0.78;

		barBack = new FlxSprite(barX, barY).makeGraphic(Std.int(barWidth), Std.int(barHeight), FlxColor.TRANSPARENT);
		drawBarOutline(barBack);
		barBack.scrollFactor.set();
		add(barBack);

		barFill = new FlxSprite(barX + barPadding, barY + barPadding);
		barFill.makeGraphic(1, Std.int(barHeight - barPadding * 2), FlxColor.WHITE);
		barFill.scrollFactor.set();
		add(barFill);

		totalSteps = LOADING_STEPS.length;
		if (totalSteps <= 0) totalSteps = 1;
		updateBarVisual(0);
	}

	function drawBarOutline(spr:FlxSprite):Void
	{
		var w:Int = Std.int(barWidth);
		var h:Int = Std.int(barHeight);
		var thickness:Int = 2;

		spr.pixels.fillRect(new openfl.geom.Rectangle(0, 0, w, thickness), FlxColor.WHITE);
		spr.pixels.fillRect(new openfl.geom.Rectangle(0, h - thickness, w, thickness), FlxColor.WHITE);
		spr.pixels.fillRect(new openfl.geom.Rectangle(0, 0, thickness, h), FlxColor.WHITE);
		spr.pixels.fillRect(new openfl.geom.Rectangle(w - thickness, 0, thickness, h), FlxColor.WHITE);

		spr.dirty = true;
	}

	function startLoading():Void
	{
		loadedSteps = 0;
		loadNextStep();
	}

	function loadNextStep():Void
	{
		if (loadedSteps >= LOADING_STEPS.length)
		{
			finishLoading();
			return;
		}

		var step = LOADING_STEPS[loadedSteps];

		try
		{
			switch (step.type)
			{
				case "image":
					Paths.image(step.path);
				case "music":
					Paths.music(step.path);
				case "sound":
					Paths.sound(step.path);
				case "font":
					Paths.font(step.path);
				default:
					trace('[TitleState] Unknown loading step type: ${step.type}');
			}
		}
		catch (e:haxe.Exception)
		{
			trace('[TitleState] Failed to load step ${step.path}: ${e.details()}');
		}

		loadedSteps++;
		updateBarVisual(loadedSteps / totalSteps);

		new FlxTimer().start(0.08, function(tmr:FlxTimer)
		{
			loadNextStep();
		});
	}

	function updateBarVisual(progress:Float):Void
	{
		if (progress > 1) progress = 1;
		if (progress < 0) progress = 0;

		var innerWidth:Float = (barWidth - barPadding * 2) * progress;
		if (innerWidth < 1) innerWidth = 1;

		barFill.makeGraphic(Std.int(innerWidth), Std.int(barHeight - barPadding * 2), FlxColor.WHITE);
		barFill.x = barX + barPadding;
		barFill.y = barY + barPadding;
	}

	function finishLoading():Void
	{
		if (loadingDone) return;
		loadingDone = true;

		new FlxTimer().start(0.4, function(tmr:FlxTimer)
		{
			goToMainMenu();
		});
	}

	function goToMainMenu():Void
	{
		if (transitioning) return;
		transitioning = true;

		if (FlxG.sound.music == null)
		{
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
			FlxG.sound.music.fadeIn(4, 0, 0.7);
		}

		FlxG.camera.flash(FlxColor.WHITE, 0.6);

		new FlxTimer().start(0.6, function(tmr:FlxTimer)
		{
			initialized = true;
			closedState = true;
			MusicBeatState.switchState(new MainMenuState());
		});
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
	}
}