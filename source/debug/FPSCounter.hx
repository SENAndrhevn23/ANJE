package debug;

import flixel.FlxG;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFieldAutoSize;
import openfl.system.System;
import backend.Paths;

#if cpp
import cpp.vm.Gc;
#end

/**
	The FPS class provides a monitor showing:
	FPS: current | lowest | highest
	MEM: current | max
**/
class FPSCounter extends TextField
{
	public var currentFPS(default, null):Int;
	public var lowestFPS(default, null):Int;
	public var highestFPS(default, null):Int;

	/** Current memory usage in megabytes. */
	public var memoryMegas(get, never):Float;
	/** Peak memory usage in megabytes. */
	public var memoryPeakMegas(default, null):Float;

	@:noCompletion private var times:Array<Float>;
	@:noCompletion private var deltaTimeout:Float = 0.0;
	@:noCompletion private var fpsFontSize:Int;

	public function new(x:Float = 10, y:Float = 10, color:Int = 0xFFFFFFFF, fpsFontSize:Int = 14)
	{
		super();

		this.x = x;
		this.y = y;
		this.fpsFontSize = fpsFontSize;

		currentFPS = 0;
		lowestFPS = 0;
		highestFPS = 0;
		memoryPeakMegas = 0;

		selectable = false;
		mouseEnabled = false;
		multiline = true;
		wordWrap = false;
		autoSize = TextFieldAutoSize.LEFT;

		background = true;
		// Semi-transparent black background.
		// If your OpenFL target ignores alpha here, tell me and I’ll switch this to a sprite-backed version.
		backgroundColor = 0x80000000;

		defaultTextFormat = new TextFormat(Paths.font("fps.ttf"), fpsFontSize, color);
		textColor = color;

		text = "FPS: 0 | 0 | 0\nMEM: 0MB | 0.00GB";
		times = [];
	}

	private override function __enterFrame(deltaTime:Float):Void
	{
		final now:Float = haxe.Timer.stamp() * 1000;
		times.push(now);
		while (times.length > 0 && times[0] < now - 1000)
			times.shift();

		// Update text at a slower rate so the overlay isn't rebuilt every frame.
		if (deltaTimeout < 50)
		{
			deltaTimeout += deltaTime;
			return;
		}

		currentFPS = Std.int(Math.min(times.length, FlxG.updateFramerate));
		if (lowestFPS == 0 || currentFPS < lowestFPS)
			lowestFPS = currentFPS;
		if (currentFPS > highestFPS)
			highestFPS = currentFPS;

		final currentMem:Float = memoryMegas;
		if (currentMem > memoryPeakMegas)
			memoryPeakMegas = currentMem;

		updateText();
		deltaTimeout = 0.0;
	}

	public dynamic function updateText():Void
	{
		text = 'FPS: ${currentFPS} | ${lowestFPS} | ${highestFPS}'
			+ '\nMEM: ${formatMegabytes(memoryMegas)} | ${formatMemoryPeak(memoryPeakMegas)}';

		textColor = 0xFFFFFFFF;
		if (currentFPS < FlxG.drawFramerate * 0.5)
			textColor = 0xFFFF0000;
	}

	inline function formatMegabytes(value:Float):String
	{
		return '${formatNumber(Std.int(Math.round(value)))}MB';
	}

	inline function formatMemoryPeak(value:Float):String
	{
		if (value >= 1024)
			return '${formatDecimal(value / 1024)}GB';
		return '${formatNumber(Std.int(Math.round(value)))}MB';
	}

	inline function formatNumber(value:Int):String
	{
		return formatWithCommas(value);
	}

	inline function formatDecimal(value:Float):String
	{
		var out = Std.string(Math.ffloor(value * 100) / 100);
		if (out.indexOf(".") == -1) out += ".00";
		else {
			var parts = out.split(".");
			var dec = parts[1];
			if (dec.length == 1) out += "0";
		}
		return out;
	}

	inline function formatWithCommas(value:Int):String
	{
		var s = Std.string(value);
		var negative = false;
		if (StringTools.startsWith(s, "-"))
		{
			negative = true;
			s = s.substr(1);
		}

		var out = "";
		var count = 0;
		for (i in 0...s.length)
		{
			var idx = s.length - 1 - i;
			out = s.charAt(idx) + out;
			count++;
			if (count % 3 == 0 && idx > 0)
				out = "," + out;
		}

		return negative ? "-" + out : out;
	}

	inline function get_memoryMegas():Float
	{
		#if cpp
		return Gc.memInfo64(Gc.MEM_INFO_USAGE);
		#else
		return System.totalMemory / (1024 * 1024);
		#end
	}
}
