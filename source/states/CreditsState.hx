package states;

import objects.AttachedSprite;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.text.FlxText;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;

class CreditsState extends MusicBeatState
{
	var curSelected:Int = -1;
	var curBoardSelected:Int = -1;

	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var iconArray:Array<AttachedSprite> = [];
	private var creditsStuff:Array<Array<String>> = [];

	private var boardGroup:FlxTypedGroup<FlxSprite>;
	private var boardStuff:Array<Array<String>> = [];
	var boardBg:FlxSprite;

	var bg:FlxSprite;
	var descText:FlxText;
	var intendedColor:FlxColor;
	var descBox:AttachedSprite;

	var offsetThing:Float = -75;
	var showOriginalCredits:Bool = false; 

	var myBoardList:Array<Array<String>> = [
		["Marlikov",   "mydev1",  "Director, Voice actor, Sound designer", "https://x.com",      "444444"],
		["Abra",       "mydev2",  "Director, Musician", "https://x.com",      "14967B"],
		["zokx",       "mydev3",  "Coder, ogurchik", "https://x.com",      "3E813A"],
		["dizzer",     "mydev4",  "Artist", "https://x.com",      "9E29CF"],
		["x-frask",    "mydev5",  "3D Animator", "https://x.com",      "64A250"],
		["!v1kruins!", "mydev6",  "Artist", "https://x.com",      "FFBD40"],
		["Slaus",      "mydev7",  "Musician", "https://x.com",      "D21C11"],
		["TheVoid",    "mydev8",  "Writer, Design help", "https://x.com",      "3C2E4E"],
		["YB",         "mydev9",  "Voice actor", "https://x.com",      "E1843A"],
		["Kukushka",   "mydev10", "Artist, Animator", "https://x.com",      "5F5F5F"],
		["whiterer",   "mydev11", "Animator", "https://x.com",      "5F5F5F"]
	];

	override function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Menus (Credits)", null);
		#end

		persistentUpdate = true;
		
		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);
		bg.screenCenter();
		
		boardGroup = new FlxTypedGroup<FlxSprite>();
		
		boardBg = new FlxSprite();
		if (Paths.fileExists('images/credits/board/board_bg.png', IMAGE, false, 'shared')) {
			boardBg.loadGraphic(Paths.image('credits/board/board_bg', 'shared'));
		} else {
			boardBg.makeGraphic(1160, 500, FlxColor.fromRGB(60, 40, 25)); 
		}
		boardBg.screenCenter();
		boardBg.y -= 30;
		boardGroup.add(boardBg);

		for(i in myBoardList) boardStuff.push(i);

		for (i => dev in boardStuff)
		{
			var assetPath:String = 'credits/missing_icon'; 
			
			if(dev[1] != null && dev[1].length > 0) {
				var checkPath = 'images/credits/board/' + dev[1] + '.png';
				if (Paths.fileExists(checkPath, IMAGE, false, 'shared')) {
					assetPath = 'credits/board/' + dev[1];
				}
			}

			var devSprite:FlxSprite = new FlxSprite();
			devSprite.loadGraphic(Paths.image(assetPath, 'shared'));
			
			if(devSprite.width > 160 || devSprite.height > 160) {
				devSprite.setGraphicSize(160, 160);
				devSprite.updateHitbox();
			}

			var row:Int = Math.floor(i / 5);
			var col:Int = i % 5;
			
			devSprite.x = boardBg.x + 45 + (col * 220); 
			devSprite.y = boardBg.y + 40 + (row * 220);
			devSprite.antialiasing = ClientPrefs.data.antialiasing;
			devSprite.ID = i; 
			boardGroup.add(devSprite);
		}
		add(boardGroup);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		#if MODS_ALLOWED
		for (mod in Mods.parseList().enabled) pushModCreditsToList(mod);
		#end

		var defaultList:Array<Array<String>> = [
			["Psych Engine Team"],
			["Shadow Mario",		"shadowmario",		"Main Programmer and Head of Psych Engine",					"https://ko-fi.com/shadowmario",	"444444"],
			["Riveren",				"riveren",			"Main Artist/Animator of Psych Engine",						"https://x.com/riverennn",			"14967B"],
			[""],
			["Former Engine Members"],
			["bb-panzu",			"bb",				"Ex-Programmer of Psych Engine",							"https://x.com/bbsub3",				"3E813A"],
			[""],
			["Engine Contributors"],
			["crowplexus",			"crowplexus",	"Linux Support, HScript Iris, Input System v3, and Other PRs",	"https://twitter.com/IamMorwen",	"CFCFCF"],
			["Kamizeta",			"kamizeta",			"Creator of Pessy, Psych Engine's mascot.",				"https://www.instagram.com/cewweey/",	"D21C11"],
			["MaxNeton",			"maxneton",			"Loading Screen Easter Egg Artist/Animator.",	"https://bsky.app/profile/maxneton.bsky.social","3C2E4E"],
			["Keoiki",				"keoiki",			"Note Splash Animations and Latin Alphabet",				"https://x.com/Keoiki_",			"D2D2D2"],
			["SqirraRNG",			"sqirra",			"Crash Handler and Base code for\nChart Editor's Waveform",	"https://x.com/gedehari",			"E1843A"],
			["EliteMasterEric",		"mastereric",		"Runtime Shaders support and Other PRs",					"https://x.com/EliteMasterEric",	"FFBD40"],
			["MAJigsaw77",			"majigsaw",			".MP4 Video Loader Library (hxvlc)",						"https://x.com/MAJigsaw77",			"5F5F5F"],
			["iFlicky",				"flicky",			"Composer of Psync and Tea Time\nAnd some sound effects",	"https://x.com/flicky_i",			"9E29CF"],
			["KadeDev",				"kade",				"Fixed some issues on Chart Editor and Other PRs",			"https://x.com/kade0912",			"64A250"],
			["superpowers04",		"superpowers04",	"LUA JIT Fork",												"https://x.com/superpowers04",		"B957ED"],
			["CheemsAndFriends",	"cheems",			"Creator of FlxAnimate",									"https://x.com/CheemsnFriendos",	"E1E1E1"],
			[""],
			["Funkin' Crew"],
			["ninjamuffin99",		"ninjamuffin99",	"Programmer of Friday Night Funkin'",						"https://x.com/ninja_muffin99",		"CF2D2D"],
			["PhantomArcade",		"phantomarcade",	"Animator of Friday Night Funkin'",							"https://x.com/PhantomArcade3K",	"FADC45"],
			["evilsk8r",			"evilsk8r",			"Artist of Friday Night Funkin'",							"https://x.com/evilsk8r",			"5ABD4B"],
			["kawaisprite",			"kawaisprite",		"Composer of Friday Night Funkin'",							"https://x.com/kawaisprite",		"378FC7"],
			[""],
			["Psych Engine Discord"],
			["Join the Psych Ward!", "discord", "", "https://discord.gg/2ka77eMXDv", "5165F6"]
		];
		
		for(i in defaultList) creditsStuff.push(i);
	
		for (i => credit in creditsStuff)
		{
			var isSelectable:Bool = !unselectableCheck(i);
			var optionText:Alphabet = new Alphabet(FlxG.width / 2, 300, credit[0], !isSelectable);
			optionText.isMenuItem = true;
			optionText.targetY = i;
			optionText.changeX = false;
			optionText.snapToPosition();
			grpOptions.add(optionText);

			if(isSelectable)
			{
				var str:String = 'credits/missing_icon';
				if(credit[1] != null && credit[1].length > 0) {
					var fileName = 'credits/' + credit[1];
					if (Paths.fileExists('images/$fileName.png', IMAGE)) str = fileName;
				}

				var icon:AttachedSprite = new AttachedSprite(str);
				icon.xAdd = optionText.width + 10;
				icon.sprTracker = optionText;
				iconArray.push(icon);
				add(icon);

				if(curSelected == -1) curSelected = i;
			}
			else optionText.alignment = CENTERED;
		}
		
		descBox = new AttachedSprite();
		descBox.makeGraphic(1, 1, FlxColor.BLACK);
		descBox.xAdd = -10;
		descBox.yAdd = -10;
		descBox.alphaMult = 0.6;
		descBox.alpha = 0.6;
		add(descBox);

		descText = new FlxText(50, FlxG.height + offsetThing - 25, 1180, "", 32);
		descText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		descText.scrollFactor.set();
		descBox.sprTracker = descText;
		add(descText);

		bg.color = CoolUtil.colorFromString(boardStuff[0][4]);
		intendedColor = bg.color;
		
		FlxG.mouse.visible = true;

		toggleCreditsMode(false);
		super.create();
	}

	var quitting:Bool = false;
	var holdTime:Float = 0;
	
	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.7) FlxG.sound.music.volume += 0.5 * elapsed;

		if (FlxG.keys.justPressed.TAB) {
			toggleCreditsMode(!showOriginalCredits);
		}

		if(!quitting)
		{
			if (controls.BACK)
			{
				FlxG.mouse.visible = false;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
				quitting = true;
			}

			if (!showOriginalCredits) 
			{
				var targetScrollX = (FlxG.mouse.x - FlxG.width / 2) * 0.02;
				var targetScrollY = (FlxG.mouse.y - FlxG.height / 2) * 0.02;
				FlxG.camera.scroll.x = FlxMath.lerp(targetScrollX, FlxG.camera.scroll.x, Math.exp(-elapsed * 10));
				FlxG.camera.scroll.y = FlxMath.lerp(targetScrollY, FlxG.camera.scroll.y, Math.exp(-elapsed * 10));
				var overlapSomething:Bool = false;

				boardGroup.forEach(function(spr:FlxSprite) {
					if (spr != boardBg && FlxG.mouse.overlaps(spr)) {
						overlapSomething = true;
						if (curBoardSelected != spr.ID) {
							curBoardSelected = spr.ID;
							updateBoardSelection();
						}

						spr.scale.set(FlxMath.lerp(1.1, spr.scale.x, Math.exp(-elapsed * 9)), FlxMath.lerp(1.1, spr.scale.y, Math.exp(-elapsed * 9)));

						if (FlxG.mouse.justPressed) {
							var link:String = boardStuff[curBoardSelected][3];
							if (link != null && link.length > 4) {
								CoolUtil.browserLoad(link);
							}
						}
					} else if (spr != boardBg) {
						spr.scale.set(FlxMath.lerp(1.0, spr.scale.x, Math.exp(-elapsed * 9)), FlxMath.lerp(1.0, spr.scale.y, Math.exp(-elapsed * 9)));
					}
				});

				if (!overlapSomething && curBoardSelected != -1) {
					curBoardSelected = -1;
					descText.visible = descBox.visible = false;
				}
			} 
			else 
			{
				if(creditsStuff.length > 1)
				{
					var shiftMult:Int = FlxG.keys.pressed.SHIFT ? 3 : 1;

					if (controls.UI_UP_P) { changeSelection(-shiftMult); holdTime = 0; }
					if (controls.UI_DOWN_P) { changeSelection(shiftMult); holdTime = 0; }

					if(controls.UI_DOWN || controls.UI_UP)
					{
						var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
						holdTime += elapsed;
						var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

						if(holdTime > 0.5 && checkNewHold - checkLastHold > 0) {
							changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
						}
					}
				}

				if(controls.ACCEPT && (creditsStuff[curSelected][3] == null || creditsStuff[curSelected][3].length > 4)) {
					CoolUtil.browserLoad(creditsStuff[curSelected][3]);
				}
			}
		}
		
		if (showOriginalCredits) {
			for (item in grpOptions.members)
			{
				if(!item.bold) {
					var lerpVal:Float = Math.exp(-elapsed * 12);
					if(item.targetY == 0) {
						var lastX:Float = item.x;
						item.screenCenter(X);
						item.x = FlxMath.lerp(item.x - 70, lastX, lerpVal);
					} else {
						item.x = FlxMath.lerp(200 + -40 * Math.abs(item.targetY), item.x, lerpVal);
					}
				}
			}
		}

		super.update(elapsed);
	}

	function toggleCreditsMode(showOriginal:Bool)
	{
		showOriginalCredits = showOriginal;

		boardGroup.visible = !showOriginalCredits;
		grpOptions.visible = showOriginalCredits;
		for (icon in iconArray) icon.visible = showOriginalCredits;

		if (showOriginalCredits) {
			FlxG.camera.scroll.set(0, 0);
			changeSelection();
		} else {
			descText.visible = descBox.visible = false;
			curBoardSelected = -1;
		}
	}

	var moveTween:FlxTween = null;
	function updateBoardSelection()
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		var newColor:FlxColor = CoolUtil.colorFromString(boardStuff[curBoardSelected][4]);
		if(newColor != intendedColor) {
			intendedColor = newColor;
			FlxTween.cancelTweensOf(bg);
			FlxTween.color(bg, 0.4, bg.color, intendedColor);
		}

		descText.text = boardStuff[curBoardSelected][2];
		if(descText.text.trim().length > 0) {
			descText.visible = descBox.visible = true;
			descText.y = FlxG.height - descText.height + offsetThing - 60;
	
			if(moveTween != null) moveTween.cancel();
			moveTween = FlxTween.tween(descText, {y : descText.y + 75}, 0.25, {ease: FlxEase.sineOut});
	
			descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
			descBox.updateHitbox();
		}
	}

	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		do {
			curSelected = FlxMath.wrap(curSelected + change, 0, creditsStuff.length - 1);
		} while(unselectableCheck(curSelected));

		var newColor:FlxColor = CoolUtil.colorFromString(creditsStuff[curSelected][4]);
		if(newColor != intendedColor) {
			intendedColor = newColor;
			FlxTween.cancelTweensOf(bg);
			FlxTween.color(bg, 1, bg.color, intendedColor);
		}

		for (num => item in grpOptions.members) {
			item.targetY = num - curSelected;
			if(!unselectableCheck(num)) {
				item.alpha = 0.6;
				if (item.targetY == 0) item.alpha = 1;
			}
		}

		descText.text = creditsStuff[curSelected][2];
		if(descText.text.trim().length > 0) {
			descText.visible = descBox.visible = true;
			descText.y = FlxG.height - descText.height + offsetThing - 60;
	
			if(moveTween != null) moveTween.cancel();
			moveTween = FlxTween.tween(descText, {y : descText.y + 75}, 0.25, {ease: FlxEase.sineOut});
	
			descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
			descBox.updateHitbox();
		} else descText.visible = descBox.visible = false;
	}

	#if MODS_ALLOWED
	function pushModCreditsToList(folder:String)
	{
		var creditsFile:String = Paths.mods(folder + '/data/credits.txt');
		if (FileSystem.exists(creditsFile)) {
			var firstarray:Array<String> = File.getContent(creditsFile).split('\n');
			for(i in firstarray) {
				var arr:Array<String> = i.replace('\\n', '\n').split("::");
				if(arr.length >= 5) arr.push(folder);
				creditsStuff.push(arr);
			}
			creditsStuff.push(['']);
		}
	}
	#end

	private function unselectableCheck(num:Int):Bool {
		return creditsStuff[num].length <= 1;
	}
}