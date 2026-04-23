import XMonad
import XMonad.Util.EZConfig (additionalKeysP)
import XMonad.Hooks.EwmhDesktops (ewmh)

main :: IO ()
main = xmonad $ ewmh def
    { terminal           = "alacritty"
    , modMask            = mod4Mask
    , borderWidth        = 2
    } `additionalKeysP`
    [ ("M-S-w", kill)
    , ("M-p",   spawn "dmenu_run")
    ]