module Elmer.EventTests exposing (all)

import Test exposing (..)
import Elmer.TestApps.ClickTestApp as ClickApp
import Elmer.TestApps.InputTestApp as InputApp
import Elmer.TestApps.MessageTestApp as MessageApp
import Expect
import Elmer exposing (..)
import Elmer.Types exposing (..)
import Elmer.Event as Event
import Elmer.Command as Command

all : Test
all =
  describe "Event Tests"
    [ clickTests
    , inputTests
    , customEventTests
    , commandEventTests
    ]

standardEventHandlerBehavior : (ComponentStateResult ClickApp.Model ClickApp.Msg -> ComponentStateResult ClickApp.Model ClickApp.Msg) -> String -> Test
standardEventHandlerBehavior eventHandler eventName =
  describe "Event Handler Behavior"
  [ describe "when there is an upstream failure"
    [ test "it passes on the error" <|
      \() ->
        let
          initialState = UpstreamFailure "upstream failure"
        in
          eventHandler initialState
            |> Expect.equal initialState
    ]
  , describe "when there is no target node"
    [ test "it returns an upstream failure" <|
      \() ->
        let
          initialState = Elmer.componentState ClickApp.defaultModel ClickApp.view ClickApp.update
        in
          eventHandler initialState
           |> Expect.equal (UpstreamFailure "No target node specified")
    ]
  , describe "when the event is not found on the target node"
    [ test "it returns an event not found error" <|
      \() ->
        let
          initialState = Elmer.componentState ClickApp.defaultModel ClickApp.view ClickApp.update
        in
          Elmer.find ".noEvents" initialState
            |> eventHandler
            |> Expect.equal (UpstreamFailure ("No " ++ eventName ++ " event found"))
    ]
  ]

clickTests =
  describe "Click Event Tests"
  [ standardEventHandlerBehavior Event.click "click"
  , describe "when the click succeeds"
    [ test "it updates the model accordingly" <|
      \() ->
        let
          initialState = Elmer.componentState ClickApp.defaultModel ClickApp.view ClickApp.update
          updatedStateResult = Elmer.find ".button" initialState
                                |> Event.click
        in
          case updatedStateResult of
            CurrentState updatedState ->
              Expect.equal updatedState.model.clicks 1
            UpstreamFailure msg ->
              Expect.fail msg
    ]
  ]

inputTests =
  describe "input event tests"
  [ standardEventHandlerBehavior (Event.input "fun stuff") "input"
  , describe "when the input succeeds"
    [ test "it updates the model accordingly" <|
      \() ->
        let
          initialState = Elmer.componentState InputApp.defaultModel InputApp.view InputApp.update
          updatedStateResult = Elmer.find ".nameField" initialState
                                |> Event.input "Mr. Fun Stuff"
        in
          case updatedStateResult of
            CurrentState updatedState ->
              Expect.equal updatedState.model.name "Mr. Fun Stuff"
            UpstreamFailure msg ->
              Expect.fail msg
    ]
  ]

customEventTests =
  let
    keyUpEventJson = "{\"keyCode\":65}"
  in
    describe "custom event tests"
    [ standardEventHandlerBehavior (Event.on "keyup" keyUpEventJson) "keyup"
    , describe "when the event succeeds"
      [ test "it updates the model accordingly" <|
        \() ->
          let
            initialState = Elmer.componentState InputApp.defaultModel InputApp.view InputApp.update
            updatedStateResult = Elmer.find ".nameField" initialState
                                  |> Event.on "keyup" keyUpEventJson
          in
            case updatedStateResult of
              CurrentState updatedState ->
                Expect.equal updatedState.model.lastLetter 65
              UpstreamFailure msg ->
                Expect.fail msg
      ]
    ]

commandEventTests =
  describe "command event tests"
  [ describe "when there is an upstream failure"
    [ test "it passes on the error" <|
      \() ->
        let
          initialState = UpstreamFailure "upstream failure"
        in
          Event.sendCommand Cmd.none initialState
            |> Expect.equal initialState
    ]
  , describe "when there is no upstream failure"
    [ test "it executes the command and updates the component state" <|
        \() ->
          let
            initialState = Elmer.componentState MessageApp.defaultModel MessageApp.view MessageApp.update
            result = Event.sendCommand (Command.messageCommand (MessageApp.RenderFirstMessage "Did it!")) initialState
          in
            case result of
              CurrentState updatedState ->
                Expect.equal updatedState.model.firstMessage "Did it!"
              UpstreamFailure msg ->
                Expect.fail msg
    ]
  ]
