module Main exposing (main)

import Browser
import Browser.Navigation
import Dict exposing (Dict)
import Html exposing (Html, button, h2, h3, img, li, main_, section, text, ul)
import Html.Attributes exposing (height, src, width)
import Html.Events exposing (onClick)
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
    , artDataState : ArtDataState
    , pageState : PageState
    }


type ArtDataState
    = ArtDataLoading
    | ArtDataReady ArtData
    | ArtDataError String


type alias ArtData =
    { artists : List Artist
    , works : List Work
    , media : List Media
    }


type PageState
    = Dashboard
    | ArtistPage ArtistId
    | WorkPage WorkId


initialModel : Browser.Navigation.Key -> Model
initialModel navKey =
    { navKey = navKey
    , artDataState = ArtDataLoading
    , pageState = Dashboard
    }


init : () -> Url -> Browser.Navigation.Key -> ( Model, Cmd Msg )
init () url navKey =
    ( initialModel navKey
    , Task.map3 ArtData loadArtists loadWorks loadMedia
        |> Task.attempt ArtDataLoaded
    )



-- Update


type Msg
    = NoOp
    | UrlRequested Browser.UrlRequest
    | UrlChanged Url
    | ArtDataLoaded (Result Http.Error ArtData)
    | GoToDashboard
    | GoToArtistPage ArtistId
    | GoToWorkPage WorkId


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        UrlRequested urlRequest ->
            ( model, Cmd.none )

        UrlChanged url ->
            ( model, Cmd.none )

        ArtDataLoaded (Ok { artists, works, media }) ->
            let
                artDataState =
                    ArtDataReady
                        { artists = artists
                        , works = works
                        , media = media
                        }
            in
            ( { model | artDataState = artDataState }
            , Cmd.none
            )

        ArtDataLoaded (Err httpError) ->
            ( { model | artDataState = ArtDataError (Debug.toString httpError) }
            , Cmd.none
            )

        GoToDashboard ->
            ( { model | pageState = Dashboard }, Cmd.none )

        GoToArtistPage artistId ->
            ( { model | pageState = ArtistPage artistId }, Cmd.none )

        GoToWorkPage workId ->
            ( { model | pageState = WorkPage workId }, Cmd.none )



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- View


view : Model -> Browser.Document Msg
view model =
    { title = "Art Database", body = viewBody model }


viewBody : Model -> List (Html Msg)
viewBody model =
    case model.artDataState of
        ArtDataLoading ->
            [ text "Loading..." ]

        ArtDataReady artData ->
            viewPage model.pageState artData

        ArtDataError error ->
            [ text error ]


viewPage : PageState -> ArtData -> List (Html Msg)
viewPage pageState artData =
    case pageState of
        Dashboard ->
            viewDashboard artData

        ArtistPage artistId ->
            viewArtistPage artistId artData

        WorkPage workId ->
            viewWorkPage workId artData



-- Dashboard View


viewDashboard : ArtData -> List (Html Msg)
viewDashboard artData =
    let
        workCountByArtistId =
            List.foldl incrementWorkCount Dict.empty artData.works

        dashboardArtists =
            List.map (artistToDashboard workCountByArtistId) artData.artists

        artistById =
            dashboardArtists
                |> List.map (\artist -> ( artistIdToInt artist.id, artist ))
                |> Dict.fromList

        dashboardWorks =
            List.map (workToDashboard artistById) artData.works
    in
    [ main_ []
        [ section []
            [ h3 [] [ text "Artists" ]
            , artistsList dashboardArtists
            ]
        , section []
            [ h3 [] [ text "Works" ]
            , worksList dashboardWorks
            ]
        , section []
            [ h3 [] [ text "Media" ]
            , mediaList artData.media
            ]
        ]
    ]


type alias DashboardArtist =
    { id : ArtistId
    , fullName : String
    , workCount : Int
    }


artistToDashboard : Dict Int Int -> Artist -> DashboardArtist
artistToDashboard workCountByArtistId artist =
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


type alias DashboardWork =
    { id : WorkId
    , title : String
    , artist : DashboardArtist
    }


workToDashboard : Dict Int DashboardArtist -> Work -> DashboardWork
workToDashboard artistById work =
    { id = work.id
    , title = work.title
    , artist =
        artistById
            |> Dict.get (artistIdToInt work.artistId)
            |> Maybe.withDefault (artistToDashboard Dict.empty emptyArtist)
    }


incrementWorkCount : Work -> Dict Int Int -> Dict Int Int
incrementWorkCount work workCountByArtistId =
    Dict.update (workIdToInt work.id)
        (Maybe.map (\count -> count + 1) >> Maybe.withDefault 1 >> Just)
        workCountByArtistId


artistsList : List DashboardArtist -> Html Msg
artistsList artists =
    ul [] (List.map artistItem artists)


artistItem : DashboardArtist -> Html Msg
artistItem artist =
    li [ onClick (GoToArtistPage artist.id) ]
        [ text (artist.fullName ++ " (" ++ pluralizeWorks artist.workCount ++ ")") ]


worksList : List DashboardWork -> Html Msg
worksList works =
    ul [] (List.map workItem works)


workItem : DashboardWork -> Html Msg
workItem work =
    li [] [ text (work.title ++ " - " ++ work.artist.fullName) ]


mediaList : List Media -> Html Msg
mediaList media =
    ul [] (List.map mediaItem media)


mediaItem : Media -> Html Msg
mediaItem media =
    li [] [ text media.title, img [ src media.src, height 100, width 100 ] [] ]



-- Artist View


viewArtistPage : ArtistId -> ArtData -> List (Html Msg)
viewArtistPage artistId artData =
    let
        artist =
            artistToArtistPage artData artistId
    in
    [ button [ onClick GoToDashboard ] [ text "Back" ]
    , h2 [] [ text artist.fullName ]
    ]


type alias ArtistPageArtist =
    { fullName : String
    , works : List ArtistPageWork
    , media : List Media
    }


type alias ArtistPageWork =
    { title : String
    , media : List Media
    }


artistToArtistPage : ArtData -> ArtistId -> ArtistPageArtist
artistToArtistPage artData artistId =
    let
        fullName =
            artData.artists
                |> List.filter (\artist -> artist.id == artistId)
                |> List.head
                |> Maybe.map artistFullName
                |> Maybe.withDefault ""

        mediaByWorkId =
            groupMediaByWorkId artData.media

        works =
            artData.works
                |> List.filter (\work -> work.artistId == artistId)
                |> List.map (workToArtistPage mediaByWorkId)

        artistMedia =
            List.filter (mediaArtistId >> (==) (Just artistId)) artData.media
    in
    { fullName = fullName
    , works = works
    , media = artistMedia
    }


groupMediaByWorkId : List Media -> Dict Int (List Media)
groupMediaByWorkId media =
    media
        |> filterWorkMedia
        |> List.foldr consWorkMedia Dict.empty


filterWorkMedia : List Media -> List ( Int, Media )
filterWorkMedia media =
    List.filterMap
        (\currMedia ->
            currMedia
                |> mediaWorkId
                |> Maybe.map (\workId -> ( workIdToInt workId, currMedia ))
        )
        media


consWorkMedia : ( Int, Media ) -> Dict Int (List Media) -> Dict Int (List Media)
consWorkMedia ( workId, media ) mediaByWorkId =
    let
        updatedMedia =
            mediaByWorkId
                |> Dict.get workId
                |> Maybe.map ((::) media)
                |> Maybe.withDefault [ media ]
    in
    Dict.insert workId updatedMedia mediaByWorkId


workToArtistPage : Dict Int (List Media) -> Work -> ArtistPageWork
workToArtistPage mediaByWorkId work =
    { title = work.title
    , media =
        mediaByWorkId
            |> Dict.get (workIdToInt work.id)
            |> Maybe.withDefault []
    }



-- Work View


viewWorkPage : WorkId -> ArtData -> List (Html Msg)
viewWorkPage workId artData =
    []



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


mediaArtistId : Media -> Maybe ArtistId
mediaArtistId media =
    case media.owner of
        ArtistOwner artistId ->
            Just artistId

        WorkOwner _ ->
            Nothing

        NoOwner ->
            Nothing


mediaWorkId : Media -> Maybe WorkId
mediaWorkId media =
    case media.owner of
        WorkOwner workId ->
            Just workId

        ArtistOwner _ ->
            Nothing

        NoOwner ->
            Nothing


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
