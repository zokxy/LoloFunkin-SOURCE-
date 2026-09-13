package states;

import backend.WeekData;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.input.gamepad.FlxGamepad;
import haxe.Json;
import openfl.Assets;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import shaders.ColorSwap;
import hxwindowmode.WindowColorMode;

#if VIDEOS_ALLOWED
import objects.VideoSprite;
#end

import states.StoryMenuState;
import states.MainMenuState;
import flixel.addons.display.FlxBackdrop;

typedef TitleData = {
	var titlex:Float;
	var titley:Float;
	var startx:Float;
	var starty:Float;
	var backgroundSprite:String;
	var bpm:Float;
}

class TitleState extends MusicBeatState
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];
	public static var initialized:Bool = false;

	var titleTextColors:Array<FlxColor> = [0xFF33FFFF, 0xFF3333CC];
	var titleTextAlphas:Array<Float> = [1, .64];
	var introFinished:Bool = false;
	var bgPattern:FlxBackdrop;
	var bgImage:FlxSprite;
	var vigImg:FlxSprite;

	override public function create():Void
	{
		Paths.clearStoredMemory();
		super.create();
		Paths.clearUnusedMemory();

		musicLoopStarted = false;
    	musicLooping = false;
    	WindowColorMode.setDarkMode();

		if (!initialized)
		{
			ClientPrefs.loadPrefs();
			Language.reloadPhrases();
		}

		if (!initialized)
		{
			if (FlxG.save.data != null && FlxG.save.data.fullscreen)
				FlxG.fullscreen = FlxG.save.data.fullscreen;

			persistentUpdate = true;
			persistentDraw = true;
		}

		if (FlxG.save.data.weekCompleted != null)
			StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;

		FlxG.mouse.visible = false;

		#if FREEPLAY
		MusicBeatState.switchState(new FreeplayState());
		#elseif CHARTING
		MusicBeatState.switchState(new ChartingState());
		#else
		startIntro();
		#end
	}

	var logoBl:FlxSprite;
	var logoBumpScale:Float = 0.78;
	var logoBaseScale:Float = 0.7;
	var titleText:FlxSprite;
	var swagShader:ColorSwap = null;

	#if VIDEOS_ALLOWED
	var introVideo:VideoSprite = null;
	#end

	var usingIntroVideo:Bool = false;

	var musicLoopStarted:Bool = false;
	var musicLooping:Bool = false;

	function startIntro()
	{
		persistentUpdate = true;

		if (FlxG.sound.music == null)
		{
		    FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
		    FlxG.sound.music.looped = false;
		    musicLooping = true;
		}

		bgImage = new FlxSprite().loadGraphic(Paths.image('lolointro'));
		bgImage.antialiasing = ClientPrefs.data.antialiasing;

		var scale:Float = Math.max(FlxG.width / bgImage.width,FlxG.height / bgImage.height);
		bgImage.setGraphicSize(Std.int(bgImage.width * scale),Std.int(bgImage.height * scale));

		bgImage.updateHitbox();
		bgImage.screenCenter();
		add(bgImage);

		loadJsonData();
		Conductor.bpm = musicBPM;

		vigImg = new FlxSprite().loadGraphic(Paths.image('vig'));
		vigImg.antialiasing = ClientPrefs.data.antialiasing;

		var scaleVig:Float = Math.max(FlxG.width / vigImg.width,FlxG.height / vigImg.height);
		vigImg.setGraphicSize(Std.int(vigImg.width * scaleVig),Std.int(vigImg.height * scaleVig));
				vigImg.alpha = 0.5;

		vigImg.updateHitbox();
		vigImg.screenCenter();


		logoBl = new FlxSprite(logoPosition.x, logoPosition.y);
		logoBl.loadGraphic(Paths.image('logoBumpin'));
		logoBl.antialiasing = ClientPrefs.data.antialiasing;
		logoBaseScale = 0.7;
		logoBumpScale = 0.78;
		logoBl.scale.set(logoBaseScale, logoBaseScale);
		logoBl.updateHitbox();

		if (ClientPrefs.data.shaders)
		{
			swagShader = new ColorSwap();
			logoBl.shader = swagShader.shader;
		}

		FlxTween.tween(logoBl, {x: logoPosition.x + 12}, 1.6, {
			ease: FlxEase.sineInOut,
			type: FlxTween.PINGPONG
		});

		var animFrames:Array<FlxFrame> = [];
		titleText = new FlxSprite(enterPosition.x, enterPosition.y);
		titleText.frames = Paths.getSparrowAtlas('titleEnter');

		@:privateAccess
		{
			titleText.animation.findByPrefix(animFrames, "ENTER IDLE");
			titleText.animation.findByPrefix(animFrames, "ENTER FREEZE");
		}

		if (newTitle = animFrames.length > 0)
		{
			titleText.animation.addByPrefix('idle', "ENTER IDLE", 24);
			titleText.animation.addByPrefix(
				'press',
				ClientPrefs.data.flashing ? "ENTER PRESSED" : "ENTER FREEZE",
				24
			);
		}
		else
		{
			titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
			titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		}

		titleText.animation.play('idle');
		titleText.updateHitbox();

		bgPattern = new FlxBackdrop(Paths.image('titleCheckerBG'));
		bgPattern.alpha = 0.35;
		bgPattern.velocity.set(40, 0);
		bgPattern.antialiasing = ClientPrefs.data.antialiasing;

		add(bgPattern);
		add(vigImg);
		add(logoBl);
		add(titleText);

		if (initialized)
		{
			skippedIntro = true;
		    introFinished = true;
		    musicLooping = true;
		}
		else
		{
			initialized = true;
			startIntroVideo();
		}
	}

	function startIntroVideo():Void
	{
		#if VIDEOS_ALLOWED
		var videoPath:String = Paths.video('introTitle');

		if (Assets.exists(videoPath))
		{
			usingIntroVideo = true;
			introVideo = new VideoSprite(videoPath, false, true, false);
			introVideo.finishCallback = onIntroVideoFinished;
			introVideo.onSkip = onIntroVideoFinished;
			introVideo.startedCallback = onIntroVideoStarted;
			add(introVideo);
			introVideo.play();
			return;
		}
		else
			FlxG.log.warn('[TitleState] Intro video not found: ' + videoPath);
		#end

		if (FlxG.sound.music != null)
			FlxG.sound.music.fadeIn(4, 0, 0.7);

		skipIntro();
	}

	function onIntroVideoStarted():Void
	{
		if (FlxG.sound.music != null)
		{
			#if hxvlc
			var videoTimeMs:Float = haxe.Int64.toInt(introVideo.videoSprite.bitmap.time);
			FlxG.sound.music.time = videoTimeMs;
			#end

			FlxG.sound.music.play();
			FlxG.sound.music.fadeIn(4, 0, 0.7);
			musicLooping = true;
		}
	}

	function onIntroVideoFinished():Void
	{
		#if VIDEOS_ALLOWED
		usingIntroVideo = false;

		if (introVideo != null)
		{
			remove(introVideo);
			introVideo = null;
		}
		#end

		skipIntro();
	}

	var logoPosition:FlxPoint = FlxPoint.get(-150, -100);
	var enterPosition:FlxPoint = FlxPoint.get(100, 576);
	var musicBPM:Float = 102;

	function loadJsonData()
	{
		if (Paths.fileExists('images/gfDanceTitle.json', TEXT))
		{
			var titleRaw:String = Paths.getTextFromFile('images/gfDanceTitle.json');

			if (titleRaw != null && titleRaw.length > 0)
			{
				try
				{
					var titleJSON:TitleData = tjson.TJSON.parse(titleRaw);

					logoPosition.set(titleJSON.titlex, titleJSON.titley);
					enterPosition.set(titleJSON.startx, titleJSON.starty);
					musicBPM = titleJSON.bpm;

					if (titleJSON.backgroundSprite != null &&
						titleJSON.backgroundSprite.trim().length > 0)
					{
						var bg:FlxSprite = new FlxSprite().loadGraphic(
							Paths.image(titleJSON.backgroundSprite)
						);

						bg.antialiasing = ClientPrefs.data.antialiasing;
						add(bg);
					}
				}
				catch(e:haxe.Exception)
				{
					trace('[WARN] Title JSON might broken, ignoring issue...\n${e.details()}');
				}
			}
			else
				trace('[WARN] No Title JSON detected, using default values.');
		}
	}

	var transitioning:Bool = false;
	var newTitle:Bool = false;
	var titleTimer:Float = 0;

	override function update(elapsed:Float)
	{
	    if (FlxG.sound.music != null)
	    {
	        Conductor.songPosition = FlxG.sound.music.time;

	        if (musicLooping && FlxG.sound.music.length > 0)
	        {
	            if (FlxG.sound.music.time >= FlxG.sound.music.length - 50)
	            {
	                FlxG.sound.music.time = 14000;
	                FlxG.sound.music.play();
	            }
	        }
	    }

	    var pressedEnter:Bool = FlxG.keys.justPressed.ENTER || controls.ACCEPT;

		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
				pressedEnter = true;
		}
		#end

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (gamepad != null)
		{
			if (gamepad.justPressed.START)
				pressedEnter = true;

			#if switch
			if (gamepad.justPressed.B)
				pressedEnter = true;
			#end
		}

		if (newTitle)
		{
			titleTimer += FlxMath.bound(elapsed, 0, 1);
			if (titleTimer > 2)
				titleTimer -= 2;
		}

		if (initialized && !transitioning && skippedIntro)
		{
			if (newTitle && !pressedEnter)
			{
				var timer:Float = titleTimer;

				if (timer >= 1)
					timer = (-timer) + 2;

				timer = FlxEase.quadInOut(timer);

				titleText.color = FlxColor.interpolate(
					titleTextColors[0],
					titleTextColors[1],
					timer
				);

				titleText.alpha = FlxMath.lerp(
					titleTextAlphas[0],
					titleTextAlphas[1],
					timer
				);
			}

			if (pressedEnter)
			{
				titleText.color = FlxColor.WHITE;
				titleText.alpha = 1;

				if (titleText != null)
					titleText.animation.play('press');

				FlxG.camera.flash(
					ClientPrefs.data.flashing ? FlxColor.WHITE : 0x4CFFFFFF,
					1
				);

				FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
				transitioning = true;

				new FlxTimer().start(1, function(tmr:FlxTimer)
				{
					MusicBeatState.switchState(new MainMenuState());
					closedState = true;
				});
			}
		}

		if (initialized && pressedEnter && !skippedIntro)
		{
			skipIntro(true);
		}

		if (swagShader != null)
		{
			if (controls.UI_LEFT)
				swagShader.hue -= elapsed * 0.1;

			if (controls.UI_RIGHT)
				swagShader.hue += elapsed * 0.1;
		}

		super.update(elapsed);
	}

	override function destroy():Void
	{
	    if (logoBl != null)
	    {
	        FlxTween.cancelTweensOf(logoBl);
	        FlxTween.cancelTweensOf(logoBl.scale);
	    }
	    super.destroy();
	}

	public static var closedState:Bool = false;

	override function beatHit()
	{
		super.beatHit();

		if (logoBl != null)
		{
			logoBl.scale.set(logoBumpScale, logoBumpScale);
			logoBl.updateHitbox();
			FlxTween.cancelTweensOf(logoBl.scale);

			FlxTween.tween(logoBl.scale, {
				x: logoBaseScale,
				y: logoBaseScale
			}, Conductor.crochet / 1000, {
				ease: FlxEase.quadOut
			});
		}
	}

	var skippedIntro:Bool = false;

	function skipIntro(fromButton:Bool = false):Void
	{
		if (!skippedIntro)
		{
			introFinished = true;

			if (fromButton)
			{
				#if VIDEOS_ALLOWED
				if (introVideo != null)
				{
					remove(introVideo);
					introVideo = null;
					usingIntroVideo = false;
				}
				#end

				if (FlxG.sound.music != null)
				{
					FlxG.sound.music.time = 14000;
					FlxG.sound.music.play();
					musicLooping = true;
				}
			}

			FlxG.camera.flash(FlxColor.WHITE, 4);
			skippedIntro = true;
		}
	}
}