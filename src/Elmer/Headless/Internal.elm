module Elmer.Headless.Internal exposing
  ( HeadlessState(..)
  , createWithCommand
  )

import Elmer.TestState as TestState exposing (TestState, TestStateExtension(..))
import Elmer.Context as Context exposing (Context)
import Elmer.Runtime.Command as RuntimeCommand
import Elmer.Runtime as Runtime
import Html exposing (Html)
import Expect

type alias CommandContextModel msg =
  { messages : List msg
  }

type HeadlessState
  = Messages


createWithCommand : (() -> Cmd msg) -> TestState {} msg
createWithCommand commandGenerator =
  Context.default {} emptyView messageCollectorUpdate
    |> withCommandGenerator commandGenerator
    |> TestState.with


emptyView : model -> Html msg
emptyView model =
  Html.text ""


messageCollectorUpdate : msg -> model -> (model, Cmd msg)
messageCollectorUpdate msg model =
  ( model
  , RuntimeCommand.mapState Messages <|
    \state ->
      Maybe.withDefault [] state
        |> (::) msg
  )


withCommandGenerator : (() -> Cmd msg) -> Context model msg -> Context model msg
withCommandGenerator generator context =
  RuntimeCommand.mapState MapToExpectationExtension (\state ->
    Maybe.withDefault [] state
      |> (::) (expectationExtension generator)
  )
    |> flip Context.updateState context


expectationExtension : (() -> Cmd msg) -> (Context model msg -> Expect.Expectation) -> Context model msg -> Expect.Expectation
expectationExtension commandGenerator mapper context =
  case Runtime.performCommand (commandGenerator ()) context of
    Ok resolvedContext ->
      mapper resolvedContext
    Err errorMessage ->
      Expect.fail errorMessage
