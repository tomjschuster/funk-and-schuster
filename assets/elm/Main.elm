module Main exposing (main)

import Browser
import Browser.Navigation
import Html
import Http
import Json.Decode as JD
import Task exposing (Task)
import Time
import Url exposing (Url)


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = \model -> { title = "hello elm", body = [ Html.text "working" ] }
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = UrlRequested
        , onUrlChange = UrlChanged
        }



-- Model


type alias Model =
    { navKey : Browser.Navigation.Key
    , error : Maybe String
    , artists : List Artist
    , works : List Work
    , media : List Media
    }


initialModel : Browser.Navigation.Key -> Model
initialModel navKey =
    { navKey = navKey, error = Nothing, artists = [], works = [], media = [] }


init : () -> Url -> Browser.Navigation.Key -> ( Model, Cmd Msg )
init () url navKey =
    ( initialModel navKey
    , Task.map3 InitialData
        loadArtists
        loadWorks
        loadMedia
        |> Task.attempt InitialDataReceived
    )


loadArtists : Task Http.Error (List Artist)
loadArtists =
    getTask (JD.field "data" (JD.list artistDecoder)) "/api/artists"


loadWorks : Task Http.Error (List Work)
loadWorks =
    getTask (JD.field "data" (JD.list workDecoder)) "/api/works"


loadMedia : Task Http.Error (List Media)
loadMedia =
    getTask (JD.field "data" (JD.list mediaDecoder)) "/api/media"



-- Update


type Msg
    = InitialDataReceived (Result Http.Error InitialData)
    | UrlRequested Browser.UrlRequest
    | UrlChanged Url


type alias InitialData =
    { artists : List Artist, works : List Work, media : List Media }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        InitialDataReceived (Ok { artists, works, media }) ->
            ( { model
                | artists = artists
                , works = works
                , media = media
              }
            , Cmd.none
            )

        InitialDataReceived (Err httpError) ->
            ( { model | error = Just "Something went wrong" }, Cmd.none )

        UrlRequested urlRequest ->
            ( model, Cmd.none )

        UrlChanged url ->
            ( model, Cmd.none )



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- Types
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
