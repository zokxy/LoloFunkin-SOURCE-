package states;

import flixel.input.keyboard.FlxKey;
import flixel.graphics.frames.FlxFrame;
import flixel.input.gamepad.FlxGamepad;
import openfl.Assets;
import shaders.ColorSwap;
import hxwindowmode.WindowColorMode;

#if VIDEOS_ALLOWED
import objects.VideoSprite;
#end

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
	public static var closedState:Bool = false;

	public static inline final LOOP_START_MS:Float = 14000;

	static inline final VIDEO_SYNC_INTERVAL:Float = 0.5;

	var titleTextColors:Array<FlxColor> = [0xFF33FFFF, 0xFF3333CC];
	var titleTextAlphas:Array<Float> = [1, .64];

	var bgPattern:FlxBackdrop;
	var bgImage:FlxSprite;
	var vigImg:FlxSprite;
	var titleAnim:FlxSprite;
	var logoBl:FlxSprite;
	var titleText:FlxSprite;
	var swagShader:ColorSwap = null;

	var logoBumpScale:Float = 0.68;
	var logoBaseScale:Float = 0.6;

	var logoPosition:FlxPoint = FlxPoint.get(-150, -100);
	var enterPosition:FlxPoint = FlxPoint.get(100, 576);
	var musicBPM:Float = 102;

	var transitioning:Bool = false;
	var newTitle:Bool = false;
	var titleTimer:Float = 0;
	var skippedIntro:Bool = false;

	#if VIDEOS_ALLOWED
	var introVideo:VideoSprite = null;
	#end

	var usingIntroVideo:Bool = false;

	var videoStarted:Bool = false;

	var skipQueued:Bool = false;
	var videoSyncTimer:Float = 0;

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

	function fitToScreen(spr:FlxSprite):Void
	{
		var scale:Float = Math.max(FlxG.width / spr.width, FlxG.height / spr.height);
		spr.setGraphicSize(Std.int(spr.width * scale), Std.int(spr.height * scale));
		spr.updateHitbox();
		spr.screenCenter();
	}

	function startIntro()
	{
		persistentUpdate = true;

		bgImage = new FlxSprite().loadGraphic(Paths.image('lolointro'));
		bgImage.antialiasing = ClientPrefs.data.antialiasing;
		fitToScreen(bgImage);
		add(bgImage);

		loadJsonData();
		Conductor.bpm = musicBPM;

		vigImg = new FlxSprite().loadGraphic(Paths.image('vig'));
		vigImg.antialiasing = ClientPrefs.data.antialiasing;
		fitToScreen(vigImg);
		vigImg.alpha = 0.5;

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

		newTitle = animFrames.length > 0;

		if (newTitle)
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

				FlxG.log.warn('[TitleState] Intro video failed to play: ' + videoPath);
			}
			else
				FlxG.log.warn('[TitleState] Intro video failed to load: ' + videoPath);

			disposeIntroVideo();
		}
		else
			FlxG.log.warn('[TitleState] Intro video not found: ' + videoPath);
		#end

		skipIntro(true);
	}

	function onIntroVideoStarted():Void
	{

		videoStarted = true;

		if (!usingIntroVideo || skippedIntro) return;

		if (FlxG.sound.music == null)
			prepareIntroMusic();

		FlxG.sound.music.volume = 0;
		FlxG.sound.music.time = 0;
		FlxG.sound.music.play();
		FlxG.sound.music.fadeIn(4, 0, 0.7);

		videoSyncTimer = VIDEO_SYNC_INTERVAL;
	}

	function onIntroVideoFinished(wasSkipped:Bool = false):Void
	{
		disposeIntroVideo();
		skipIntro(wasSkipped);
	}

	function disposeIntroVideo():Void
	{
		usingIntroVideo = false;
		videoStarted = false;
		skipQueued = false;

		#if VIDEOS_ALLOWED
		if (introVideo == null) return;

		var video:VideoSprite = introVideo;
		introVideo = null;

		video.finishCallback = null;
		video.startedCallback = null;

		try
		{
			if (video.videoSprite != null)
				video.videoSprite.stop();
		}
		catch (e:Dynamic) {}

		remove(video, true);

		try
		{
			video.destroy();
		}
		catch (e:Dynamic) {}
		#end
	}

	function loadJsonData()
	{
		if (!Paths.fileExists('images/gfDanceTitle.json', TEXT)) return;

		var titleRaw:String = Paths.getTextFromFile('images/gfDanceTitle.json');

		if (titleRaw == null || titleRaw.length == 0)
		{
			trace('[WARN] No Title JSON detected, using default values.');
			return;
		}

		try
		{
			var titleJSON:TitleData = tjson.TJSON.parse(titleRaw);

			logoPosition.set(titleJSON.titlex, titleJSON.titley);
			enterPosition.set(titleJSON.startx, titleJSON.starty);
			musicBPM = titleJSON.bpm;

			if (titleJSON.backgroundSprite != null && titleJSON.backgroundSprite.trim().length > 0)
			{
				var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image(titleJSON.backgroundSprite));
				bg.antialiasing = ClientPrefs.data.antialiasing;
				add(bg);
			}
		}
		catch (e:haxe.Exception)
		{
			trace('[WARN] Title JSON might broken, ignoring issue...\n${e.details()}');
		}
	}

	function isEnterPressed():Bool
	{
		if (FlxG.keys.justPressed.ENTER || controls.ACCEPT) return true;

		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed) return true;
		}
		#end

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (gamepad != null)
		{
			if (gamepad.justPressed.START) return true;

			#if switch
			if (gamepad.justPressed.B) return true;
			#end
		}

		return false;
	}

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
		{
			Conductor.songPosition = FlxG.sound.music.time;

			#if VIDEOS_ALLOWED
			if (usingIntroVideo && videoStarted && introVideo != null && FlxG.sound.music.playing)
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

		var pressedEnter:Bool = isEnterPressed();

		if (newTitle)
		{
			titleTimer += FlxMath.bound(elapsed, 0, 1);
			if (titleTimer > 2)
				titleTimer -= 2;
		}

		if (skippedIntro && !transitioning)
		{
			if (newTitle && !pressedEnter && titleText != null)
			{
				var timer:Float = titleTimer;

				if (timer >= 1)
					timer = 2 - timer;

				timer = FlxEase.quadInOut(timer);

				titleText.color = FlxColor.interpolate(titleTextColors[0], titleTextColors[1], timer);
				titleText.alpha = FlxMath.lerp(titleTextAlphas[0], titleTextAlphas[1], timer);
			}

			if (pressedEnter)
			{
				if (titleText != null)
				{
					titleText.color = FlxColor.WHITE;
					titleText.alpha = 1;
					titleText.animation.play('press');
				}

				FlxG.camera.flash(ClientPrefs.data.flashing ? FlxColor.WHITE : 0x4CFFFFFF, 1);
				FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
				transitioning = true;

				new FlxTimer().start(1, function(tmr:FlxTimer)
				{
					MusicBeatState.switchState(new MainMenuState());
					closedState = true;
				});
			}
		}
		else if (!skippedIntro)
		{
			if (pressedEnter)
			{
				if (usingIntroVideo && !videoStarted)
					skipQueued = true;
				else if (usingIntroVideo)
					onIntroVideoFinished(true);
				else
					skipIntro(true);
			}
			else if (skipQueued && videoStarted)
			{
				skipQueued = false;
				onIntroVideoFinished(true);
			}
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
		disposeIntroVideo();

		if (logoBl != null)
		{
			FlxTween.cancelTweensOf(logoBl);
			FlxTween.cancelTweensOf(logoBl.scale);
		}

		logoPosition.put();
		enterPosition.put();

		super.destroy();
	}

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

	function skipIntro(fromButton:Bool = false):Void
	{
		if (skippedIntro) return;

		skippedIntro = true;

		if (fromButton)
			jumpToTitleMusic();
		else
			configureMusicLoop();

		FlxG.camera.flash(FlxColor.WHITE, 4);
	}
}