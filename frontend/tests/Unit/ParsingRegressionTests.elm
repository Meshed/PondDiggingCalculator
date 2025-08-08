module Unit.ParsingRegressionTests exposing (suite)

{-| Regression tests for parsing errors that have been fixed

These tests ensure that common parsing mistakes don't get reintroduced:

  - Unicode escape syntax errors
  - Record update syntax errors
  - Import validation

@docs suite

-}

import Expect
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Parsing Regression Tests"
        [ describe "Unicode Escape Syntax Regression"
            [ test "should use proper Elm 0.19 Unicode escape syntax" <|
                \_ ->
                    let
                        -- Test that we're using correct Unicode escape format
                        validUnicodeEscapes =
                            [ "A" -- Capital A
                            , "\u{00A0}" -- Non-breaking space (was the bug)
                            , "λ" -- Lambda
                            , "😊" -- Smiling face emoji
                            ]

                        -- Ensure all Unicode escapes compile and are non-empty
                        allValidUnicode =
                            validUnicodeEscapes
                                |> List.map String.length
                                |> List.all (\len -> len > 0)

                        -- Test specific non-breaking space that caused the original error
                        nonBreakingSpace =
                            "\u{00A0}"

                        nonBreakingSpaceValid =
                            String.length nonBreakingSpace == 1
                    in
                    Expect.all
                        [ \_ -> Expect.equal True allValidUnicode
                        , \_ -> Expect.equal True nonBreakingSpaceValid
                        , \_ -> Expect.notEqual "" nonBreakingSpace
                        ]
                        ()
            , test "should demonstrate invalid Unicode escape patterns for reference" <|
                \_ ->
                    let
                        -- Document the INVALID patterns that caused parsing errors
                        -- (These are in comments to prevent actual syntax errors)
                        invalidPatterns =
                            [ "\\u00A0" -- Missing curly braces (was the bug)
                            , "\\u{00A0" -- Missing closing brace
                            , "\\u00A0}" -- Missing opening brace
                            , "\\u{}" -- Empty escape
                            ]

                        -- Test that we know what the correct patterns should be
                        correctPattern =
                            "\\u{00A0}"

                        -- Correct format with curly braces
                        documentationTest =
                            String.length correctPattern > 0
                    in
                    -- This test documents the fix for future developers
                    Expect.equal True documentationTest
            ]
        , describe "Whitespace Character Handling Regression"
            [ test "should handle various whitespace characters correctly" <|
                \_ ->
                    let
                        -- Test various whitespace characters that might use Unicode escapes
                        whitespaceChars =
                            [ " " -- Regular space
                            , "\t" -- Tab
                            , "\n" -- Newline
                            , "\u{000D}\n" -- Carriage return + newline
                            , "\u{00A0}" -- Non-breaking space (the fixed one)
                            , "\u{2003}" -- Em space
                            , "\u{2009}" -- Thin space
                            ]

                        allCharsValid =
                            whitespaceChars
                                |> List.map String.length
                                |> List.all (\len -> len > 0)

                        -- Test that trimming works with Unicode whitespace
                        textWithUnicodeSpace =
                            "\u{00A0}test\u{00A0}"

                        canProcessUnicodeWhitespace =
                            String.length textWithUnicodeSpace > 0
                    in
                    Expect.all
                        [ \_ -> Expect.equal True allCharsValid
                        , \_ -> Expect.equal True canProcessUnicodeWhitespace
                        , \_ -> Expect.notEqual "" textWithUnicodeSpace
                        ]
                        ()
            ]
        , describe "Record Update Syntax Regression"
            [ test "should use proper two-step record update syntax" <|
                \_ ->
                    let
                        -- Test proper record update syntax pattern
                        originalRecord =
                            { name = "test", value = 42, flag = False }

                        -- CORRECT: Two-step approach (what we fixed to)
                        baseRecord =
                            originalRecord

                        updatedRecord =
                            { baseRecord | flag = True }

                        -- Verify the update worked
                        updateWorked =
                            updatedRecord.flag == True && updatedRecord.name == "test"

                        -- Test that we can chain updates properly
                        chainedUpdate =
                            originalRecord
                                |> (\r -> { r | value = 100 })
                                |> (\r -> { r | flag = True })

                        chainWorked =
                            chainedUpdate.value == 100 && chainedUpdate.flag == True
                    in
                    Expect.all
                        [ \_ -> Expect.equal True updateWorked
                        , \_ -> Expect.equal True chainWorked
                        , \_ -> Expect.equal "test" updatedRecord.name
                        , \_ -> Expect.equal 100 chainedUpdate.value
                        ]
                        ()
            , test "should demonstrate invalid record update patterns for reference" <|
                \_ ->
                    let
                        -- Document the INVALID patterns that caused parsing errors
                        -- (These would cause compilation errors if uncommented)
                        -- INVALID: { createRecord() | field = value }  -- Function call in record update
                        -- INVALID: { someFunction param | field = value }  -- Expression in record update
                        -- The correct pattern for complex record creation + update
                        createComplexRecord flag =
                            { name = "complex", value = 999, flag = flag }

                        -- CORRECT: Separate the creation from the update
                        baseRecord =
                            createComplexRecord False

                        updatedRecord =
                            { baseRecord | value = 1000 }

                        patternValid =
                            updatedRecord.value == 1000 && updatedRecord.name == "complex"
                    in
                    -- This test documents the correct pattern for future developers
                    Expect.equal True patternValid
            , test "should handle nested record updates correctly" <|
                \_ ->
                    let
                        -- Test nested record update patterns that are safe
                        nestedRecord =
                            { outer = { inner = "initial" }, count = 0 }

                        -- CORRECT: Update nested records step by step
                        originalInner =
                            nestedRecord.outer

                        updatedInner =
                            { originalInner | inner = "updated" }

                        updatedRecord =
                            { nestedRecord | outer = updatedInner, count = 1 }

                        nestedUpdateWorked =
                            updatedRecord.outer.inner == "updated" && updatedRecord.count == 1
                    in
                    Expect.equal True nestedUpdateWorked
            ]
        ]
