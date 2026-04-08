import XMonad
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Util.Run
import XMonad.Util.SpawnOnce

myTerminal = "terminator"

myStartupHook = do
    spawnOnce "feh --bg-scale /usr/share/backgrounds/armbian/armbian03-Dre0x-Minum-dark-3840x2160.jpg"
    spawnOnce "xmobar"
    spawnOnce "nm-applet"
    spawnOnce "dunst"

main = xmonad $ docks def
    { terminal    = myTerminal
    , modMask     = mod4Mask
    , startupHook = myStartupHook
    , borderWidth = 2
    }
