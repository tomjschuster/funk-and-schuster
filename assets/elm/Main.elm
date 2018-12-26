module Main exposing (main)

import Browser
import Html
import Http
import Json.Decode as JD
import Task exposing (Task)
import Time
import Url exposing (Url)


main : Program () Model ()
main =
    Browser.application
        { init = \() _ _ -> ( initialModel, Cmd.none )
        , view = \model -> { title = "hello elm", body = [ Html.text "hi there?" ] }
        , update = \() model -> ( initialModel, Cmd.none )
        , subscriptions = \model -> Sub.none
        , onUrlRequest = \_ -> ()
        , onUrlChange = \_ -> ()
        }


type alias Model =
    { artists : List Artist, works : List Work, media : List Media }


initialModel : Model
initialModel =
    { artists = [], works = [], media = [] }



-- Artist


type alias Artist =
    { id : ArtistId
    , firstName : String
    , lastName : String
    , dob : Time.Posix
    }


type ArtistId
    = ArtistId Int


artistDecoder : JD.Decoder Artist
artistDecoder =
    JD.map4 Artist
        (JD.field "id" artistIdDecoder)
        (JD.field "firstName" JD.string)
        (JD.field "lastName" JD.string)
        (JD.field "dob" (JD.map Time.millisToPosix JD.int))


artistIdDecoder : JD.Decoder ArtistId
artistIdDecoder =
    JD.map ArtistId JD.int



-- Work


type alias Work =
    { id : WorkId
    , artistId : ArtistId
    , title : String
    , date : Time.Posix
    , medium : Medium
    , dimensions : Dimensions
    }


type WorkId
    = WorkId Int


type Medium
    = OtherMedium String


type Dimensions
    = CustomDimensoins String


workDecoder : JD.Decoder Work
workDecoder =
    JD.map6 Work
        (JD.field "id" workIdDecoder)
        (JD.field "artistId" artistIdDecoder)
        (JD.field "title" JD.string)
        (JD.field "date" (JD.map Time.millisToPosix JD.int))
        (JD.field "medium" mediumDecoder)
        (JD.field "dimensions" dimensionsDecoder)


workIdDecoder : JD.Decoder WorkId
workIdDecoder =
    JD.map WorkId JD.int


mediumDecoder : JD.Decoder Medium
mediumDecoder =
    JD.map OtherMedium JD.string


dimensionsDecoder : JD.Decoder Dimensions
dimensionsDecoder =
    JD.map CustomDimensoins JD.string



-- Media


type alias Media =
    { id : MediaId
    , owner : MediaOwner
    , title : String
    , caption : String
    , src : String
    , contentType : ContentType
    }


type MediaId
    = MediaId Int


type MediaOwner
    = ArtistOwner ArtistId
    | WorkOwner WorkId
    | NoOwner


type ContentType
    = OtherContentType String


mediaDecoder : JD.Decoder Media
mediaDecoder =
    JD.map6 Media
        (JD.field "id" mediaIdDecoder)
        mediaOwnerDecoder
        (JD.field "title" JD.string)
        (JD.field "caption" JD.string)
        (JD.field "src" JD.string)
        (JD.field "contentType" contentTypeDecoder)


mediaIdDecoder : JD.Decoder MediaId
mediaIdDecoder =
    JD.map MediaId JD.int


mediaOwnerDecoder : JD.Decoder MediaOwner
mediaOwnerDecoder =
    JD.oneOf
        [ JD.field "artistId" (JD.map ArtistOwner artistIdDecoder)
        , JD.field "workId" (JD.map WorkOwner workIdDecoder)
        , JD.succeed NoOwner
        ]


contentTypeDecoder : JD.Decoder ContentType
contentTypeDecoder =
    JD.map OtherContentType JD.string



-- HTTP


getTask : JD.Decoder a -> String -> Task Http.Error a
getTask decoder url =
    Http.task
        { method = "GET"
        , headers = []
        , url = url
        , body = Http.emptyBody
        , resolver = jsonResolver decoder
        , timeout = Nothing
        }


jsonResolver : JD.Decoder a -> Http.Resolver Http.Error a
jsonResolver decoder =
    decoder
        |> handleJsonResponse
        |> Http.stringResolver


handleJsonResponse : JD.Decoder a -> Http.Response String -> Result Http.Error a
handleJsonResponse decoder response =
    case response of
        Http.BadUrl_ url ->
            Err (Http.BadUrl url)

        Http.Timeout_ ->
            Err Http.Timeout

        Http.NetworkError_ ->
            Err Http.NetworkError

        Http.BadStatus_ metadata body ->
            Err (Http.BadStatus metadata.statusCode)

        Http.GoodStatus_ metadata body ->
            case JD.decodeString decoder body of
                Ok value ->
                    Ok value

                Err err ->
                    Err (Http.BadBody (JD.errorToString err))
