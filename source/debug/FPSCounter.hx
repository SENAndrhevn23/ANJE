package debug;

import flixel.FlxG;
import flixel.math.FlxMath;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.system.System;
import backend.Paths;

class FPSCounter extends TextField
{
	public var currentFPS(default, null):Int = 0;

	public var highestFPS:Int = 0;
	public var lowestFPS:Int = 9999;

	public var currentMemoryMB:Float = 0;
	public var maxMemoryMB:Float = 0;

	@:noCompletion private var times:Array<Float> = [];

	var deltaTimeout:Float = 0.0;

	public function new(x:Float = 10, y:Float = 10, color:Int = 0xFFFFFFFF)
	{
		super();

		this.x = x;
		this.y = y;

		selectable = false;
		mouseEnabled = false;
		multiline = true;
		autoSize = LEFT;

		background = true;
		backgroundColor = 0x88000000; // black transparent background

		defaultTextFormat = new TextFormat(Paths.font("fps.ttf"), 14, color);

		text = "FPS: 0 | 0 | 0\nMEM: 0MB | 0GB";
	}

	private override function __enterFrame(deltaTime:Float):Void
	{
		super.__enterFrame(deltaTime);

		final now:Float = haxe.Timer.stamp() * 1000;

		times.push(now);

		while(times.length > 0 && times[0] < now - 1000)
			times.shift();

		deltaTimeout += deltaTime;

		// updates every 50ms instead of every frame
		if(deltaTimeout < 50)
			return;

		currentFPS = times.length;

		if(currentFPS > FlxG.updateFramerate)
			currentFPS = FlxG.updateFramerate;

		if(currentFPS > highestFPS)
			highestFPS = currentFPS;

		if(currentFPS < lowestFPS)
			lowestFPS = currentFPS;

		// bytes -> MB
		currentMemoryMB = memoryBytes / 1024 / 1024;

		if(currentMemoryMB > maxMemoryMB)
			maxMemoryMB = currentMemoryMB;

		updateText();

		deltaTimeout = 0.0;
	}

	public dynamic function updateText():Void
	{
		var memMB:String = Std.string(FlxMath.roundDecimal(currentMemoryMB, 2));
		var maxGB:String = Std.string(FlxMath.roundDecimal(maxMemoryMB / 1024, 2));

		text =
			'FPS: ${currentFPS} | ${lowestFPS} | ${highestFPS}'
			+ '\nMEM: ${memMB}MB | ${maxGB}GB';

		textColor = 0xFFFFFFFF;

		if(currentFPS < FlxG.drawFramerate * 0.5)
			textColor = 0xFFFF0000;
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
