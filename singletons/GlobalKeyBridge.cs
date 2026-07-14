using Godot;
using SharpHook;
using SharpHook.Providers;
using SharpHook.Native;
using SharpHook.Logging;
using SharpHook.Data; // <-- Added this!

public partial class GlobalKeyBridge : Node
{
	[Signal]
	public delegate void GlobalKeyPressedEventHandler(int keyCode);

	[Signal]
	public delegate void GlobalKeyReleasedEventHandler(int keyCode);

	[Signal]
	public delegate void GlobalKeyTypedEventHandler(string text, int keyCode);

	readonly SimpleGlobalHook _hook = new();
	LogSource _logSource = LogSource.RegisterOrGet(minLevel: LogLevel.Debug); // LogLevel now works

	public override void _Ready()
	{
		InitializeSharpHookSignals();
		_hook.RunAsync();
	}

	void InitializeSharpHookSignals()
	{
		UioHookProvider.Instance.KeyTypedEnabled = true;

		_hook.KeyPressed += OnHookKeyPressed;
		_hook.KeyReleased += OnHookKeyReleased;
		_hook.KeyTyped += OnHookKeyTyped;

		//_logSource.MessageLogged += OnMessageLogged;
	}

	void OnMessageLogged(object? sender, LogEventArgs e)
	{
		//GD.Print($"{e.LfdogEntry.Level}: {e.LogEntry.FullText}");
	}

	void OnHookKeyPressed(object? sender, KeyboardHookEventArgs e)
	{
		CallDeferred(MethodName.DispatchKey, true, (int)e.Data.KeyCode);
	}

	void OnHookKeyReleased(object? sender, KeyboardHookEventArgs e)
	{
		CallDeferred(MethodName.DispatchKey, false, (int)e.Data.KeyCode);
	}

	void OnHookKeyTyped(object? sender, KeyboardHookEventArgs e)
	{
		// e.Data.KeyChar contains the typed character 
		CallDeferred(MethodName.DispatchTyped, e.Data.KeyChar.ToString(), (int)e.Data.KeyCode);
	}

	void DispatchKey(bool pressed, int keyCode)
	{
		if (pressed)
		{
			EmitSignal(SignalName.GlobalKeyPressed, keyCode);
		}
		else
		{
			EmitSignal(SignalName.GlobalKeyReleased, keyCode);
		}
		
		// Casting directly to KeyCode now works because of SharpHook.Data
		//GD.Print(f$"GLOBAL key {(pressed ? "down" : "up")}: {(KeyCode)keyCode}");
	}

	void DispatchTyped(string text, int keyCode)
	{
		EmitSignal(SignalName.GlobalKeyTyped, text, keyCode);
		
		//GD.Print($"GLOBAL typed: '{text}' from {(KeyCode)keyCode}");
	}

	public override void _ExitTree()
	{
		_hook.Dispose();
	}
}
