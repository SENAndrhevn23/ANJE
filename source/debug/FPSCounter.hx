package debug;

import flixel.FlxG;
import flixel.math.FlxMath;
import openfl.display.Sprite;
import openfl.display.Shape;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import openfl.system.System;
import backend.Paths;

class FPSCounter extends Sprite
{
	public var currentFPS(default, null):Int = 0;
	public var highestFPS:Int = 0;
	public var lowestFPS:Int = 9999;

	public var currentMemoryMB:Float = 0;
	public var maxMemoryMB:Float = 0;

	public var memoryBytes(get, never):Float;

	@:noCompletion private var times:Array<Float> = [];
	private var deltaTimeout:Float = 0.0;

	private var bg:Shape;
	private var label:TextField;
	private var padding:Int = 4;

	public function new(x:Float = 10, y:Float = 10, color:Int = 0xFFFFFFFF)
	{
		super();

		this.x = x;
		this.y = y;

		mouseEnabled = false;
		mouseChildren = false;

		bg = new Shape();
		addChild(bg);

		label = new TextField();
		label.selectable = false;
		label.mouseEnabled = false;
		label.multiline = true;
		label.autoSize = TextFieldAutoSize.LEFT;
		label.defaultTextFormat = new TextFormat(Paths.font("fps.ttf"), 14, color);
		label.textColor = color;
		addChild(label);

		label.text = "FPS: 0 | 0 | 0\nMEM: 0.00MB | 0.00GB";
		drawBackground();
	}

	private override function __enterFrame(deltaTime:Int):Void
	{
		super.__enterFrame(deltaTime);

		final now:Float = haxe.Timer.stamp() * 1000;
		times.push(now);

		while (times.length > 0 && times[0] < now - 1000)
			times.shift();

		deltaTimeout += deltaTime;

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

	public dynamic function updateText():Void
	{
		var memMB:String = Std.string(FlxMath.roundDecimal(currentMemoryMB, 2));
		var maxGB:String = Std.string(FlxMath.roundDecimal(maxMemoryMB / 1024, 2));

		label.text =
			'FPS: ${currentFPS} | ${lowestFPS} | ${highestFPS}'
			+ '\nMEM: ${memMB}MB | ${maxGB}GB';

		label.textColor = 0xFFFFFFFF;

		if (currentFPS < FlxG.drawFramerate * 0.5)
			label.textColor = 0xFFFF0000;

		drawBackground();
	}

	private function drawBackground():Void
	{
		bg.graphics.clear();
		bg.graphics.beginFill(0x000000, 0.5);
		bg.graphics.drawRect(0, 0, label.textWidth + padding * 2 + 4, label.textHeight + padding * 2 + 4);
		bg.graphics.endFill();

		label.x = padding;
		label.y = padding - 2;
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
