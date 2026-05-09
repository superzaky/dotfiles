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
        , workspaces         = ["1","2","3","4","5","6","7","8","9"]
        , borderWidth        = 2
        , normalBorderColor = "#444b6a"
        , focusedBorderColor = "#ad8ee6"
        , startupHook        = spawnOnce "feh --bg-fill /home/zaky/Pictures/motorcycle_restaurant.jpg"
        , layoutHook         = avoidStruts $ layoutHook def -- This stops windows from covering the bar
        , logHook = dynamicLogWithPP xmobarPP
            { ppOutput          = hPutStrLn xmproc
            , ppCurrent         = xmobarColor "#f1c40f" "" . wrap "[" "]" . clickable
            , ppVisible         = xmobarColor "#ecf0f1" "" . wrap "(" ")" . clickable
            , ppHidden          = xmobarColor "#95a5a6" "" . clickable        -- Workspaces with windows
            , ppHiddenNoWindows = xmobarColor "#444b6a" "" . clickable        -- Empty workspaces (dimmer color)
            , ppUrgent          = xmobarColor "#e74c3c" "" . clickable
            , ppTitle           = xmobarColor "#2ecc71" "" . shorten 50
            , ppSep             = "   " 
            , ppOrder           = \(ws:l:t:ex) -> [ws,t]
            }
        } `additionalKeysP`
        [ ("M-p",        spawn "dmenu_run")
        , ("M-<Return>", spawn "alacritty")
        -- , ("M-i", spawn "emacs ~/leerplek/angular/hello-world/")
        , ("M-i", spawn "emacs")
        , ("<XF86AudioRaiseVolume>", spawn "amixer set Master 5%+")
        , ("<XF86AudioLowerVolume>", spawn "amixer set Master 5%-")
        , ("<XF86AudioMute>",        spawn "amixer set Master toggle")
        , ("<XF86MonBrightnessUp>",   spawn "brightnessctl set +5%")
        , ("<XF86MonBrightnessDown>", spawn "brightnessctl set 5%-")
        , ("M-S-r", spawn "xmonad --recompile && xmonad --restart")
        , ("M-<F7>", spawn "sh ~/.config/xmonad/scripts/dual_screen.sh")
        , ("M-<F8>", spawn "sh ~/.config/xmonad/scripts/monitor_only.sh")
        , ("M-S-k", spawn "sh ~/.config/xmonad/scripts/keys.sh")
        , ("M-<Backspace>", kill)
        ]
