package objects;

import flixel.addons.display.FlxPieDial;

#if hxvlc
import hxvlc.flixel.FlxVideoSprite;
#end

class VideoSprite extends FlxSpriteGroup {
	#if VIDEOS_ALLOWED
	public var finishCallback:Void->Void = null;
	public var onSkip:Void->Void = null;
	public var startedCallback:Void->Void = null;

	final _timeToSkip:Float = 1;
	public var holdingTime:Float = 0;
	public var videoSprite:FlxVideoSprite;
	public var skipSprite:FlxPieDial;
	public var cover:FlxSprite;
	public var canSkip(default, set):Bool = false;

	public var loaded:Bool = false;

	private var videoName:String;

	public var waiting:Bool = false;

	public function new(videoName:String, isWaiting:Bool, canSkip:Bool = false, shouldLoop:Dynamic = false) {
		super();

		this.videoName = videoName;
		scrollFactor.set();
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		waiting = isWaiting;
		if(!waiting)
		{
			cover = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
			cover.scale.set(FlxG.width + 100, FlxG.height + 100);
			cover.screenCenter();
			cover.scrollFactor.set();
			add(cover);
		}

		videoSprite = new FlxVideoSprite();
		videoSprite.antialiasing = ClientPrefs.data.antialiasing;
		add(videoSprite);
		if(canSkip) this.canSkip = true;

		if(!shouldLoop) videoSprite.bitmap.onEndReached.add(finishVideo);

		videoSprite.bitmap.onPlaying.add(function()
		{
			if(startedCallback != null)
			{
				var cb = startedCallback;
				startedCallback = null;
				cb();
			}
		});

		videoSprite.bitmap.onFormatSetup.add(function()
		{

			var fit:Float = Math.min(FlxG.width / videoSprite.frameWidth, FlxG.height / videoSprite.frameHeight);
			videoSprite.scale.set(fit, fit);
			videoSprite.updateHitbox();
			videoSprite.screenCenter();
		});

		loaded = videoSprite.load(videoName, shouldLoop ? ['input-repeat=65545'] : null);
	}

	var alreadyDestroyed:Bool = false;
	override function destroy()
	{
		if(alreadyDestroyed)
			return;
		alreadyDestroyed = true;

		trace('Video destroyed');
		if(cover != null)
		{
			remove(cover);
			cover.destroy();
			cover = null;
		}

		finishCallback = null;
		startedCallback = null;
		onSkip = null;

		if(FlxG.state != null)
		{
			if(FlxG.state.members.contains(this))
				FlxG.state.remove(this);

			if(FlxG.state.subState != null && FlxG.state.subState.members.contains(this))
				FlxG.state.subState.remove(this);
		}
		super.destroy();
	}
	function finishVideo()
	{
		if (!alreadyDestroyed)
		{
			if(finishCallback != null)
				finishCallback();

			destroy();
		}
	}

	override function update(elapsed:Float)
	{
		if(canSkip)
		{
			if(Controls.instance.pressed('accept'))
			{
				holdingTime = Math.max(0, Math.min(_timeToSkip, holdingTime + elapsed));
			}
			else if (holdingTime > 0)
			{
				holdingTime = Math.max(0, FlxMath.lerp(holdingTime, -0.1, FlxMath.bound(elapsed * 3, 0, 1)));
			}
			updateSkipAlpha();

			if(holdingTime >= _timeToSkip)
			{
				if(onSkip != null) onSkip();
				finishCallback = null;
				videoSprite.bitmap.onEndReached.dispatch();
				trace('Skipped video');
				return;
			}
		}
		super.update(elapsed);
	}

	function set_canSkip(newValue:Bool)
	{
		canSkip = newValue;
		if(canSkip)
		{
			if(skipSprite == null)
			{
				skipSprite = new FlxPieDial(0, 0, 40, FlxColor.WHITE, 40, true, 24);
				skipSprite.replaceColor(FlxColor.BLACK, FlxColor.TRANSPARENT);
				skipSprite.x = FlxG.width - (skipSprite.width + 80);
				skipSprite.y = FlxG.height - (skipSprite.height + 72);
				skipSprite.amount = 0;
				add(skipSprite);
			}
		}
		else if(skipSprite != null)
		{
			remove(skipSprite);
			skipSprite.destroy();
			skipSprite = null;
		}
		return canSkip;
	}

	function updateSkipAlpha()
	{
		if(skipSprite == null) return;

		skipSprite.amount = Math.min(1, Math.max(0, (holdingTime / _timeToSkip) * 1.025));
		skipSprite.alpha = FlxMath.remapToRange(skipSprite.amount, 0.025, 1, 0, 1);
	}

	var driftStrikes:Int = 0;

	public function syncTo(targetMs:Float, behindMs:Float = 250, aheadMs:Float = 600):Void
	{
		if(alreadyDestroyed || videoSprite == null || videoSprite.bitmap == null) return;
		if(!videoSprite.bitmap.isPlaying) return;

		var videoTime:Float = haxe.Int64.toInt(videoSprite.bitmap.time);
		if(videoTime < 0) return;

		var drift:Float = videoTime - targetMs;
		if(drift >= -behindMs && drift <= aheadMs)
		{
			driftStrikes = 0;
			return;
		}

		driftStrikes++;
		if(driftStrikes < 2) return;

		driftStrikes = 0;
		videoSprite.bitmap.time = haxe.Int64.ofInt(Std.int(targetMs));
	}

	public function play():Bool return videoSprite != null && videoSprite.play();
	public function resume() videoSprite?.resume();
	public function pause() videoSprite?.pause();
	#end
}