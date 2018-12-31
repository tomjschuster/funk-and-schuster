module Main exposing (main)

import Browser
import Browser.Navigation as Navigation
import Dict exposing (Dict)
import Html
    exposing
        ( Html
        , a
        , button
        , form
        , h2
        , h3
        , img
        , input
        , label
        , li
        , main_
        , option
        , section
        , select
        , text
        , ul
        )
import Html.Attributes
    exposing
        ( disabled
        , for
        , height
        , href
        , id
        , name
        , selected
        , src
        , type_
        , value
        , width
        )
import Html.Events exposing (onClick, onInput, onSubmit)
import Http
import Json.Decode as JD
import Json.Encode as JE
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
    | Dashboard DashboardModel
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
      -- DASHBOARD
      -- New Artist Form
    | NewArtist
    | CancelNewArtist
    | CreateNewArtist
    | ArtistCreated (Result Http.Error ArtistId)
    | InputNewArtistFirstName String
    | InputNewArtistLastName String
    | InputNewArtistDob String
      -- New Work Form
    | NewWork
    | CancelNewWork
    | CreateNewWork
    | WorkCreated (Result Http.Error WorkId)
    | InputNewWorkTitle String
    | InputNewWorkArtist (Maybe Int)
    | InputNewWorkDate String
    | InputNewWorkMedium String
    | InputNewWorkDimensions String


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
                , pageState = routeToPageState artData model.route
              }
            , Cmd.none
            )

        ArtDataLoaded (Err httpError) ->
            ( { model | artDataState = ArtDataError (Debug.toString httpError) }
            , Cmd.none
            )

        -- DASHBOARD
        -- New Artist Form
        NewArtist ->
            updateDashboard
                (\dashboardModel ->
                    ( { dashboardModel | dashboardForm = NewArtistForm emptyArtistForm }, Cmd.none )
                )
                model

        CancelNewArtist ->
            updateDashboard
                (\dashboardModel ->
                    ( { dashboardModel | dashboardForm = NoDashboardForm }, Cmd.none )
                )
                model

        CreateNewArtist ->
            updateDashboard
                (updateNewArtistForm
                    (\formData ->
                        ( formData
                        , formData |> createArtist |> Task.attempt ArtistCreated
                        )
                    )
                )
                model

        ArtistCreated (Ok artistId) ->
            ( model |> addNewArtistToArtData artistId |> clearDashboardForm
            , Cmd.none
            )

        ArtistCreated (Err error) ->
            ( model, Cmd.none )

        InputNewArtistFirstName firstName ->
            ( mapDashboard (mapNewArtistForm (\f -> { f | firstName = firstName })) model
            , Cmd.none
            )

        InputNewArtistLastName lastName ->
            ( mapDashboard (mapNewArtistForm (\f -> { f | lastName = lastName })) model
            , Cmd.none
            )

        InputNewArtistDob dobString ->
            ( mapDashboard (mapNewArtistForm (\f -> { f | dob = iso8601DateToPosix dobString })) model
            , Cmd.none
            )

        -- New Work Form
        NewWork ->
            updateDashboard
                (\dashboardModel ->
                    ( { dashboardModel | dashboardForm = NewWorkForm emptyWorkForm }, Cmd.none )
                )
                model

        CancelNewWork ->
            updateDashboard
                (\dashboardModel ->
                    ( { dashboardModel | dashboardForm = NoDashboardForm }, Cmd.none )
                )
                model

        CreateNewWork ->
            updateDashboard
                (updateNewWorkForm
                    (\formData ->
                        ( formData
                        , formData |> createWork |> Task.attempt WorkCreated
                        )
                    )
                )
                model

        WorkCreated (Ok workId) ->
            ( model |> addNewWorkToArtData workId |> clearDashboardForm
            , Cmd.none
            )

        WorkCreated (Err error) ->
            ( model, Cmd.none )

        InputNewWorkTitle title ->
            ( mapDashboard (mapNewWorkForm (\f -> { f | title = title })) model
            , Cmd.none
            )

        InputNewWorkArtist artistId ->
            ( mapDashboard (mapNewWorkForm (\f -> { f | artistId = Maybe.map artistIdFromInt artistId })) model
            , Cmd.none
            )

        InputNewWorkDate dateString ->
            ( mapDashboard (mapNewWorkForm (\f -> { f | date = iso8601DateToPosix dateString })) model
            , Cmd.none
            )

        InputNewWorkMedium medium ->
            ( mapDashboard (mapNewWorkForm (\f -> { f | medium = medium })) model
            , Cmd.none
            )

        InputNewWorkDimensions dimensions ->
            ( mapDashboard (mapNewWorkForm (\f -> { f | dimensions = dimensions })) model
            , Cmd.none
            )


routeToPageState : ArtData -> Maybe Route -> PageState
routeToPageState artData route =
    case route of
        Nothing ->
            NotFound

        Just DashboardRoute ->
            Dashboard (DashboardModel (artDataToDashboard artData) NoDashboardForm)

        Just (ArtistRoute artistId) ->
            ArtistPage (artistToArtistPage artData artistId)

        Just (WorkRoute workId) ->
            WorkPage (workToWorkPage artData workId)



-- Dashboard Page Transformation


addNewArtistToArtData : ArtistId -> Model -> Model
addNewArtistToArtData artistId model =
    case ( model.artDataState, model.pageState ) of
        ( ArtDataReady artData, Dashboard dashboardModel ) ->
            case dashboardModel.dashboardForm of
                NewArtistForm formData ->
                    let
                        artist =
                            formDataToArtist artistId formData

                        updatedArtData =
                            { artData | artists = artData.artists ++ [ artist ] }

                        dashboardArtData =
                            artDataToDashboard updatedArtData
                    in
                    { model
                        | artDataState = ArtDataReady { artData | artists = artist :: artData.artists }
                        , pageState = Dashboard { dashboardModel | artData = dashboardArtData }
                    }

                _ ->
                    model

        _ ->
            model


addNewWorkToArtData : WorkId -> Model -> Model
addNewWorkToArtData workId model =
    case ( model.artDataState, model.pageState ) of
        ( ArtDataReady artData, Dashboard dashboardModel ) ->
            case dashboardModel.dashboardForm of
                NewWorkForm formData ->
                    let
                        work =
                            formDataToWork workId formData

                        updatedArtData =
                            { artData | works = artData.works ++ [ work ] }

                        dashboardArtData =
                            artDataToDashboard updatedArtData
                    in
                    { model
                        | artDataState = ArtDataReady { artData | works = work :: artData.works }
                        , pageState = Dashboard { dashboardModel | artData = dashboardArtData }
                    }

                _ ->
                    model

        _ ->
            model


clearDashboardForm : Model -> Model
clearDashboardForm model =
    mapDashboard (\d -> { d | dashboardForm = NoDashboardForm }) model


updateDashboard : (DashboardModel -> ( DashboardModel, Cmd Msg )) -> Model -> ( Model, Cmd Msg )
updateDashboard f model =
    case model.pageState of
        Dashboard dashboardModel ->
            let
                ( updatedDashboardModel, cmd ) =
                    f dashboardModel
            in
            ( { model | pageState = Dashboard updatedDashboardModel }, cmd )

        _ ->
            ( model, Cmd.none )


mapDashboard : (DashboardModel -> DashboardModel) -> Model -> Model
mapDashboard f model =
    case model.pageState of
        Dashboard dashboardModel ->
            { model | pageState = Dashboard (f dashboardModel) }

        _ ->
            model


updateNewArtistForm :
    (ArtistFormData -> ( ArtistFormData, Cmd Msg ))
    -> DashboardModel
    -> ( DashboardModel, Cmd Msg )
updateNewArtistForm f dashboardModel =
    case dashboardModel.dashboardForm of
        NewArtistForm formData ->
            let
                ( updatedFormData, cmd ) =
                    f formData
            in
            ( { dashboardModel | dashboardForm = NewArtistForm updatedFormData }, cmd )

        _ ->
            ( dashboardModel, Cmd.none )


mapNewArtistForm : (ArtistFormData -> ArtistFormData) -> DashboardModel -> DashboardModel
mapNewArtistForm f dashboardModel =
    case dashboardModel.dashboardForm of
        NewArtistForm formData ->
            { dashboardModel | dashboardForm = NewArtistForm (f formData) }

        _ ->
            dashboardModel


updateNewWorkForm :
    (WorkFormData -> ( WorkFormData, Cmd Msg ))
    -> DashboardModel
    -> ( DashboardModel, Cmd Msg )
updateNewWorkForm f dashboardModel =
    case dashboardModel.dashboardForm of
        NewWorkForm formData ->
            let
                ( updatedFormData, cmd ) =
                    f formData
            in
            ( { dashboardModel | dashboardForm = NewWorkForm updatedFormData }, cmd )

        _ ->
            ( dashboardModel, Cmd.none )


mapNewWorkForm : (WorkFormData -> WorkFormData) -> DashboardModel -> DashboardModel
mapNewWorkForm f dashboardModel =
    case dashboardModel.dashboardForm of
        NewWorkForm formData ->
            { dashboardModel | dashboardForm = NewWorkForm (f formData) }

        _ ->
            dashboardModel


type alias DashboardModel =
    { artData : DashboardArtData
    , dashboardForm : DashboardForm
    }


type alias DashboardArtData =
    { artists : List DashboardArtist
    , works : List DashboardWork
    , media : List Media
    }


type DashboardForm
    = NoDashboardForm
    | NewArtistForm ArtistFormData
    | NewWorkForm WorkFormData


type alias ArtistFormData =
    { firstName : String
    , lastName : String
    , dob : Maybe Time.Posix
    }


formDataToArtist : ArtistId -> ArtistFormData -> Artist
formDataToArtist artistId formData =
    { id = artistId
    , firstName = formData.firstName
    , lastName = formData.lastName
    , dob = formData.dob
    }


emptyArtistForm : ArtistFormData
emptyArtistForm =
    { firstName = ""
    , lastName = ""
    , dob = Nothing
    }


encodeNewArtistForm : ArtistFormData -> JE.Value
encodeNewArtistForm formData =
    JE.object
        [ ( "first_name", JE.string formData.firstName )
        , ( "last_name", JE.string formData.lastName )
        , ( "dob"
          , formData.dob
                |> Maybe.map (posixToIso8601Date >> JE.string)
                |> Maybe.withDefault JE.null
          )
        ]


type alias WorkFormData =
    { title : String
    , artistId : Maybe ArtistId
    , date : Maybe Time.Posix
    , medium : String
    , dimensions : String
    }


formDataToWork : WorkId -> WorkFormData -> Work
formDataToWork workId formData =
    { id = workId
    , title = formData.title
    , artistId = Maybe.withDefault (artistIdFromInt 0) formData.artistId
    , date = formData.date
    , medium = OtherMedium formData.medium
    , dimensions = CustomDimensions formData.dimensions
    }


emptyWorkForm : WorkFormData
emptyWorkForm =
    { title = ""
    , artistId = Nothing
    , date = Nothing
    , medium = ""
    , dimensions = ""
    }


encodeNewWorkForm : WorkFormData -> JE.Value
encodeNewWorkForm formData =
    JE.object
        [ ( "title", JE.string formData.title )
        , ( "artist_id"
          , formData.artistId
                |> Maybe.map (artistIdToInt >> JE.int)
                |> Maybe.withDefault JE.null
          )
        , ( "date"
          , formData.date
                |> Maybe.map (posixToIso8601Date >> JE.string)
                |> Maybe.withDefault JE.null
          )
        , ( "medium", JE.string formData.medium )
        , ( "dimensions", JE.string formData.dimensions )
        ]


iso8601DateToPosix : String -> Maybe Time.Posix
iso8601DateToPosix isoString =
    case String.split "-" isoString of
        [ "", y, m, d ] ->
            Maybe.map3 ymdToPosix
                (String.toInt y |> Maybe.map ((*) -1))
                (String.toInt m)
                (String.toInt d)
                |> Maybe.withDefault Nothing

        [ y, m, d ] ->
            Maybe.map3 ymdToPosix
                (String.toInt y)
                (String.toInt m)
                (String.toInt d)
                |> Maybe.withDefault Nothing

        _ ->
            Nothing


posixToIso8601Date : Time.Posix -> String
posixToIso8601Date posix =
    (posix |> Time.toYear Time.utc |> String.fromInt |> String.padLeft 4 '0')
        ++ "-"
        ++ (posix |> Time.toMonth Time.utc |> monthToInt |> String.fromInt |> String.padLeft 2 '0')
        ++ "-"
        ++ (posix |> Time.toDay Time.utc |> String.fromInt |> String.padLeft 2 '0')


monthToInt : Time.Month -> Int
monthToInt month =
    case month of
        Time.Jan ->
            1

        Time.Feb ->
            2

        Time.Mar ->
            3

        Time.Apr ->
            4

        Time.May ->
            5

        Time.Jun ->
            6

        Time.Jul ->
            7

        Time.Aug ->
            8

        Time.Sep ->
            9

        Time.Oct ->
            10

        Time.Nov ->
            11

        Time.Dec ->
            12


ymdToPosix : Int -> Int -> Int -> Maybe Time.Posix
ymdToPosix year month day =
    if monthIsValid month && dayIsValid year month day then
        (monthDayToMillis year month day + yearToMillis year)
            |> negateIfBefore1970 year
            |> Time.millisToPosix
            |> Just
    else
        Nothing


dayIsValid : Int -> Int -> Int -> Bool
dayIsValid year month day =
    year
        |> monthDays
        |> List.drop (month - 1)
        |> List.head
        |> Maybe.map (\days -> day > 0 && day <= days)
        |> Maybe.withDefault False


monthIsValid : Int -> Bool
monthIsValid month =
    month > 0 && month < 13


yearToMillis : Int -> Int
yearToMillis year =
    let
        yearRange =
            if year < 1970 then
                List.range (year + 1) 1969
            else
                List.range 1970 (year - 1)
    in
    yearRange
        |> List.map millisInYear
        |> List.sum


millisInYear : Int -> Int
millisInYear year =
    if isLeapYear year then
        366 * millisInDay
    else
        365 * millisInDay


millisInDay : Int
millisInDay =
    24 * 60 * 60 * 1000


monthDayToMillis : Int -> Int -> Int -> Int
monthDayToMillis year month day =
    let
        currentMonthDays =
            if year < 1970 then
                year
                    |> monthDays
                    |> List.drop (month - 1)
                    |> List.head
                    |> Maybe.map ((-) day >> (+) 1)
                    |> Maybe.withDefault 0
            else
                day - 1

        previousMonthDays =
            if year < 1970 then
                year
                    |> monthDays
                    |> List.drop month
                    |> List.sum
            else
                year
                    |> monthDays
                    |> List.take (month - 1)
                    |> List.sum
    in
    (currentMonthDays + previousMonthDays) * millisInDay


monthDays : Int -> List Int
monthDays year =
    if isLeapYear year then
        [ 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 ]
    else
        [ 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 ]


isLeapYear : Int -> Bool
isLeapYear year =
    let
        divisibleBy4 =
            remainderBy 4 year == 0

        divisibleBy100 =
            remainderBy 100 year == 0

        divisibleBy400 =
            remainderBy 400 year == 0
    in
    if divisibleBy400 then
        True
    else if divisibleBy100 then
        False
    else if divisibleBy4 then
        True
    else
        False


negateIfBefore1970 : Int -> Int -> Int
negateIfBefore1970 year millis =
    if year < 1970 then
        -1 * millis
    else
        millis


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
    Dict.update (artistIdToInt work.artistId)
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

                Dashboard dashboardModel ->
                    viewDashboard dashboardModel

                ArtistPage artist ->
                    viewArtistPage artist

                WorkPage work ->
                    viewWorkPage work

        ArtDataError error ->
            [ text error ]



-- Dashboard View


viewDashboard : DashboardModel -> List (Html Msg)
viewDashboard { artData, dashboardForm } =
    case dashboardForm of
        NoDashboardForm ->
            [ main_ []
                [ button [ onClick NewArtist ] [ text "New Artist" ]
                , button [ onClick NewWork ] [ text "New Work" ]
                , section []
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

        NewArtistForm artistForm ->
            [ main_ []
                [ button [ onClick CancelNewArtist ] [ text "Cancel" ]
                , form [ onSubmit CreateNewArtist ]
                    [ label []
                        [ text "First Name"
                        , input
                            [ type_ "text"
                            , name "first-name"
                            , onInput InputNewArtistFirstName
                            ]
                            []
                        ]
                    , label []
                        [ text "Last Name"
                        , input
                            [ type_ "dobtext"
                            , name "last-name"
                            , onInput InputNewArtistLastName
                            ]
                            []
                        ]
                    , label []
                        [ text "DOB"
                        , input
                            [ type_ "date"
                            , name "dob"
                            , onInput InputNewArtistDob
                            ]
                            []
                        ]
                    , button [ type_ "submit" ] [ text "Create" ]
                    ]
                ]
            ]

        NewWorkForm workForm ->
            [ main_ []
                [ button [ onClick CancelNewWork ] [ text "Cancel" ]
                , form [ onSubmit CreateNewWork ]
                    [ label []
                        [ text "Title"
                        , input
                            [ type_ "text"
                            , name "title"
                            , onInput InputNewWorkTitle
                            ]
                            []
                        ]
                    , label []
                        [ text "Artist"
                        , artistDropDown workForm.artistId artData.artists
                        ]
                    , label []
                        [ text "Date"
                        , input
                            [ type_ "date"
                            , name "date"
                            , onInput InputNewWorkDate
                            ]
                            []
                        ]
                    , label []
                        [ text "Medium"
                        , input
                            [ type_ "text"
                            , name "medium"
                            , onInput InputNewWorkMedium
                            ]
                            []
                        ]
                    , label []
                        [ text "Dimensions"
                        , input
                            [ type_ "text"
                            , name "dimensions"
                            , onInput InputNewWorkDimensions
                            ]
                            []
                        ]
                    , button [ type_ "submit" ] [ text "Create" ]
                    ]
                ]
            ]


artistDropDown : Maybe ArtistId -> List DashboardArtist -> Html Msg
artistDropDown artistId artists =
    select
        [ name "artist-id"
        , onInput (String.toInt >> InputNewWorkArtist)
        ]
        (option [ value "-", selected (artistId == Nothing) ] [ text "-" ] :: List.map (artistOption artistId) artists)


artistOption : Maybe ArtistId -> DashboardArtist -> Html Msg
artistOption artistId artist =
    option
        [ value (artist.id |> artistIdToInt |> String.fromInt)
        , selected (Just artist.id == artistId)
        ]
        [ text artist.fullName ]


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
    , dob : Maybe Time.Posix
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
    , dob = Nothing
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
        (JD.field "dob" (JD.maybe (JD.map Time.millisToPosix JD.int)))


artistIdDecoder : JD.Decoder ArtistId
artistIdDecoder =
    JD.map ArtistId JD.int



-- Work


type alias Work =
    { id : WorkId
    , artistId : ArtistId
    , title : String
    , date : Maybe Time.Posix
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
    , date = Nothing
    , medium = OtherMedium ""
    , dimensions = CustomDimensions ""
    }


workDecoder : JD.Decoder Work
workDecoder =
    JD.map6 Work
        (JD.field "id" workIdDecoder)
        (JD.field "artist_id" artistIdDecoder)
        (JD.field "title" JD.string)
        (JD.field "date" (JD.maybe (JD.map Time.millisToPosix JD.int)))
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


createArtist : ArtistFormData -> Task Http.Error ArtistId
createArtist formData =
    postData (JE.object [ ( "artist", encodeNewArtistForm formData ) ]) artistIdDecoder (artistsUrl ++ "/")


createWork : WorkFormData -> Task Http.Error WorkId
createWork formData =
    postData (JE.object [ ( "work", encodeNewWorkForm formData ) ]) workIdDecoder (worksUrl ++ "/")



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


postData : JE.Value -> JD.Decoder a -> String -> Task Http.Error a
postData body decoder url =
    Http.task
        { method = "POST"
        , headers = []
        , url = url
        , body = Http.jsonBody body
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
