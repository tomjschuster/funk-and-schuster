module Main exposing (main)

import Browser
import Browser.Navigation
import Dict exposing (Dict)
import Html exposing (Html, h3, img, li, main_, section, text, ul)
import Html.Attributes exposing (height, src, width)
import Http
import Json.Decode as JD
import Task exposing (Task)
import Time
import Url exposing (Url)


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = view
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
    , Task.map3 InitialData loadArtists loadWorks loadMedia
        |> Task.attempt InitialDataReceived
    )



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



-- View


type alias ArtistView =
    { id : ArtistId
    , fullName : String
    , workCount : Int
    }


artistToView : Dict Int Int -> Artist -> ArtistView
artistToView workCountByArtistId artist =
    { id = artist.id
    , fullName = artistFullName artist
    , workCount =
        workCountByArtistId
            |> Dict.get (artistIdToInt artist.id)
            |> Maybe.withDefault 0
    }


pluralizeWorks : Int -> String
pluralizeWorks workCount =
    case workCount of
        1 ->
            "1 work"

        count ->
            String.fromInt count ++ " works"


type alias WorkView =
    { id : WorkId
    , title : String
    , artist : ArtistView
    }


workToView : Dict Int ArtistView -> Work -> WorkView
workToView artistById work =
    { id = work.id
    , title = work.title
    , artist =
        artistById
            |> Dict.get (artistIdToInt work.artistId)
            |> Maybe.withDefault (artistToView Dict.empty emptyArtist)
    }


incrementWorkCount : Work -> Dict Int Int -> Dict Int Int
incrementWorkCount work workCountByArtistId =
    Dict.update (workIdToInt work.id)
        (Maybe.map (\count -> count + 1) >> Maybe.withDefault 1 >> Just)
        workCountByArtistId


view : Model -> Browser.Document Msg
view model =
    let
        workCountByArtistId =
            List.foldl incrementWorkCount Dict.empty model.works

        artistViews =
            List.map (artistToView workCountByArtistId) model.artists

        artistById =
            artistViews
                |> List.map (\artist -> ( artistIdToInt artist.id, artist ))
                |> Dict.fromList

        workViews =
            List.map (workToView artistById) model.works
    in
    { title = "Art Database"
    , body =
        [ main_ []
            [ section []
                [ h3 [] [ text "Artists" ]
                , artistsList artistViews
                ]
            , section []
                [ h3 [] [ text "Works" ]
                , worksList workViews
                ]
            , section []
                [ h3 [] [ text "Media" ]
                , mediaList model.media
                ]
            ]
        ]
    }


artistsList : List ArtistView -> Html Msg
artistsList artists =
    ul [] (List.map artistItem artists)


artistItem : ArtistView -> Html Msg
artistItem artist =
    li []
        [ text (artist.fullName ++ " (" ++ pluralizeWorks artist.workCount ++ ")") ]


worksList : List WorkView -> Html Msg
worksList works =
    ul [] (List.map workItem works)


workItem : WorkView -> Html Msg
workItem work =
    li [] [ text (work.title ++ " - " ++ work.artist.fullName) ]


mediaList : List Media -> Html Msg
mediaList media =
    ul [] (List.map mediaItem media)


mediaItem : Media -> Html Msg
mediaItem media =
    li [] [ text media.title, img [ src media.src, height 100, width 100 ] [] ]



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


artistIdToInt : ArtistId -> Int
artistIdToInt (ArtistId id) =
    id


artistIdFromInt : Int -> ArtistId
artistIdFromInt id =
    ArtistId id


emptyArtist : Artist
emptyArtist =
    { id = artistIdFromInt 0
    , firstName = ""
    , lastName = ""
    , dob = Time.millisToPosix 0
    }


artistFullName : Artist -> String
artistFullName artist =
    artist.firstName ++ " " ++ artist.lastName


artistDecoder : JD.Decoder Artist
artistDecoder =
    JD.map4 Artist
        (JD.field "id" artistIdDecoder)
        (JD.field "first_name" JD.string)
        (JD.field "last_name" JD.string)
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


workIdToInt : WorkId -> Int
workIdToInt (WorkId id) =
    id


type Medium
    = OtherMedium String


type Dimensions
    = CustomDimensoins String


workDecoder : JD.Decoder Work
workDecoder =
    JD.map6 Work
        (JD.field "id" workIdDecoder)
        (JD.field "artist_id" artistIdDecoder)
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
        (JD.field "caption" (JD.map (Maybe.withDefault "") (JD.maybe JD.string)))
        (JD.field "src" JD.string)
        (JD.field "content_type" contentTypeDecoder)


mediaIdDecoder : JD.Decoder MediaId
mediaIdDecoder =
    JD.map MediaId JD.int


mediaOwnerDecoder : JD.Decoder MediaOwner
mediaOwnerDecoder =
    JD.oneOf
        [ JD.field "artist_id" (JD.map ArtistOwner artistIdDecoder)
        , JD.field "work_id" (JD.map WorkOwner workIdDecoder)
        , JD.succeed NoOwner
        ]


contentTypeDecoder : JD.Decoder ContentType
contentTypeDecoder =
    JD.map OtherContentType JD.string



-- HTTP
-- Requests


baseApi : String
baseApi =
    "/api/art"


artistsUrl : String
artistsUrl =
    baseApi ++ "/artists"


worksUrl : String
worksUrl =
    baseApi ++ "/works"


mediaUrl : String
mediaUrl =
    baseApi ++ "/media"


loadArtists : Task Http.Error (List Artist)
loadArtists =
    getData (JD.list artistDecoder) artistsUrl


loadWorks : Task Http.Error (List Work)
loadWorks =
    getData (JD.list workDecoder) worksUrl


loadMedia : Task Http.Error (List Media)
loadMedia =
    getData (JD.list mediaDecoder) mediaUrl



-- HTTP Helpers


getData : JD.Decoder a -> String -> Task Http.Error a
getData decoder url =
    Http.task
        { method = "GET"
        , headers = []
        , url = url
        , body = Http.emptyBody
        , resolver = jsonResolver (JD.field "data" decoder)
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
