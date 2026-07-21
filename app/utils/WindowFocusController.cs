using Godot;
using System;
using System.Runtime.InteropServices;

public partial class WindowFocusController : Node
{
	private const int SwRestore = 9;
	private const int SwShow = 5;

	private Window _targetWindow;
	private IntPtr _previousForegroundHandle = IntPtr.Zero;

	[DllImport("user32.dll")]
	private static extern bool SetForegroundWindow(IntPtr hWnd);
	[DllImport("user32.dll")]
	private static extern bool BringWindowToTop(IntPtr hWnd);
	[DllImport("user32.dll")]
	private static extern IntPtr SetFocus(IntPtr hWnd);
	[DllImport("user32.dll")]
	private static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
	[DllImport("user32.dll")]
	private static extern IntPtr GetForegroundWindow();
	[DllImport("user32.dll")]
	private static extern bool IsWindow(IntPtr hWnd);
	[DllImport("user32.dll")]
	private static extern uint GetWindowThreadProcessId(IntPtr hWnd, IntPtr processId);
	[DllImport("kernel32.dll")]
	private static extern uint GetCurrentThreadId();
	[DllImport("user32.dll")]
	private static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);
	[DllImport("user32.dll")]
	private static extern bool AllowSetForegroundWindow(uint dwProcessId);
	[DllImport("kernel32.dll")]
	private static extern uint GetCurrentProcessId();

	public void initialize(Window window)
	{
		_targetWindow = window;
	}

	public void capture_focus()
	{
		if (!HasValidTarget())
			return;
		if (OS.GetName() == "Windows")
			CaptureFocusWindows();
		_targetWindow.GrabFocus();
	}

	public void release_focus()
	{
		if (OS.GetName() == "Windows")
			ReleaseFocusWindows();
	}

	private void CaptureFocusWindows()
	{
		IntPtr handle = ResolveNativeHandle();
		if (handle == IntPtr.Zero)
			return;

		AllowSetForegroundWindow(GetCurrentProcessId());

		IntPtr foreground = GetForegroundWindow();
		if (foreground != IntPtr.Zero && foreground != handle)
			_previousForegroundHandle = foreground;

		uint appThread = GetCurrentThreadId();
		uint foregroundThread = GetWindowThreadProcessId(foreground, IntPtr.Zero);
		bool attached = AttachToCurrentThread(foregroundThread, appThread);
		try
		{
			ShowWindow(handle, SwShow);
			ShowWindow(handle, SwRestore);
			BringWindowToTop(handle);
			SetForegroundWindow(handle);
			SetFocus(handle);
		}
		finally
		{
			DetachFromCurrentThread(foregroundThread, appThread, attached);
		}
	}

	private void ReleaseFocusWindows()
	{
		AllowSetForegroundWindow(GetCurrentProcessId());

		IntPtr previous = _previousForegroundHandle;
		_previousForegroundHandle = IntPtr.Zero;
		if (previous == IntPtr.Zero || !IsWindow(previous))
			return;

		IntPtr foreground = GetForegroundWindow();
		uint foregroundThread = GetWindowThreadProcessId(foreground, IntPtr.Zero);
		uint previousThread = GetWindowThreadProcessId(previous, IntPtr.Zero);
		uint appThread = GetCurrentThreadId();
		bool attachedToForeground = AttachToCurrentThread(foregroundThread, appThread);
		bool attachedToPrevious = previousThread != foregroundThread
			&& AttachToCurrentThread(previousThread, appThread);
		try
		{
			SetForegroundWindow(previous);
		}
		finally
		{
			DetachFromCurrentThread(previousThread, appThread, attachedToPrevious);
			DetachFromCurrentThread(foregroundThread, appThread, attachedToForeground);
		}
	}

	private IntPtr ResolveNativeHandle()
	{
		if (!HasValidTarget())
			return IntPtr.Zero;
		return (IntPtr)DisplayServer.WindowGetNativeHandle(
			DisplayServer.HandleType.WindowHandle,
			_targetWindow.GetWindowId()
		);
	}

	private bool HasValidTarget() =>
		_targetWindow != null && GodotObject.IsInstanceValid(_targetWindow);

	private static bool AttachToCurrentThread(uint threadId, uint currentThreadId) =>
		threadId != 0
		&& threadId != currentThreadId
		&& AttachThreadInput(threadId, currentThreadId, true);

	private static void DetachFromCurrentThread(uint threadId, uint currentThreadId, bool attached)
	{
		if (attached)
			AttachThreadInput(threadId, currentThreadId, false);
	}
}
