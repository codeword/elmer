module Elmer.NavigationTests exposing (..)

import Test exposing (..)
import Elmer.TestApps.NavigationTestApp as App
import Expect
import Elmer exposing (..)
import Elmer.TestState as TestState exposing (TestState)
import Elmer.Html.Event as Event
import Elmer.Spy as Spy
import Elmer.Platform.Command as Command
import Elmer.Navigation as ElmerNav
import Elmer.Navigation.Location as Location
import Elmer.Html.Matchers as Matchers exposing (..)
import Elmer.Printer exposing (..)
import Elmer.Html as Markup
import Navigation


expectLocationTests =
  describe "location tests"
  [ describe "when there is an upstream failure"
    [ test "it reports the failure" <|
      \() ->
        let
          initialState = TestState.failure "Nothing found!"
        in
          ElmerNav.expectLocation "http://blah.com" initialState
            |> Expect.equal (Expect.fail "Nothing found!")
    ]
  , describe "when a location has not been set"
    [ test "it explains the failure" <|
      \() ->
        let
          initialState = Elmer.given App.defaultModel App.view App.update
        in
          ElmerNav.expectLocation "http://badplace.com" initialState
            |> Expect.equal
              (Expect.fail "Expected to be at location:\n\n\thttp://badplace.com\n\nbut no location has been set")
    ]
  , describe "when a newURL command is sent"
    [ describe "when the correct url is expected"
      [ test "it passes" <|
          \() ->
            Elmer.given App.defaultModel App.view App.update
              |> Spy.use [ ElmerNav.spy ]
              |> Markup.target "#navigateButton"
              |> Event.click
              |> ElmerNav.expectLocation "http://fun.com/fun.html"
              |> Expect.equal Expect.pass
      ]
    , describe "when the incorrect url is expected"
      [ describe "when a location has been set"
        [ test "it explains the failure" <|
          \() ->
            Elmer.given App.defaultModel App.view App.update
              |> Spy.use [ ElmerNav.spy ]
              |> Markup.target "#navigateButton"
              |> Event.click
              |> ElmerNav.expectLocation "http://badplace.com"
              |> Expect.equal
                (Expect.fail (format [message "Expected to be at location:" "http://badplace.com", message "but location is:" "http://fun.com/fun.html"]))
        ]
      ]
    ]
  , describe "when a modifyUrl command is sent"
    [ describe "when the correct url is expected"
      [ test "it passes" <|
          \() ->
            Elmer.given App.defaultModel App.view App.update
              |> Spy.use [ ElmerNav.spy ]
              |> Markup.target "#modifyLocationButton"
              |> Event.click
              |> ElmerNav.expectLocation "http://fun.com/awesome.html"
              |> Expect.equal Expect.pass
      ]
    , describe "when the incorrect url is expected"
      [ describe "when a location has been set"
        [ test "it explains the failure" <|
          \() ->
            Elmer.given App.defaultModel App.view App.update
              |> Spy.use [ ElmerNav.spy ]
              |> Markup.target "#modifyLocationButton"
              |> Event.click
              |> ElmerNav.expectLocation "http://badplace.com"
              |> Expect.equal
                (Expect.fail (format [message "Expected to be at location:" "http://badplace.com", message "but location is:" "http://fun.com/awesome.html"]))
        ]
      ]
    ]
  ]

setLocationTests =
  let
    fullState =
      Elmer.given App.defaultModel App.view App.update
        |> ElmerNav.withLocationParser App.parseLocation
  in
  describe "set location"
  [ describe "when there is an upstream failure"
    [ test "it shows the message" <|
      \() ->
        let
          failureState = TestState.failure "failed"
        in
          ElmerNav.setLocation "http://fun.com/fun.html" failureState
            |> Markup.target ".error"
            |> Markup.expect elementExists
            |> Expect.equal (Expect.fail "failed")
    ]
  , describe "when no parser is set"
    [ test "it fails with a message" <|
      \() ->
        let
          stateWithoutParser = Elmer.given App.defaultModel App.view App.update
        in
          ElmerNav.setLocation "http://fun.com/fun.html" stateWithoutParser
            |> Markup.target ".error"
            |> Markup.expect elementExists
            |> Expect.equal (Expect.fail "setLocation failed because no locationParser was set")
    ]
  , describe "when locationParser is set"
    [ test "it updates the component state with the new location" <|
      \() ->
          ElmerNav.setLocation "http://fun.com/fun.html" fullState
            |> Markup.target ".error"
            |> Markup.expect (element <| hasText "Unknown path: /fun.html")
    , test "it updates the component state with another location" <|
      \() ->
        ElmerNav.setLocation "http://fun.com/api/view" fullState
          |> Markup.target ".error"
          |> Markup.expect (element <| hasText "No error")
    ]
  ]

asLocationTests =
  describe "asLocation tests"
  [ describe "hash"
    [ test "it has a default value" <|
      \() ->
        let
          location = Location.asLocation "http://fun.com/fun.html"
        in
          Expect.equal location.hash ""
    , test "it finds the hashed value" <|
      \() ->
        let
          location = Location.asLocation "http://fun.com/fun.html?key=value#some/fun/path"
        in
          Expect.equal location.hash "#some/fun/path"
    , describe "when the hash is relative"
      [ test "it finds the hashed value" <|
        \() ->
          let
            location = Location.asLocation "#some/fun/path"
          in
            Expect.equal location.hash "#some/fun/path"
      , test "it finds a single hashed value" <|
        \() ->
          let
            location = Location.asLocation "#hash"
          in
            Expect.equal location.hash "#hash"
      ]
    ]
  , describe "path"
    [ test "it finds the path" <|
      \() ->
        let
          location = Location.asLocation "http://fun.com/fun.html?key=value#some/fun/path"
        in
          Expect.equal location.pathname "/fun.html?key=value#some/fun/path"
    ]
  , describe "href"
    [ test "it contains the url" <|
      \() ->
        let
          location = Location.asLocation "http://fun.com/fun.html?key=value#some/fun/path"
        in
          Expect.equal location.href "http://fun.com/fun.html?key=value#some/fun/path"
    ]
  , describe "protocol"
    [ test "it contains the protocol" <|
      \() ->
        let
          location = Location.asLocation "http://fun.com/fun.html?key=value#some/fun/path"
        in
          Expect.equal location.protocol "http:"
    , test "it has a default value" <|
      \() ->
        let
          location = Location.asLocation "/fun.html?key=value#some/fun/path"
        in
          Expect.equal location.protocol ""
    ]
  , describe "search"
    [ test "it gets the query string" <|
      \() ->
        let
          location = Location.asLocation "http://fun.com/fun.html?key=value#some/fun/path"
        in
          Expect.equal location.search "?key=value"
    , test "it gets the query string when there is no hash" <|
      \() ->
        let
          location = Location.asLocation "http://fun.com/fun.html?key=value"
        in
          Expect.equal location.search "?key=value"
    , test "it returns an empty string when there is no query string" <|
      \() ->
        let
          location = Location.asLocation "http://fun.com/fun.html"
        in
          Expect.equal location.search ""
        ]
  ]
