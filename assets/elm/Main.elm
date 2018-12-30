module Main exposing (main)

import Browser
import Browser.Navigation as Navigation
import Dict exposing (Dict)
import Html exposing (Html, a, button, h2, h3, img, li, main_, section, text, ul)
import Html.Attributes exposing (height, href, src, width)
import Html.Events exposing (onClick)
import Http
import Json.Decode as JD
import Task exposing (Task)
import Time
import Url exposing (Url)
import Url.Builder
import Url.Parser exposing ((</>))


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



-- Route


type Route
    = DashboardRoute
    | ArtistRoute ArtistId
    | WorkRoute WorkId


routeParser : Url.Parser.Parser (Route -> a) a
routeParser =
    Url.Parser.oneOf
        [ Url.Parser.map DashboardRoute (Url.Parser.s "art")
        , Url.Parser.map (artistIdFromInt >> ArtistRoute) (Url.Parser.s "art" </> Url.Parser.s "artists" </> Url.Parser.int)
        , Url.Parser.map (workIdFromInt >> WorkRoute) (Url.Parser.s "art" </> Url.Parser.s "works" </> Url.Parser.int)
        ]


parseRoute : Url -> Maybe Route
parseRoute url =
    Url.Parser.parse routeParser url


routeToUrl : Route -> String
routeToUrl route =
    case route of
        DashboardRoute ->
            Url.Builder.absolute [ "art" ] []

        ArtistRoute artistId ->
            let
                stringId =
                    artistId |> artistIdToInt |> String.fromInt
            in
            Url.Builder.absolute [ "art", "artists", stringId ] []

        WorkRoute workId ->
            let
                stringId =
                    workId |> workIdToInt |> String.fromInt
            in
            Url.Builder.absolute [ "art", "works", stringId ] []


routeLink : Route -> List (Html.Attribute msg) -> List (Html msg) -> Html msg
routeLink route attributes children =
    a (href (routeToUrl route) :: attributes) children



-- Model


type alias Model =
    { navKey : Navigation.Key
    , route : Maybe Route
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
    = PageLoading
    | NotFound
    | Dashboard DashboardArtData
    | ArtistPage ArtistPageArtist
    | WorkPage WorkPageWork


initialModel : Navigation.Key -> Maybe Route -> Model
initialModel navKey route =
    { navKey = navKey
    , route = route
    , artDataState = ArtDataLoading
    , pageState = PageLoading
    }


init : () -> Url -> Navigation.Key -> ( Model, Cmd Msg )
init () url navKey =
    ( initialModel navKey (parseRoute url)
    , Task.map3 ArtData loadArtists loadWorks loadMedia
        |> Task.attempt ArtDataLoaded
    )



-- Update


type Msg
    = NoOp
    | UrlRequested Browser.UrlRequest
    | UrlChanged Url
    | ArtDataLoaded (Result Http.Error ArtData)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        UrlRequested urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Navigation.pushUrl model.navKey (Url.toString url) )

                Browser.External href ->
                    ( model, Navigation.load href )

        UrlChanged url ->
            case model.artDataState of
                ArtDataReady artData ->
                    let
                        route =
                            parseRoute url

                        pageState =
                            routeToPageState artData route
                    in
                    ( { model | route = route, pageState = pageState }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        ArtDataLoaded (Ok artData) ->
            ( { model
                | artDataState = ArtDataReady artData
                , pageState = Dashboard (artDataToDashboard artData)
              }
            , Cmd.none
            )

        ArtDataLoaded (Err httpError) ->
            ( { model | artDataState = ArtDataError (Debug.toString httpError) }
            , Cmd.none
            )


routeToPageState : ArtData -> Maybe Route -> PageState
routeToPageState artData route =
    case route of
        Nothing ->
            NotFound

        Just DashboardRoute ->
            Dashboard (artDataToDashboard artData)

        Just (ArtistRoute artistId) ->
            ArtistPage (artistToArtistPage artData artistId)

        Just (WorkRoute workId) ->
            WorkPage (workToWorkPage artData workId)



-- Dashboard Page Transformation


type alias DashboardArtData =
    { artists : List DashboardArtist
    , works : List DashboardWork
    , media : List Media
    }


artDataToDashboard : ArtData -> DashboardArtData
artDataToDashboard artData =
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
    { artists = dashboardArtists
    , works = dashboardWorks
    , media = artData.media
    }


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



-- Artist Page Transformation


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


workToArtistPage : Dict Int (List Media) -> Work -> ArtistPageWork
workToArtistPage mediaByWorkId work =
    { title = work.title
    , media =
        mediaByWorkId
            |> Dict.get (workIdToInt work.id)
            |> Maybe.withDefault []
    }



-- Work Page Transformation


type alias WorkPageWork =
    { title : String
    , artist : WorkPageArtist
    , media : List Media
    }


type alias WorkPageArtist =
    { artistId : ArtistId
    , fullName : String
    , media : List Media
    }


workToWorkPage : ArtData -> WorkId -> WorkPageWork
workToWorkPage artData workId =
    let
        work =
            artData.works
                |> List.filter (\currWork -> currWork.id == workId)
                |> List.head
                |> Maybe.withDefault emptyWork

        artist =
            artData.artists
                |> List.filter (\currArtist -> currArtist.id == work.artistId)
                |> List.head
                |> Maybe.withDefault emptyArtist

        artistMedia =
            List.filter (mediaArtistId >> (==) (Just artist.id)) artData.media

        workMedia =
            List.filter (mediaWorkId >> (==) (Just workId)) artData.media

        workPageArtist =
            artistToWorkPage artistMedia artist
    in
    { title = work.title
    , artist = workPageArtist
    , media = workMedia
    }


artistToWorkPage : List Media -> Artist -> WorkPageArtist
artistToWorkPage media artist =
    { artistId = artist.id
    , fullName = artistFullName artist
    , media = media
    }



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

        ArtDataReady _ ->
            case model.pageState of
                PageLoading ->
                    [ text "Loading..." ]

                NotFound ->
                    [ text "Page not found" ]

                Dashboard artData ->
                    viewDashboard artData

                ArtistPage artist ->
                    viewArtistPage artist

                WorkPage work ->
                    viewWorkPage work

        ArtDataError error ->
            [ text error ]



-- Dashboard View


viewDashboard : DashboardArtData -> List (Html Msg)
viewDashboard artData =
    [ main_ []
        [ section []
            [ h3 [] [ text "Artists" ]
            , artistsList artData.artists
            ]
        , section []
            [ h3 [] [ text "Works" ]
            , worksList artData.works
            ]
        , section []
            [ h3 [] [ text "Media" ]
            , mediaList artData.media
            ]
        ]
    ]


artistsList : List DashboardArtist -> Html Msg
artistsList artists =
    ul [] (List.map artistItem artists)


artistItem : DashboardArtist -> Html Msg
artistItem artist =
    li []
        [ routeLink (ArtistRoute artist.id)
            []
            [ text (artist.fullName ++ " (" ++ pluralizeWorks artist.workCount ++ ")") ]
        ]


worksList : List DashboardWork -> Html Msg
worksList works =
    ul [] (List.map workItem works)


workItem : DashboardWork -> Html Msg
workItem work =
    li []
        [ routeLink (WorkRoute work.id)
            []
            [ text (work.title ++ " - " ++ work.artist.fullName)
            ]
        ]


mediaList : List Media -> Html Msg
mediaList media =
    ul [] (List.map mediaItem media)


mediaItem : Media -> Html Msg
mediaItem media =
    li [] [ text media.title, img [ src media.src, height 100, width 100 ] [] ]



-- Artist View


viewArtistPage : ArtistPageArtist -> List (Html Msg)
viewArtistPage artist =
    [ routeLink DashboardRoute [] [ text "Back" ]
    , h2 [] [ text artist.fullName ]
    ]



-- Work View


viewWorkPage : WorkPageWork -> List (Html Msg)
viewWorkPage work =
    [ routeLink DashboardRoute [] [ text "Back" ]
    , h2 [] [ text work.title ]
    ]



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


workIdFromInt : Int -> WorkId
workIdFromInt id =
    WorkId id


type Medium
    = OtherMedium String


type Dimensions
    = CustomDimensions String


emptyWork : Work
emptyWork =
    { id = workIdFromInt 0
    , artistId = artistIdFromInt 0
    , title = ""
    , date = Time.millisToPosix 0
    , medium = OtherMedium ""
    , dimensions = CustomDimensions ""
    }


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
    JD.map CustomDimensions JD.string



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
