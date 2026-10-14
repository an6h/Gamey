# 🚀 Gamey

**A lightweight Windows game booster built with Batch scripting.**

Gamey automatically detects when a configured game starts and applies selected Windows tweaks to reduce background activity while you play.

When the game closes, Gamey restores the changes it made wherever possible. No installer or separate launcher is required.

## ✨ Features

- 🎮 **Automatic game detection** – Detects configured games running on your PC.
- ⚡ **High-performance power plan** – Switches Windows to the High performance power plan.
- 🧹 **Background process cleanup** – Closes selected applications while gaming.
- 🖥️ **Windows Explorer control** – Stops Explorer to reduce background activity and restarts it afterward.
- ⏫ **Game priority** – Sets the game's process priority to Above Normal.
- 🧠 **RAM cleanup** – Uses RAMMap to clear selected memory lists.
- 🔄 **Automatic restoration** – Reverts enabled tweaks when the game closes or you press `Enter`.

> **Note:** Gamey applies system tweaks, but performance improvements depend on your PC and game. It does not guarantee higher FPS.

## ⚙️ How It Works

Gamey is a Windows batch script (`gamey.bat`) that runs in the background and checks whether a configured game is running.

Its workflow is simple:

1. Start `gamey.bat`.
2. Gamey requests administrator permission.
3. It checks for configured games every few seconds.
4. When a game is detected, it applies the enabled tweaks.
5. It waits until the game closes or you press `Enter`.
6. It restores the changes associated with the enabled tweaks.
7. It continues watching for another game.

## 📋 Requirements

- Windows
- Administrator permission
- The `gamey.bat` file
- [RAMMap](https://learn.microsoft.com/en-us/sysinternals/downloads/rammap) for RAM cleanup (optional)

RAMMap is optional. If it is missing from the configured path, Gamey skips RAM cleanup and continues.

## 🚀 Getting Started

1. Download or clone this repository.
2. Open `gamey.bat` in a text editor such as Notepad.
3. Configure your games and preferred tweaks using the instructions below.
4. Save the file.
5. Run `gamey.bat` and approve the administrator prompt.
6. Leave Gamey running and start one of your configured games.

When Gamey detects a game, it applies the enabled tweaks automatically.

**To stop the current boost:** Close the detected game or switch to the Gamey console and press `Enter`.

## 🎮 Configuration

All the main settings are near the top of `gamey.bat`, inside the `:Config` section.

### 1. Add or remove games

Find this line:

```bat
set "GAMELIST=eldenring.exe cs2.exe RDR2.exe Discovery-d.exe VALORANT-Win64-Shipping.exe PioneerGame.exe deadlock.exe"
```

Replace the example names with the executable names of the games you want Gamey to detect.

For example:

```bat
set "GAMELIST=game1.exe game2.exe game3.exe"
```

To find a game's executable name:

1. Open Task Manager while the game is running.
2. Go to the **Details** tab.
3. Find the game's process name.

Use the executable name, including `.exe`.

### 2. Choose which background processes to close

Find:

```bat
set "PROCESSLIST=CrossDeviceResume.exe MicrosoftEdgeUpdate.exe Spotify.exe CrossDeviceService.exe"
```

Add or remove executable names as needed.

For example:

```bat
set "PROCESSLIST=Spotify.exe Discord.exe"
```

Gamey forcefully closes the listed processes when the boost begins.

**Important:** These applications are not automatically reopened when the boost ends. Only include applications you are comfortable closing.

### 3. Configure the Windows power plan

Find these settings:

```bat
set "PLAN_BALANCED=381b4222-f694-41f0-9685-ff5bb260df2e"
set "PLAN_HIGH=8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
```

- `PLAN_BALANCED` is the power plan Gamey switches back to.
- `PLAN_HIGH` is the power plan Gamey activates during gaming.

The default values are Windows power-plan identifiers. Change them only if you know which plan identifiers you want to use.

Gamey restores the configured Balanced plan, not necessarily whichever power plan was active before it started.

### 4. Change the game detection interval

Find:

```bat
set "POLL_SECONDS=5"
```

This controls how often Gamey checks for a running game.

For example, to check every 3 seconds:

```bat
set "POLL_SECONDS=3"
```

A smaller value means more frequent checks.

### 5. Configure RAMMap

Find:

```bat
set "RAMMAP=C:\Tools\Sysinternals\RAMMap64.exe"
```

Change the path to match where `RAMMap64.exe` is installed on your computer.

For example:

```bat
set "RAMMAP=D:\Tools\RAMMap64.exe"
```

You can leave the path as it is if RAMMap is already located there. If RAMMap is unavailable, Gamey skips this step.

### 6. Configure RAM cleanup options

Find:

```bat
set "RAMFLAGS=-Ew -Es -Em -Et -E0"
```

These flags tell RAMMap which memory lists to clear.

Leave them unchanged unless you understand what each RAMMap option does.

### 7. Configure Windows services

Gamey includes optional support for stopping selected Windows services.

Find:

```bat
set "SERVICELIST="
```

Add the service names you want to manage:

```bat
set "SERVICELIST=ExampleService1 ExampleService2"
```

Use the actual **service names**, not their display names.

The service feature is disabled by default. To enable it, you must also uncomment `call :Services` in the `:Boost` section, as explained below.

Be careful when changing Windows services. Stopping an essential service may affect Windows or other applications.

## 💬 Enable or Disable Features Using Comments

You do not need to delete code to disable a feature. You can comment out its function call.

In Windows Batch, `::` at the beginning of a line makes that line a comment, so the command is not executed.

### Example: Disable a feature

Enabled:

```bat
call :PowerPlan
```

Disabled:

```bat
:: call :PowerPlan
```

Remove the leading `::` to enable it again.

### Available feature switches

Find the `:Boost` section in `gamey.bat`:

```bat
:Boost
call :PowerPlan
call :Processes
:: call :Services
:: call :Explorer
call :GamePriority
goto :eof
```

Use the following reference to control the features:

| Feature | Enable | Disable |
| --- | --- | --- |
| High-performance power plan | `call :PowerPlan` | `:: call :PowerPlan` |
| Close background processes | `call :Processes` | `:: call :Processes` |
| Stop Windows services | `call :Services` | `:: call :Services` |
| Stop Windows Explorer | `call :Explorer` | `:: call :Explorer` |
| Increase game priority | `call :GamePriority` | `:: call :GamePriority` |

**RAM cleanup is controlled separately.** Find this line in the game-detection section:

```bat
call :ClearRam
```

To disable RAM cleanup:

```bat
::call :ClearRam
```

To enable it again, remove the `::`.

### Example: A lighter gaming setup

If you only want the power plan and game priority tweaks, your `:Boost` section can look like this:

```bat
:Boost
call :PowerPlan
:: call :Processes
:: call :Services
:: call :Explorer
call :GamePriority
goto :eof
```

To disable RAM cleanup as well, comment out `call :ClearRam` in the separate game-detection section.

**Important:** Comment out only the function calls. Do not comment out the function definitions, undo functions, or helper functions. Gamey needs those functions to perform and restore its changes correctly.

## 🔄 What Gets Restored?

Gamey keeps track of the enabled tweaks that need to be undone.

- **Power plan:** Switches back to the configured Balanced plan.
- **Windows services:** Restarts services that were running before Gamey stopped them.
- **Windows Explorer:** Attempts to restore Explorer and the desktop.
- **Game priority:** Returns the game's priority to Normal.

Background processes closed by Gamey are not automatically reopened. RAM cleanup is also not reversed because clearing memory lists is not a reversible operation.

Gamey writes recovery information to `gamey.state` so it can attempt to restore recorded changes if a previous session did not finish normally.

## ⚠️ Important Notes

- Run Gamey with administrator permission for its system-level actions.
- Save your work before gaming if you enable process cleanup.
- Disabling Explorer temporarily removes the Windows taskbar and desktop. Use `Alt + Tab` to switch windows while it is stopped.
- Some tweaks may have little or no measurable effect on performance.
- Review every setting before enabling optional features, especially process cleanup and Windows service management.

## 📁 Project Structure

```text
Gamey/
├── gamey.bat       # Main script and configuration
├── gamey.state     # Temporary recovery information
└── README.md       # Project documentation
```

`gamey.state` is created when recovery information needs to be saved and is normally removed after restoration.

## 🛠️ Troubleshooting

**Gamey does not detect my game**

- Check the executable name in `GAMELIST`.
- Make sure the game is running.
- Confirm that you saved your changes.

**RAM cleanup is skipped**

- Check that `RAMMAP` points to the correct `RAMMap64.exe` file.
- Remember that RAMMap is optional.

**The desktop or taskbar does not return**

- Give Gamey a moment to finish its restoration.
- If Explorer does not return, it may need to be restarted manually through Task Manager.

**A closed application does not reopen**

This is expected. Gamey terminates configured processes but does not relaunch them.

## 📄 License

Check the repository for licensing information before redistributing or modifying the project.

---

Made for simpler gaming sessions with fewer unnecessary background tasks. 🎮
