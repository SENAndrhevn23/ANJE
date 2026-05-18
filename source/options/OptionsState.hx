package options;

import backend.ClientPrefs;
import backend.Language;
import backend.Paths;
import backend.StageData;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;

import states.MainMenuState;
import states.PlayState;

class OptionsState extends MusicBeatState
{
	var options:Array<String> = [
		'Note Colors',
		'Controls',
		'Adjust Delay and Combo',
		'Graphics',
		'Optimizations',
		'Video Rendering',
		'Visuals',
		'Gameplay'
		#if TRANSLATIONS_ALLOWED , 'Language' #end
	];

	private var grpOptions:FlxTypedGroup<Alphabet>;
	private static var curSelected:Int = 0;

	public static var menuBG:FlxSprite;
	public static var onPlayState:Bool = false;

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;

	// MENU SIZE
	var menuScale:Float = 0.8;

	function openSelectedSubstate(label:String)
	{
		switch(label)
		{
			case 'Note Colors':
				openSubState(new NotesColorSubState());

			case 'Controls':
				openSubState(new ControlsSubState());

			case 'Graphics':
				openSubState(new GraphicsSettingsSubState());

			case 'Optimizations':
				openSubState(new OptimizationsSubState());

			case 'Video Rendering':
				openSubState(new VideoRenderingSubState());

			case 'Visuals':
				openSubState(new VisualsSettingsSubState());

			case 'Gameplay':
				openSubState(new GameplaySettingsSubState());

			case 'Adjust Delay and Combo':
				MusicBeatState.switchState(new NoteOffsetState());

			case 'Language':
				openSubState(new LanguageSubState());
		}
	}

	override function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.color = 0xFFea71fd;
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		for (num => option in options)
		{
			var optionText:Alphabet = new Alphabet(
				0,
				0,
				Language.getPhrase('options_$option', option),
				true
			);

			// CHANGE SIZE HERE
			optionText.scale.set(menuScale, menuScale);
			optionText.updateHitbox();

			optionText.screenCenter();

			// STATIC POSITIONS
			optionText.y += (92 * (num - (options.length / 2))) + 45;

			// DISABLE SCROLLING
			optionText.isMenuItem = false;
			optionText.targetY = 0;

			grpOptions.add(optionText);
		}

		selectorLeft = new Alphabet(0, 0, '>', true);
		selectorLeft.scale.set(menuScale, menuScale);
		selectorLeft.updateHitbox();
		add(selectorLeft);

		selectorRight = new Alphabet(0, 0, '<', true);
		selectorRight.scale.set(menuScale, menuScale);
		selectorRight.updateHitbox();
		add(selectorRight);

		changeSelection();

		ClientPrefs.saveSettings();

		super.create();
	}

	override function closeSubState()
	{
		super.closeSubState();

		ClientPrefs.saveSettings();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// LOCK CAMERA
		FlxG.camera.scroll.set(0, 0);

		if (controls.UI_UP_P)
			changeSelection(-1);

		if (controls.UI_DOWN_P)
			changeSelection(1);

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));

			if(onPlayState)
			{
				StageData.loadDirectory(PlayState.SONG);
				LoadingState.loadAndSwitchState(new PlayState());
				FlxG.sound.music.volume = 0;
			}
			else
			{
				MusicBeatState.switchState(new MainMenuState());
			}
		}
		else if (controls.ACCEPT)
		{
			openSelectedSubstate(options[curSelected]);
		}
	}

	function changeSelection(change:Int = 0)
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);

		for (num => item in grpOptions.members)
		{
			if(item == null) continue;

			item.alpha = 0.6;

			if (num == curSelected)
			{
				item.alpha = 1;

				selectorLeft.x = item.x - 63;
				selectorLeft.y = item.y;

				selectorRight.x = item.x + item.width + 15;
				selectorRight.y = item.y;
			}
		}

		// REMOVED SCROLL SOUND
		// FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	override function destroy()
	{
		ClientPrefs.loadPrefs();
		super.destroy();
	}
}
