package options;

import backend.ClientPrefs;
import backend.Language;
import backend.Paths;
import backend.StageData;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.FlxObject;
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

	var camFollow:FlxObject;
	var camFollowPos:FlxObject;

	var mainCam:FlxCamera;
	var funnyCam:FlxCamera;

	var exiting:Bool = false;

	function openSelectedSubstate(label:String)
	{
		switch(label)
		{
			case 'Note Colors':
				openSubState(new options.NotesColorSubState());

			case 'Controls':
				openSubState(new options.ControlsSubState());

			case 'Graphics':
				openSubState(new options.GraphicsSettingsSubState());

			case 'Optimizations':
				openSubState(new options.OptimizationsSubState());

			case 'Video Rendering':
				openSubState(new options.VideoRenderingSubState());

			case 'Visuals':
				openSubState(new options.VisualsSettingsSubState());

			case 'Gameplay':
				openSubState(new options.GameplaySettingsSubState());

			case 'Adjust Delay and Combo':
				MusicBeatState.switchState(new options.NoteOffsetState());

			#if TRANSLATIONS_ALLOWED
			case 'Language':
				openSubState(new options.LanguageSubState());
			#end
		}
	}

	override function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end

		mainCam = initPsychCamera();

		funnyCam = new FlxCamera();
		funnyCam.bgColor.alpha = 0;
		FlxG.cameras.add(funnyCam, false);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);

		add(camFollow);
		add(camFollowPos);

		funnyCam.follow(camFollowPos);

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.color = 0xFFea71fd;

		bg.setGraphicSize(Std.int(bg.width * 1.175));
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

			optionText.screenCenter();
			optionText.y += (100 * (num - (options.length / 2))) + 50;

			optionText.cameras = [funnyCam];

			grpOptions.add(optionText);
		}

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

		persistentUpdate = true;
		funnyCam.visible = true;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if(exiting)
			return;

		if (controls.UI_UP_P)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'));
			changeSelection(-1);
		}

		if (controls.UI_DOWN_P)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'));
			changeSelection(1);
		}

		var lerpVal:Float = Math.max(0, Math.min(1, elapsed * 7.5));

		camFollowPos.setPosition(
			camFollowPos.x,
			FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal)
		);

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));

			exiting = true;

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
			if(item == null)
				continue;

			item.targetY = num - curSelected;

			item.alpha = 0.6;

			if (num == curSelected)
			{
				item.alpha = 1;

				var thing:Float = grpOptions.members.length > 6
					? grpOptions.members.length * 2
					: 0;

				camFollow.setPosition(
					FlxG.width / 2,
					item.y + 100 - thing
				);
			}
		}
	}

	override function destroy()
	{
		ClientPrefs.loadPrefs();
		super.destroy();
	}
}
