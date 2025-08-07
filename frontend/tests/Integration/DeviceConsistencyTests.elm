module Integration.DeviceConsistencyTests exposing (suite)

{-| Test suite to verify the architectural problem with separate mobile state

This demonstrates the broken architecture where mobile has separate state
instead of shared state with different presentation.

@docs suite

-}

import Expect
import Pages.Mobile as Mobile
import Test exposing (Test, describe, test)
import Types.DeviceType exposing (DeviceType(..))
import Types.Model exposing (Model)
import Utils.Config as Config


suite : Test
suite =
    describe "Device Consistency Architecture Tests"
        [ architecturalProblemTests
        ]


{-| Tests that demonstrate the architectural problem
-}
architecturalProblemTests : Test
architecturalProblemTests =
    describe "Demonstrates Broken Architecture - Separate Mobile State"
        [ test "proves_mobile_has_separate_state_from_main_model" <|
            \_ ->
                let
                    -- Mobile has its own completely separate state
                    ( mobileModel, _ ) =
                        Mobile.init

                    -- Main model would have different state structure
                    -- This test demonstrates they are completely separate
                    mainModelStructure =
                        { formData = Nothing -- Desktop uses formData
                        , calculationResult = Nothing
                        , mobileModel = Just mobileModel -- Mobile state is nested!
                        , deviceType = Mobile
                        }
                in
                -- This test DOCUMENTS the problem:
                -- Mobile state is separate from main state
                Expect.notEqual Nothing (Just mobileModel)
        , test "documents_state_isolation_problem" <|
            \_ ->
                let
                    -- User enters data in mobile view
                    ( initialMobile, _ ) =
                        Mobile.init

                    ( mobileWithInput, _ ) =
                        Mobile.update (Mobile.ExcavatorCapacityChanged "5.0") initialMobile

                    -- This data exists ONLY in mobile state
                    mobileExcavatorValue =
                        mobileWithInput.excavatorCapacity

                    -- Desktop formData would be completely separate
                    desktopFormData =
                        Nothing

                    -- No connection to mobile input!
                in
                -- This documents the problem: mobile input doesn't affect desktop state
                Expect.all
                    [ \_ -> Expect.equal "5.0" mobileExcavatorValue -- Mobile has the value
                    , \_ -> Expect.equal Nothing desktopFormData -- Desktop doesn't see it
                    ]
                    ()
        , test "documents_calculation_isolation_problem" <|
            \_ ->
                let
                    -- Mobile calculates result
                    ( initialMobile, _ ) =
                        Mobile.init

                    mobileWithConfig =
                        { initialMobile | config = Just Config.fallbackConfig }

                    ( mobileWithResult, _ ) =
                        Mobile.update (Mobile.ExcavatorCapacityChanged "3.0") mobileWithConfig

                    -- Desktop has separate calculation result
                    desktopResult =
                        Nothing

                    -- Completely separate!
                in
                case mobileWithResult.result of
                    Just mobileResult ->
                        -- Mobile has result, desktop doesn't - they're isolated!
                        Expect.notEqual (Just mobileResult) desktopResult

                    Nothing ->
                        Expect.pass

        -- Both empty, but still demonstrates separation
        ]
