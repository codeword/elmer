module Elmer.Headless.Internal exposing
  ( HeadlessState(..)
  , create
  , createWithCommand
  )

import Elmer.TestState as TestState exposing (TestState, TestStateExtension(..))
import Elmer.Context as Context exposing (Context, UpdateFunction)
import Elmer.Runtime.Command as RuntimeCommand
import Elmer.Runtime as Runtime
import Html exposing (Html)
import Expect


type HeadlessState
  = Messages


create : model -> UpdateFunction model msg -> TestState model msg
create model update =
  Context.default model emptyView update
    |> TestState.with


createWithCommand : (() -> Cmd msg) -> TestState () msg
createWithCommand commandGenerator =
  Context.default () emptyView messageCollectorUpdate
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
  RuntimeCommand.mapState MapBeforeExpectationExtension (\state ->
    Maybe.withDefault [] state
      |> (::) (beforeExpectationExtension generator)
  )
    |> flip Context.updateState context


beforeExpectationExtension : (() -> Cmd msg) -> Context model msg -> TestState model msg
beforeExpectationExtension commandGenerator context =
  case Runtime.performCommand (commandGenerator ()) context of
    Ok resolvedContext ->
      TestState.with resolvedContext
    Err errorMessage ->
      TestState.failure errorMessage
