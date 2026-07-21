using Godot;
using System.Collections.Generic;
using SharpHook;
using SharpHook.Providers;
using SharpHook.Native;
using SharpHook.Logging;
using SharpHook.Data;

public partial class GlobalKeyBridge : Node
{
	[Signal]
	//public delegate void GlobalKeyPressedEventHandler(int keyCode);
	public delegate void GlobalKeyPressedEventHandler();

	[Signal]
	public delegate void GlobalKeyCapturedEventHandler();

	//[Signal]
	//public delegate void GlobalKeyReleasedEventHandler(int keyCode);

	//[Signal]
	//public delegate void GlobalKeyTypedEventHandler(string text, int keyCode);

	[Signal]
	public delegate void ChordPressedEventHandler(string chordId);

	[Signal]
	public delegate void GlobalMousePressedEventHandler(int x, int y);

	readonly SimpleGlobalHook _hook = new();
	readonly Dictionary<string, Chord> _chords = new();
	readonly HashSet<KeyCode> _pressedKeys = new();
	readonly HashSet<KeyCode> _consumedChordKeys = new();
	int _inputCaptureDepth;
	bool _keyRepeatEnabled;
	int _lastSharpHookKeyCode;
	bool _lastKeyPressed;
	bool _lastCtrl;
	bool _lastAlt;
	bool _lastShift;
	bool _lastMeta;
	LogSource _logSource = LogSource.RegisterOrGet(minLevel: LogLevel.Debug); // LogLevel now works

	struct Chord
	{
		public KeyCode Key;
		public bool Ctrl;
		public bool Alt;
		public bool Shift;
		public bool Meta;
	}

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
		_hook.MousePressed += OnHookMousePressed;

		//_logSource.MessageLogged += OnMessageLogged;
	}

	void OnMessageLogged(object sender, LogEventArgs e)
	{
		//GD.Print($"{e.LfdogEntry.Level}: {e.LogEntry.FullText}");
	}

	public void register_chord(string chordId, int godotKey, bool ctrl, bool alt, bool shift, bool meta)
	{
		if (string.IsNullOrEmpty(chordId) || godotKey <= 0)
			return;
		
		_chords[chordId] = new Chord
		{
			Key = ToSharpHookKey((Key)godotKey),
			Ctrl = ctrl,
			Alt = alt,
			Shift = shift,
			Meta = meta,
		};
	}

	public void unregister_chord(string chordId)
	{
		_chords.Remove(chordId);
	}

	public void set_key_repeat_enabled(bool enabled)
	{
		_keyRepeatEnabled = enabled;
	}

	public void push_input_capture()
	{
		_inputCaptureDepth++;
	}

	public void pop_input_capture()
	{
		if (_inputCaptureDepth > 0)
			_inputCaptureDepth--;
	}

	public InputEventKey build_last_key_event()
	{
		if (_lastSharpHookKeyCode <= 0)
			return null;

		var godotKey = FromSharpHookKey((KeyCode)_lastSharpHookKeyCode);
		var ev = new InputEventKey
		{
			Pressed = _lastKeyPressed,
			Keycode = godotKey,
			PhysicalKeycode = godotKey,
			CtrlPressed = _lastCtrl,
			AltPressed = _lastAlt,
			ShiftPressed = _lastShift,
			MetaPressed = _lastMeta,
		};

		return ev;
	}

	void OnHookKeyPressed(object sender, KeyboardHookEventArgs e)
	{
		var mask = e.RawEvent.Mask;
		CallDeferred(
			MethodName.DispatchKey,
			true,
			(int)e.Data.KeyCode,
			(mask & EventMask.Ctrl) != 0,
			(mask & EventMask.Alt) != 0,
			(mask & EventMask.Shift) != 0,
			(mask & EventMask.Meta) != 0
		);
	}

	void OnHookKeyReleased(object sender, KeyboardHookEventArgs e)
	{
		var mask = e.RawEvent.Mask;
		CallDeferred(
			MethodName.DispatchKey,
			false,
			(int)e.Data.KeyCode,
			(mask & EventMask.Ctrl) != 0,
			(mask & EventMask.Alt) != 0,
			(mask & EventMask.Shift) != 0,
			(mask & EventMask.Meta) != 0
		);
	}

	void OnHookKeyTyped(object sender, KeyboardHookEventArgs e)
	{
		// e.Data.KeyChar contains the typed character
		CallDeferred(MethodName.DispatchTyped, e.Data.KeyChar.ToString(), (int)e.Data.KeyCode);
	}

	void OnHookMousePressed(object sender, MouseHookEventArgs e)
	{
		CallDeferred(MethodName.DispatchMousePressed, e.Data.X, e.Data.Y);
	}

	void DispatchMousePressed(int x, int y)
	{
		EmitSignal(SignalName.GlobalMousePressed, x, y);
	}

	void DispatchKey(bool pressed, int sharpHookKeyCode, bool ctrl, bool alt, bool shift, bool meta)
	{
		_lastKeyPressed = pressed;
		_lastSharpHookKeyCode = sharpHookKeyCode;
		_lastCtrl = ctrl;
		_lastAlt = alt;
		_lastShift = shift;
		_lastMeta = meta;

		var keyCode = (KeyCode)sharpHookKeyCode;

		if (pressed)
		{
			var firstPress = _pressedKeys.Add(keyCode);
			if (!firstPress && !_keyRepeatEnabled)
				return;

			if (firstPress
				&& !IsModifierKeyCode(sharpHookKeyCode)
				&& TryEmitMatchingChords(sharpHookKeyCode, ctrl, alt, shift, meta))
			{
				_consumedChordKeys.Add(keyCode);
				return;
			}
			if (_consumedChordKeys.Contains(keyCode))
				return;
		}
		else
		{
			_pressedKeys.Remove(keyCode);
			if (_consumedChordKeys.Remove(keyCode))
				return;
		}

		if (_inputCaptureDepth > 0)
			EmitSignal(SignalName.GlobalKeyCaptured);
		else if (pressed)
			EmitSignal(SignalName.GlobalKeyPressed);
	}

	bool TryEmitMatchingChords(int sharpHookKeyCode, bool ctrl, bool alt, bool shift, bool meta)
	{
		if (_chords.Count == 0)
			return false;

		var pressedKey = (KeyCode)sharpHookKeyCode;
		var matched = false;
		foreach (var pair in _chords)
		{
			var chord = pair.Value;
			if (chord.Key == pressedKey
				&& chord.Ctrl == ctrl
				&& chord.Alt == alt
				&& chord.Shift == shift
				&& chord.Meta == meta)
			{
				EmitSignal(SignalName.ChordPressed, pair.Key);
				matched = true;
			}
		}
		return matched;
	}

	void DispatchTyped(string text, int keyCode)
	{
		//enable when i want to again
		//EmitSignal(SignalName.GlobalKeyTyped, text, keyCode);

		//GD.Print($"GLOBAL typed: '{text}' from {(KeyCode)keyCode}");
	}

	static Key FromSharpHookKey(KeyCode keyCode)
	{
		return keyCode switch
		{
			KeyCode.VcEscape => Key.Escape,
			KeyCode.VcTab => Key.Tab,
			KeyCode.VcBackspace => Key.Backspace,
			KeyCode.VcEnter => Key.Enter,
			KeyCode.VcSpace => Key.Space,
			KeyCode.VcDelete => Key.Delete,
			KeyCode.VcInsert => Key.Insert,
			KeyCode.VcHome => Key.Home,
			KeyCode.VcEnd => Key.End,
			KeyCode.VcPageUp => Key.Pageup,
			KeyCode.VcPageDown => Key.Pagedown,
			KeyCode.VcUp => Key.Up,
			KeyCode.VcDown => Key.Down,
			KeyCode.VcLeft => Key.Left,
			KeyCode.VcRight => Key.Right,
			KeyCode.VcF1 => Key.F1,
			KeyCode.VcF2 => Key.F2,
			KeyCode.VcF3 => Key.F3,
			KeyCode.VcF4 => Key.F4,
			KeyCode.VcF5 => Key.F5,
			KeyCode.VcF6 => Key.F6,
			KeyCode.VcF7 => Key.F7,
			KeyCode.VcF8 => Key.F8,
			KeyCode.VcF9 => Key.F9,
			KeyCode.VcF10 => Key.F10,
			KeyCode.VcF11 => Key.F11,
			KeyCode.VcF12 => Key.F12,
			_ => (Key)(int)keyCode,
		};
	}

	static bool IsModifierKeyCode(int keyCode)
	{
		return (KeyCode)keyCode is
			KeyCode.VcLeftControl or KeyCode.VcRightControl or
			KeyCode.VcLeftAlt or KeyCode.VcRightAlt or
			KeyCode.VcLeftShift or KeyCode.VcRightShift or
			KeyCode.VcLeftMeta or KeyCode.VcRightMeta or
			KeyCode.VcCapsLock or KeyCode.VcNumLock or KeyCode.VcScrollLock;
	}

	static KeyCode ToSharpHookKey(Key key)
	{
		return key switch
		{
			Key.Escape => KeyCode.VcEscape,
			Key.Tab => KeyCode.VcTab,
			Key.Backspace => KeyCode.VcBackspace,
			Key.Enter => KeyCode.VcEnter,
			Key.Space => KeyCode.VcSpace,
			Key.Delete => KeyCode.VcDelete,
			Key.Insert => KeyCode.VcInsert,
			Key.Home => KeyCode.VcHome,
			Key.End => KeyCode.VcEnd,
			Key.Pageup => KeyCode.VcPageUp,
			Key.Pagedown => KeyCode.VcPageDown,
			Key.Up => KeyCode.VcUp,
			Key.Down => KeyCode.VcDown,
			Key.Left => KeyCode.VcLeft,
			Key.Right => KeyCode.VcRight,
			Key.F1 => KeyCode.VcF1,
			Key.F2 => KeyCode.VcF2,
			Key.F3 => KeyCode.VcF3,
			Key.F4 => KeyCode.VcF4,
			Key.F5 => KeyCode.VcF5,
			Key.F6 => KeyCode.VcF6,
			Key.F7 => KeyCode.VcF7,
			Key.F8 => KeyCode.VcF8,
			Key.F9 => KeyCode.VcF9,
			Key.F10 => KeyCode.VcF10,
			Key.F11 => KeyCode.VcF11,
			Key.F12 => KeyCode.VcF12,
			_ => (KeyCode)(int)key,
		};
	}

	public override void _ExitTree()
	{
		_hook.Dispose();
	}
}
