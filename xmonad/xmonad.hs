import XMonad
import XMonad.Util.EZConfig (additionalKeysP)
import XMonad.Hooks.EwmhDesktops (ewmh)
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks (docks, avoidStruts)
import XMonad.Util.Run (spawnPipe)
import System.IO (hPutStrLn)
import XMonad.Util.SpawnOnce (spawnOnce)

-- Helper function to make workspaces clickable
clickable :: String -> String
clickable ws = "<action=`xdotool key super+" ++ ws ++ "`>" ++ ws ++ "</action>"

main :: IO ()
main = do
    -- This launches xmobar using the system path
    xmproc <- spawnPipe "xmobar ~/.config/xmobar/.xmobarrc" 
    xmonad $ docks $ ewmh def
        { terminal           = "alacritty"
        , modMask            = mod4Mask -- rebind mod to super key
        , borderWidth        = 2
        , normalBorderColor = "#444b6a"
        , focusedBorderColor = "#ad8ee6"
        , startupHook        = spawnOnce "feh --bg-fill /home/zaky/Pictures/motorcycle_restaurant.jpg"
        , layoutHook         = avoidStruts $ layoutHook def -- This stops windows from covering the bar
        , logHook = dynamicLogWithPP xmobarPP
            { ppOutput = hPutStrLn xmproc
            , ppTitle = xmobarColor "#2ecc71" "" . xmobarRaw . shorten 50
            , ppCurrent = xmobarColor "#f1c40f" "" . wrap "[" "]" . clickable
            , ppVisible = wrap "(" ")" . clickable
            , ppHidden  = clickable
            }
        } `additionalKeysP`
        [ ("M-p",        spawn "dmenu_run")
        , ("M-<Return>", spawn "alacritty")
        -- , ("M-i", spawn "emacs ~/leerplek/angular/hello-world/")
        , ("M-i", spawn "emacs")
        , ("<XF86AudioRaiseVolume>", spawn "amixer set Master 5%+")
        , ("<XF86AudioLowerVolume>", spawn "amixer set Master 5%-")
        , ("<XF86AudioMute>",        spawn "amixer set Master toggle")
        ]
