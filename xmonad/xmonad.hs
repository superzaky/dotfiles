import XMonad
import XMonad.Util.EZConfig (additionalKeysP)
import XMonad.Hooks.EwmhDesktops (ewmh)
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks (docks, avoidStruts)
import XMonad.Util.Run (spawnPipe)
import System.IO (hPutStrLn)

main :: IO ()
main = do
    -- This launches xmobar using the system path
    xmproc <- spawnPipe "xmobar ~/.config/xmobar/.xmobarrc" 
    xmonad $ docks $ ewmh def
        { terminal           = "alacritty"
        , modMask            = mod4Mask -- rebind mod to super key
        , borderWidth        = 2
        , layoutHook         = avoidStruts $ layoutHook def -- This stops windows from covering the bar
        , logHook = dynamicLogWithPP xmobarPP
            { ppOutput = hPutStrLn xmproc
            , ppTitle = xmobarColor "#2ecc71" "" . xmobarRaw . shorten 50
            }
        } `additionalKeysP`
        [ ("M-S-w",      kill)
        , ("M-p",        spawn "dmenu_run")
        , ("M-<Return>", spawn "alacritty")
        , ("<XF86AudioRaiseVolume>", spawn "amixer set Master 5%+")
        , ("<XF86AudioLowerVolume>", spawn "amixer set Master 5%-")
        , ("<XF86AudioMute>",        spawn "amixer set Master toggle")
        ]