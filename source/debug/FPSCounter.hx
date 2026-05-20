package debug;

import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import openfl.system.System;

class FPSCounter extends FlxText
{
	public var currentFPS(default, null):Int = 0;

	public var highestFPS:Int = 0;
	public var lowestFPS:Int = 9999;

	public var currentMemoryMB:Float = 0;
	public var maxMemoryMB:Float = 0;

	public var memoryBytes(get, never):Float;

	@:noCompletion private var times:Array<Float> = [];
	private var deltaTimeout:Float = 0.0;

	public function new(x:Float = 10, y:Float = 10, color:Int = 0xFFFFFFFF)
	{
		super(x, y, 0, "", 14);

		setFormat(Paths.font("fps.ttf"), 14, color);

		scrollFactor.set(0, 0);
		moves = false;
		selectable = false;

		// Proper semi-transparent background
		background = true;
		backgroundColor = 0x000000;
		alpha = 0.5;

		text = "FPS: 0 | 0 | 0\nMEM: 0.00MB | 0.00GB";
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		final now:Float = haxe.Timer.stamp() * 1000;

		times.push(now);

		while (times.length > 0 && times[0] < now - 1000)
			times.shift();

		deltaTimeout += elapsed * 1000;

		if (deltaTimeout < 50)
			return;

		currentFPS = times.length;
		if (currentFPS > FlxG.updateFramerate)
			currentFPS = FlxG.updateFramerate;

		if (currentFPS > highestFPS)
			highestFPS = currentFPS;

		if (currentFPS < lowestFPS)
			lowestFPS = currentFPS;

		currentMemoryMB = memoryBytes / 1024 / 1024;

		if (currentMemoryMB > maxMemoryMB)
			maxMemoryMB = currentMemoryMB;

		updateText();
		deltaTimeout = 0;
	}

	public function updateText():Void
	{
		var memMB:String = Std.string(FlxMath.roundDecimal(currentMemoryMB, 2));
		var maxGB:String = Std.string(FlxMath.roundDecimal(maxMemoryMB / 1024, 2));

		text =
			'FPS: ${currentFPS} | ${lowestFPS} | ${highestFPS}'
			+ '\nMEM: ${memMB}MB | ${maxGB}GB';

		color = 0xFFFFFFFF;

		if (currentFPS < FlxG.drawFramerate * 0.5)
			color = 0xFFFF0000;
	}

	inline function get_memoryBytes():Float
	{
		#if cpp
		return cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE);
		#else
		return System.totalMemory;
		#end
	}
}
