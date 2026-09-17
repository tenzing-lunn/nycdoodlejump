# NYC Doodle Jump

An endless vertical platformer for iOS, built in Swift and SpriteKit. Climb a New York skyline by bouncing up procedurally placed platforms; miss one and you fall out of the world.

## Architecture

The project separates scene code from the systems that feed it, rather than piling everything into `GameScene`:

| Folder | Role |
|---|---|
| `Entities/` | The player, platforms, coins and other things that exist in the world |
| `Scenes/` | SpriteKit scenes and their lifecycle |
| `Systems/` | The managers that drive the game: platforms, background, coins, audio, UI overlays, scene routing |
| `Utils/` | Shared helpers |

Notable systems:

**`PlatformManager`** — spawns platforms ahead of the climbing camera and retires them once they fall below it. An endless scroller cannot keep allocating nodes forever, so the interesting constraint is keeping the live node count bounded no matter how high the player gets.

**`BackgroundManager`** — parallax skyline layers that scroll at different rates to fake depth from flat art.

**`PixelArtFactory`** — generates sprites in code instead of shipping image assets. Everything the player sees is drawn from shapes at runtime.

**`SceneRouter` + the overlays** (`StartOverlay`, `PauseOverlay`, `CountdownOverlay`, `GameOverOverlay`, `SettingsOverlay`, `StoreOverlay`) — game state as an explicit routing layer rather than a pile of booleans inside the scene.

**`CoinManager` + `SkinCatalog`** — a coin economy backing unlockable skins.

`DebugHUD` draws live state on screen during development.

## Run it

Open `nycdoodlejump.xcodeproj` in Xcode and run on the iOS simulator or a device.

## Status

A finished, playable build, not a shipped App Store app. Written to learn SpriteKit's scene graph, physics and update loop from the ground up.
