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

	[DllImport(ObjCLibrary, EntryPoint = "objc_msgSend")]
	private static extern void objc_msgSend_bool(IntPtr receiver, IntPtr selector, byte arg);


	// ==========================================
	// CLASS STATE
	// ==========================================
	private IntPtr _hwnd;
	private bool _isPassthrough;
	private bool _acceptAllInput;
	private bool _forcePassthrough;
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
		{
			_forcePassthrough = false;
			SetPassthrough(false);
		}
		// When false, _Process re-applies hover / force logic next frame.
	}

	public void set_force_passthrough(bool force)
	{
		_forcePassthrough = force;
		if (force)
			SetPassthrough(true);
		else if (_acceptAllInput)
			SetPassthrough(false);
	}

	public override void _Ready()
	{
		_osName = OS.GetName();
		_ResolveNativeHandle();
		SetPassthrough(true);
	}

	public override void _Process(double _)
	{
		if (_hwnd == IntPtr.Zero && (_osName == "Windows" || _osName == "macOS"))
		{
			_ResolveNativeHandle();
			if (_hwnd != IntPtr.Zero)
				ApplyNativePassthrough(_isPassthrough);
		}

		if (_forcePassthrough)
		{
			if (!_isPassthrough)
				SetPassthrough(true);
			return;
		}

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

	private void _ResolveNativeHandle()
	{
		_windowId = GetWindow().GetWindowId();
		if (_osName == "Windows" || _osName == "macOS")
			_hwnd = (IntPtr)DisplayServer.WindowGetNativeHandle(DisplayServer.HandleType.WindowHandle, _windowId);
	}

	private void SetPassthrough(bool enable)
	{
		if (_isPassthrough == enable)
			return;
		_isPassthrough = enable;

		ApplyNativePassthrough(enable);
	}

	private void ApplyNativePassthrough(bool enable)
	{
		switch (_osName)
		{
			case "Windows":
				SetPassthroughWindows(enable);
				break;
			case "macOS":
				SetPassthroughMac(enable);
				break;
			default:
				SetPassthroughLinux(enable);
				break;
		}
	}

	private void SetPassthroughWindows(bool enable)
	{
		if (_hwnd == IntPtr.Zero)
			return;

		long exStyle = (long)GetWindowLong(_hwnd, GWL_EXSTYLE);
		if (enable)
			exStyle |= (WS_EX_TRANSPARENT | WS_EX_LAYERED);
		else
			exStyle &= ~WS_EX_TRANSPARENT;

		SetWindowLong(_hwnd, GWL_EXSTYLE, (IntPtr)exStyle);
	}

	private void SetPassthroughMac(bool enable)
	{
		if (_hwnd == IntPtr.Zero)
			return;

		IntPtr selector = sel_registerName("setIgnoresMouseEvents:");
		objc_msgSend_bool(_hwnd, selector, (byte)(enable ? 1 : 0));
	}

	private void SetPassthroughLinux(bool enable)
	{
		if (enable)
		{
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
			DisplayServer.WindowSetMousePassthrough(new Vector2[] { }, _windowId);
		}
	}

	private IntPtr GetWindowLong(IntPtr hWnd, int nIndex) =>
		IntPtr.Size == 8 ? GetWindowLongPtr64(hWnd, nIndex) : GetWindowLong32(hWnd, nIndex);

	private IntPtr SetWindowLong(IntPtr hWnd, int nIndex, IntPtr dwNewLong) =>
		IntPtr.Size == 8 ? SetWindowLongPtr64(hWnd, nIndex, dwNewLong) : SetWindowLong32(hWnd, nIndex, dwNewLong);
}
