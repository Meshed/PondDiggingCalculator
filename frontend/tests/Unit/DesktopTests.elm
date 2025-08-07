module Unit.DesktopTests exposing (suite)

import Test exposing (..)
import Test.Html.Query as Query
import Test.Html.Selector exposing (..)
import Expect
import Html
import Html.Attributes
import Pages.Desktop as Desktop
import Types.Model exposing (Model)
import Types.DeviceType exposing (DeviceType(..))
import Utils.Calculations exposing (CalculationResult, Bottleneck(..), ConfidenceLevel(..))
import Components.ProjectForm exposing (FormData)
import Utils.Performance exposing (PerformanceMetrics)
import Utils.Performance
import Utils.Debounce exposing (DebounceState)
import Utils.Config


suite : Test
suite =
    describe "Desktop Page Tests"
        [ describe "Layout Structure"
            [ test "renders desktop three-column layout correctly" <|
                \_ ->
                    let
                        model = createTestModel Desktop
                        result = Desktop.view model
                    in
                    result
                        |> Query.fromHtml
                        |> Query.has [ class "grid-cols-3" ]
            
            , test "renders tablet two-column layout correctly" <|
                \_ ->
                    let
                        model = createTestModel Tablet
                        result = Desktop.view model
                    in
                    result
                        |> Query.fromHtml
                        |> Query.has [ class "grid-cols-2" ]
            
            , test "renders mobile single-column layout correctly" <|
                \_ ->
                    let
                        model = createTestModel Mobile
                        result = Desktop.view model
                    in
                    result
                        |> Query.fromHtml
                        |> Query.has [ class "flex-col" ]
            ]
        
        , describe "Section Headers"
            [ test "displays all three section headers" <|
                \_ ->
                    let
                        model = createTestModel Desktop
                        result = Desktop.view model
                        queryResult = Query.fromHtml result
                    in
                    queryResult
                        |> Query.findAll [ tag "h2" ]
                        |> Query.count (Expect.equal 3)
            
            , test "excavator section header is present" <|
                \_ ->
                    let
                        model = createTestModel Desktop
                        result = Desktop.view model
                    in
                    result
                        |> Query.fromHtml
                        |> Query.has [ text "Excavator Fleet" ]
            
            , test "truck section header is present" <|
                \_ ->
                    let
                        model = createTestModel Desktop
                        result = Desktop.view model
                    in
                    result
                        |> Query.fromHtml
                        |> Query.has [ text "Truck Fleet" ]
            
            , test "project configuration section header is present" <|
                \_ ->
                    let
                        model = createTestModel Desktop
                        result = Desktop.view model
                    in
                    result
                        |> Query.fromHtml
                        |> Query.has [ text "Project Configuration" ]
            ]
        
        , describe "Visual Styling"
            [ test "applies correct max-width for desktop" <|
                \_ ->
                    let
                        model = createTestModel Desktop
                        result = Desktop.view model
                    in
                    result
                        |> Query.fromHtml
                        |> Query.has [ class "max-w-7xl" ]
            
            , test "applies correct max-width for tablet" <|
                \_ ->
                    let
                        model = createTestModel Tablet
                        result = Desktop.view model
                    in
                    result
                        |> Query.fromHtml
                        |> Query.has [ class "max-w-5xl" ]
            
            , test "applies correct max-width for mobile" <|
                \_ ->
                    let
                        model = createTestModel Mobile
                        result = Desktop.view model
                    in
                    result
                        |> Query.fromHtml
                        |> Query.has [ class "max-w-lg" ]
            
            , test "sections have visual separation with shadows" <|
                \_ ->
                    let
                        model = createTestModel Desktop
                        result = Desktop.view model
                    in
                    result
                        |> Query.fromHtml
                        |> Query.findAll [ class "shadow-md" ]
                        |> Query.count (Expect.atLeast 3)
            
            , test "sections have proper border separation" <|
                \_ ->
                    let
                        model = createTestModel Desktop
                        result = Desktop.view model
                    in
                    result
                        |> Query.fromHtml
                        |> Query.findAll [ class "border-b" ]
                        |> Query.count (Expect.atLeast 3)
            ]
        
        , describe "Fleet Indicators"
            [ test "displays excavator fleet count" <|
                \_ ->
                    let
                        model = createTestModel Desktop
                        result = Desktop.view model
                    in
                    result
                        |> Query.fromHtml
                        |> Query.has [ text "2 Excavators" ]
            
            , test "displays truck fleet count" <|
                \_ ->
                    let
                        model = createTestModel Desktop
                        result = Desktop.view model
                    in
                    result
                        |> Query.fromHtml
                        |> Query.has [ text "3 Trucks" ]
            
            , test "fleet indicators show equipment icons" <|
                \_ ->
                    let
                        model = createTestModel Desktop
                        result = Desktop.view model
                    in
                    result
                        |> Query.fromHtml
                        |> Query.findAll [ tag "svg" ]
                        |> Query.count (Expect.atLeast 2)
            ]
        
        , describe "Responsive Behavior"
            [ test "desktop layout has appropriate gap spacing" <|
                \_ ->
                    let
                        model = createTestModel Desktop
                        result = Desktop.view model
                    in
                    result
                        |> Query.fromHtml
                        |> Query.has [ class "gap-8" ]
            
            , test "tablet layout has smaller gap spacing" <|
                \_ ->
                    let
                        model = createTestModel Tablet
                        result = Desktop.view model
                    in
                    result
                        |> Query.fromHtml
                        |> Query.has [ class "gap-6" ]
            
            , test "desktop has larger padding" <|
                \_ ->
                    let
                        model = createTestModel Desktop
                        result = Desktop.view model
                    in
                    result
                        |> Query.fromHtml
                        |> Query.has [ class "px-8" ]
            
            , test "tablet has medium padding" <|
                \_ ->
                    let
                        model = createTestModel Tablet
                        result = Desktop.view model
                    in
                    result
                        |> Query.fromHtml
                        |> Query.has [ class "px-6" ]
            
            , test "mobile has smaller padding" <|
                \_ ->
                    let
                        model = createTestModel Mobile
                        result = Desktop.view model
                    in
                    result
                        |> Query.fromHtml
                        |> Query.has [ class "px-4" ]
            ]
        
        , describe "Page Header"
            [ test "displays main heading" <|
                \_ ->
                    let
                        model = createTestModel Desktop
                        result = Desktop.view model
                    in
                    result
                        |> Query.fromHtml
                        |> Query.has [ text "Pond Digging Calculator" ]
            
            , test "displays subtitle" <|
                \_ ->
                    let
                        model = createTestModel Desktop
                        result = Desktop.view model
                    in
                    result
                        |> Query.fromHtml
                        |> Query.has [ text "Professional excavation timeline estimator" ]
            ]
        ]


-- Helper function to create test model
createTestModel : DeviceType -> Model
createTestModel deviceType =
    { message = ""
    , config = Just Utils.Config.fallbackConfig
    , formData = Just createTestFormData
    , calculationResult = Just createTestCalculationResult
    , lastValidResult = Nothing
    , hasValidationErrors = False
    , deviceType = deviceType
    , calculationInProgress = False
    , performanceMetrics = Utils.Performance.initMetrics
    , debounceState = Utils.Debounce.initDebounce
    }


-- Helper function to create test form data
createTestFormData : FormData
createTestFormData =
    { excavatorCapacity = "2.5"
    , excavatorCycleTime = "0.5"
    , truckCapacity = "15.0"
    , truckRoundTripTime = "30.0"
    , workHoursPerDay = "8.0"
    , pondLength = "100.0"
    , pondWidth = "50.0"
    , pondDepth = "8.0"
    , errors = []
    }


-- Helper function to create test calculation result
createTestCalculationResult : CalculationResult
createTestCalculationResult =
    { timelineInDays = 5
    , totalHours = 40.0
    , excavationRate = 120.0
    , haulingRate = 100.0
    , bottleneck = HaulingBottleneck
    , confidence = Medium
    , assumptions = [ "Standard soil conditions assumed", "No weather delays factored" ]
    , warnings = [ "Consider adding more trucks to improve efficiency" ]
    }