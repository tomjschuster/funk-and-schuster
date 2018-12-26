module Main exposing (main)

import Browser
import Html


main : Program () () ()
main =
    Browser.application
        { init = \() _ _ -> ( (), Cmd.none )
        , view = \() -> { title = "hello elm", body = [ Html.text "hi there" ] }
        , update = \() () -> ( (), Cmd.none )
        , subscriptions = \() -> Sub.none
        , onUrlRequest = \_ -> ()
        , onUrlChange = \_ -> ()
        }
