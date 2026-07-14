using Godot;
using System;
using System.Runtime.InteropServices;

public partial class DynamicPassthrough : Node
{
	// ==========================================
	// WINDOWS NATIVE API
	// ==========================================
	const int GWL_EXSTYLE = -20;
	const long WS_EX_TRANSPARENT = 0x00000020L;
	const long WS_EX_LAYERED = 0x00080000L;

	[DllImport("user32.dll", EntryPoint = "GetWindowLongPtr")]
	private static extern IntPtr GetWindowLongPtr64(IntPtr hWnd, int nIndex);
	[DllImport("user32.dll", EntryPoint = "GetWindowLong")]
	private static extern IntPtr GetWindowLong32(IntPtr hWnd, int nIndex);
	[DllImport("user32.dll", EntryPoint = "SetWindowLongPtr")]
	private static extern IntPtr SetWindowLongPtr64(IntPtr hWnd, int nIndex, IntPtr dwNewLong);
	[DllImport("user32.dll", EntryPoint = "SetWindowLong")]
	private static extern IntPtr SetWindowLong32(IntPtr hWnd, int nIndex, IntPtr dwNewLong);


	// ==========================================
	// MACOS NATIVE API (Objective-C)
	// ==========================================
	const string ObjCLibrary = "/usr/lib/libobjc.A.dylib";

	[DllImport(ObjCLibrary)]
	private static extern IntPtr sel_registerName(string str);

	// We pass a 'byte' instead of 'bool' to guarantee safe 1-byte transmission to Apple's BOOL
	[DllImport(ObjCLibrary, EntryPoint = "objc_msgSend")]
	private static extern void objc_msgSend_bool(IntPtr receiver, IntPtr selector, byte arg);


	// ==========================================
	// CLASS STATE
	// ==========================================
	private IntPtr _hwnd;
	private bool _isPassthrough = false;
	private bool _acceptAllInput = false;
	private string _osName;
	private int _windowId;

	private Godot.Collections.Array<Control> _clickableElements = new();

	public void add_control(Control control)
	{
		_clickableElements.Add(control);
	}

	public void set_accept_all_input(bool acceptAll)
	{
		_acceptAllInput = acceptAll;
		if (acceptAll)
			SetPassthrough(false);
		// When false, _Process will re-apply hover logic next frame.
	}

	public override void _Ready()
	{
		_osName = OS.GetName();
		_windowId = GetWindow().GetWindowId();


		// We only need the raw pointer for Windows and macOS
		if (_osName == "Windows" || _osName == "macOS")
		{
			_hwnd = (IntPtr)DisplayServer.WindowGetNativeHandle(DisplayServer.HandleType.WindowHandle, _windowId);
		}

		GD.Print($"Passthrough on hwnd={_hwnd} id={_windowId} path={GetPath()}");


		// Force initial state
		_isPassthrough = false; 
		SetPassthrough(true);
	}

	public override void _Process(double delta)
	{
		if (_acceptAllInput)
		{
			if (_isPassthrough)
				SetPassthrough(false);
			return;
		}
	
		Vector2I globalMousePos = DisplayServer.MouseGetPosition();
		Vector2I windowPos = GetWindow().Position;
		Vector2 localMousePos = globalMousePos - windowPos;

		bool isHoveringUI = false;

		foreach (var control in _clickableElements)
		{
			if (control != null && control.IsVisibleInTree() && control.GetGlobalRect().HasPoint(localMousePos))
			{
				isHoveringUI = true;
				break;
			}
		}

		if (isHoveringUI && _isPassthrough) SetPassthrough(false);
		else if (!isHoveringUI && !_isPassthrough) SetPassthrough(true);
	}

	private void SetPassthrough(bool enable)
	{
		// Safety guard so we don't spam the OS every frame
		if (_isPassthrough == enable) return;
		_isPassthrough = enable;

		switch (_osName)
		{
			case "Windows":
				SetPassthroughWindows(enable);
				break;
			case "macOS":
				SetPassthroughMac(enable);
				break;
			default:
				// Linux / FreeBSD / etc.
				SetPassthroughLinux(enable);
				break;
		}
	}

	// --- Windows Implementation ---
	private void SetPassthroughWindows(bool enable)
	{
		long exStyle = (long)GetWindowLong(_hwnd, GWL_EXSTYLE);
		
		if (enable) exStyle |= (WS_EX_TRANSPARENT | WS_EX_LAYERED);
		else exStyle &= ~WS_EX_TRANSPARENT;
		
		SetWindowLong(_hwnd, GWL_EXSTYLE, (IntPtr)exStyle);
	}

	// --- macOS Implementation ---
	private void SetPassthroughMac(bool enable)
	{
		// In Objective-C this executes: [window setIgnoresMouseEvents:YES/NO]
		IntPtr selector = sel_registerName("setIgnoresMouseEvents:");
		objc_msgSend_bool(_hwnd, selector, (byte)(enable ? 1 : 0));
	}

	// --- Linux Implementation ---
	private void SetPassthroughLinux(bool enable)
	{
		if (enable)
		{
			// Create a tiny 1x1 pixel region in the corner. 
			// Clicks outside this polygon will pass straight through the window!
			Vector2[] tinyRegion = new Vector2[] {
				new Vector2(0, 0),
				new Vector2(1, 0),
				new Vector2(1, 1),
				new Vector2(0, 1)
			};
			DisplayServer.WindowSetMousePassthrough(tinyRegion, _windowId);
		}
		else
		{
			// Passing an empty array resets the window, making the whole thing clickable again
			DisplayServer.WindowSetMousePassthrough(new Vector2[] { }, _windowId);
		}
	}

	// --- Win32 Wrappers ---
	private IntPtr GetWindowLong(IntPtr hWnd, int nIndex) => 
		IntPtr.Size == 8 ? GetWindowLongPtr64(hWnd, nIndex) : GetWindowLong32(hWnd, nIndex);

	private IntPtr SetWindowLong(IntPtr hWnd, int nIndex, IntPtr dwNewLong) => 
		IntPtr.Size == 8 ? SetWindowLongPtr64(hWnd, nIndex, dwNewLong) : SetWindowLong32(hWnd, nIndex, dwNewLong);
}
