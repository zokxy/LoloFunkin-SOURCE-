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

	public static inline final LOOP_START_MS:Float = 14000;

	static inline final VIDEO_SYNC_INTERVAL:Float = 0.5;

	var titleTextColors:Array<FlxColor> = [0xFF33FFFF, 0xFF3333CC];
	var titleTextAlphas:Array<Float> = [1, .64];
	var introFinished:Bool = false;
	var bgPattern:FlxBackdrop;
	var bgImage:FlxSprite;
	var vigImg:FlxSprite;
	var titleAnim:FlxSprite;

	override public function create():Void
	{
		Paths.clearStoredMemory();
		super.create();
		Paths.clearUnusedMemory();

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
	var logoBumpScale:Float = 0.68;
	var logoBaseScale:Float = 0.6;
	var titleText:FlxSprite;
	var swagShader:ColorSwap = null;

	#if VIDEOS_ALLOWED
	var introVideo:VideoSprite = null;
	#end

	var usingIntroVideo:Bool = false;
	var videoSyncTimer:Float = 0;

	public static function playMenuMusic(volume:Float = 0.7):Void
	{
		if (FlxG.sound.music == null || !FlxG.sound.music.playing)
		{
			FlxG.sound.playMusic(Paths.music('freakyMenu'), volume);
			FlxG.sound.music.time = LOOP_START_MS;
		}

		FlxG.sound.music.looped = true;
		FlxG.sound.music.loopTime = LOOP_START_MS;
		FlxG.sound.music.volume = volume;
	}

	public static function configureMusicLoop():Void
	{
		if (FlxG.sound.music == null) return;

		FlxG.sound.music.looped = true;
		FlxG.sound.music.loopTime = LOOP_START_MS;
	}

	function prepareIntroMusic():Void
	{
		FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
		configureMusicLoop();
		FlxG.sound.music.pause();
	}

	function jumpToTitleMusic():Void
	{
		if (FlxG.sound.music == null)
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 0.7);

		configureMusicLoop();
		FlxG.sound.music.fadeTween?.cancel();
		FlxG.sound.music.volume = 0.7;
		FlxG.sound.music.time = LOOP_START_MS;
		FlxG.sound.music.play();
	}

	function videoExists(path:String):Bool
	{
		#if sys
		if (sys.FileSystem.exists(path)) return true;
		#end
		return Assets.exists(path);
	}

	function startIntro()
	{
		persistentUpdate = true;

		bgImage = new FlxSprite().loadGraphic(Paths.image('lolointro'));
		bgImage.antialiasing = ClientPrefs.data.antialiasing;

		var scale:Float = Math.max(FlxG.width / bgImage.width, FlxG.height / bgImage.height);
		bgImage.setGraphicSize(Std.int(bgImage.width * scale), Std.int(bgImage.height * scale));

		bgImage.updateHitbox();
		bgImage.screenCenter();
		add(bgImage);

		loadJsonData();
		Conductor.bpm = musicBPM;

		vigImg = new FlxSprite().loadGraphic(Paths.image('vig'));
		vigImg.antialiasing = ClientPrefs.data.antialiasing;

		var scaleVig:Float = Math.max(FlxG.width / vigImg.width, FlxG.height / vigImg.height);
		vigImg.setGraphicSize(Std.int(vigImg.width * scaleVig), Std.int(vigImg.height * scaleVig));
		vigImg.alpha = 0.5;

		vigImg.updateHitbox();
		vigImg.screenCenter();

		titleAnim = new FlxSprite(350, -100);
		titleAnim.frames = Paths.getSparrowAtlas('Lo');
		titleAnim.animation.addByPrefix('idle', 'idle', 16, true);
		titleAnim.animation.play('idle');
		titleAnim.antialiasing = ClientPrefs.data.antialiasing;
		titleAnim.setGraphicSize(titleAnim.width / 1.3, titleAnim.height / 1.3);
		titleAnim.updateHitbox();

		logoBl = new FlxSprite(logoPosition.x, logoPosition.y);
		logoBl.loadGraphic(Paths.image('logoBumpin'));
		logoBl.antialiasing = ClientPrefs.data.antialiasing;
		logoBaseScale = 0.6;
		logoBumpScale = 0.68;
		logoBl.scale.set(logoBaseScale, logoBaseScale);
		logoBl.updateHitbox();

		if (ClientPrefs.data.shaders)
		{
			swagShader = new ColorSwap();
			logoBl.shader = swagShader.shader;
		}

		FlxTween.tween(logoBl, {x: logoPosition.x + 12}, 1.6, {ease: FlxEase.sineInOut, type: FlxTween.PINGPONG});

		var animFrames:Array<FlxFrame> = [];
		titleText = new FlxSprite(enterPosition.x, enterPosition.y);
		titleText.frames = Paths.getSparrowAtlas('titleEnter');
		titleText.setGraphicSize(titleText.width / 1.3, titleText.height / 1.3);

		@:privateAccess
		{
			titleText.animation.findByPrefix(animFrames, "ENTER IDLE");
			titleText.animation.findByPrefix(animFrames, "ENTER FREEZE");
		}

		if (newTitle = animFrames.length > 0)
		{
			titleText.animation.addByPrefix('idle', "ENTER IDLE", 24);
			titleText.animation.addByPrefix('press', ClientPrefs.data.flashing ? "ENTER PRESSED" : "ENTER FREEZE", 24);
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
		add(titleAnim);
		add(logoBl);
		add(titleText);

		if (initialized)
		{
			skippedIntro = true;
			introFinished = true;
			playMenuMusic(0.7);
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

		if (videoExists(videoPath))
		{

			prepareIntroMusic();

			introVideo = new VideoSprite(videoPath, false, false, false);

			if (introVideo.loaded)
			{
				usingIntroVideo = true;
				introVideo.finishCallback = function() {
					onIntroVideoFinished(false);
				};
				introVideo.startedCallback = onIntroVideoStarted;
				add(introVideo);

				if (introVideo.play())
					return;

				usingIntroVideo = false;
				FlxG.log.warn('[TitleState] Intro video failed to play: ' + videoPath);
			}
			else
				FlxG.log.warn('[TitleState] Intro video failed to load: ' + videoPath);

			introVideo.finishCallback = null;
			introVideo.startedCallback = null;
			remove(introVideo, true);
			introVideo.destroy();
			introVideo = null;
		}
		else
			FlxG.log.warn('[TitleState] Intro video not found: ' + videoPath);
		#end

		skipIntro(true);
	}

	function onIntroVideoStarted():Void
	{
		if (!usingIntroVideo || skippedIntro) return;

		if (FlxG.sound.music == null)
		{
			prepareIntroMusic();
		}

		FlxG.sound.music.volume = 0;
		FlxG.sound.music.time = 0;
		FlxG.sound.music.play();
		FlxG.sound.music.fadeIn(4, 0, 0.7);

		videoSyncTimer = VIDEO_SYNC_INTERVAL;
	}

	function onIntroVideoFinished(wasSkipped:Bool = false):Void
	{
		#if VIDEOS_ALLOWED
		usingIntroVideo = false;

		if (introVideo != null)
		{
			introVideo.finishCallback = null;
			introVideo.startedCallback = null;
			if (introVideo.videoSprite != null)
				introVideo.videoSprite.stop();
			remove(introVideo, true);
			introVideo.destroy();
			introVideo = null;
		}
		#end

		skipIntro(wasSkipped);
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

			#if VIDEOS_ALLOWED

			if (usingIntroVideo && introVideo != null && FlxG.sound.music.playing)
			{
				videoSyncTimer -= elapsed;
				if (videoSyncTimer <= 0)
				{
					videoSyncTimer = VIDEO_SYNC_INTERVAL;
					introVideo.syncTo(FlxG.sound.music.time);
				}
			}
			#end
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

				if (titleText != null)
				{
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
			}

			if (pressedEnter)
			{
				if (titleText != null)
				{
					titleText.color = FlxColor.WHITE;
					titleText.alpha = 1;
					titleText.animation.play('press');
				}

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
		else if (initialized && pressedEnter && !skippedIntro)
		{
			#if VIDEOS_ALLOWED
			if (usingIntroVideo)
				onIntroVideoFinished(true);
			else
				skipIntro(true);
			#else
			skipIntro(true);
			#end
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
		#if VIDEOS_ALLOWED
		if (introVideo != null)
		{
			introVideo.finishCallback = null;
			introVideo.startedCallback = null;
		}
		#end

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
			skippedIntro = true;
			introFinished = true;

			if (fromButton)
				jumpToTitleMusic();
			else
				configureMusicLoop();

			FlxG.camera.flash(FlxColor.WHITE, 4);
		}
	}
}