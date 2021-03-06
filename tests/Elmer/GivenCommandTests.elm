module Elmer.GivenCommandTests exposing (..)

import Test exposing (..)
import Expect
import Elmer exposing (exactly)
import Elmer.Http exposing (HttpResponseStub)
import Elmer.Http.Route exposing (..)
import Elmer.Http.Stub as Stub exposing (withBody)
import Elmer.Spy as Spy exposing (Spy, andCallFake)
import Elmer.Spy.Matchers exposing (wasCalledWith, stringArg)
import Elmer.Headless as Headless
import Elmer.TestApps.HeadlessTestApp as App
import Elmer.Printer exposing (..)


httpTests : Test
httpTests =
  describe "when a given command triggers an http request"
  [ test "the expectation is satisfied" <|
    \() ->
      Headless.givenCommand (\() -> App.httpCommand "http://fake.com/my-fake-stuff")
        |> Spy.use [ Elmer.Http.spy ]
        |> Elmer.Http.expect (get "http://fake.com/my-fake-stuff")
  ]


spyTests : Test
spyTests =
  describe "when the test for a given command uses a spy"
  [ test "it satisfies expectations about the spy" <|
    \() ->
      Headless.givenCommand (\() -> App.spyCommand "hello")
        |> Spy.use [ testPortSpy ]
        |> Spy.expect "test-port-spy" (\calls ->
            wasCalledWith [ stringArg "hello" ] calls
        )
  ]


testPortSpy : Spy
testPortSpy =
  Spy.create "test-port-spy" (\_ -> App.testPortCommand)
    |> andCallFake (\_ -> Cmd.none)


expectMessageTests : Test
expectMessageTests =
  describe "when a given command results in a message"
  [ describe "when the processing the command is successful"
    [ test "it records the messages" <|
      \() ->
        Headless.givenCommand (\() -> App.httpCommand "http://fake.com/my-fake-stuff")
          |> Spy.use [ Elmer.Http.serve [ httpResponse "http://fake.com/my-fake-stuff" ] ]
          |> Headless.expectMessages (
            exactly 1 <| Expect.equal (App.HttpRequest <| Ok [ 22, 34 ])
          )
    ]
  , describe "when processing the command results in a test failure"
    [ test "it records the messages" <|
      \() ->
        Headless.givenCommand (\() -> App.httpCommand "http://fake.com/my-fake-stuff")
          |> Spy.use [ Elmer.Http.serve [ httpBadResponse "http://fake.com/my-fake-stuff" ] ]
          |> Headless.expectMessages (
            exactly 1 <| Expect.equal (App.HttpRequest <| Ok [ 22, 34 ])
          )
          |> Expect.equal (Expect.fail (format
            [ message "Parsing a stubbed response" "GET http://fake.com/my-fake-stuff"
            , description ("\tWith body: \"Hey!\"")
            , message "failed with error" "Given an invalid JSON: Unexpected token H in JSON at position 0"
            , description "If you really want to generate a BadPayload error, consider using\nElmer.Http.Stub.withError to build your stubbed response."
            ]
          ))
    ]
  ]


httpResponse : String -> HttpResponseStub
httpResponse url =
  Stub.for (get url)
    |> withBody "[22,34]"


httpBadResponse : String -> HttpResponseStub
httpBadResponse url =
  Stub.for (get url)
    |> withBody "Hey!"
