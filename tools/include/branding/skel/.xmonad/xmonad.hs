import XMonad

main = xmonad def
    { terminal    = "terminator"
    , modMask     = mod4Mask
    , borderWidth = 2
    }
