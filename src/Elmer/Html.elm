module Elmer.Html exposing
  ( HtmlElement
  , find
  , findChildren
  , expectElement
  , expectElementExists
  )

{-| Functions for working with the `Html msg` generated by a view function.

# Finding elements
@docs HtmlElement, find, findChildren

# General expectations
@docs expectElement, expectElementExists

-}

import Elmer exposing (Matcher)
import Elmer.Internal as Internal exposing (..)
import Elmer.Html.Types exposing (..)
import Elmer.Html.Internal as HtmlInternal
import Elmer.Html.Query as Query
import Html exposing (Html)
import Expect
import Dict exposing (Dict)
import Json.Decode as Json
import Regex exposing (Regex)


{-| Represents an Html element.
-}
type alias HtmlElement msg
  = Elmer.Html.Types.HtmlElement msg

{-| Target the first element matching the selector within the Html
produced by the component's `view` function. This is the most common
way to find an element during a test.

Find an element by class:

    find ".some-class-name"

Find an element by id:

    find "#some-id"

Find an element by Html tag:

    find "div"

Find an element by Html tag having attribute:

    find "div[data-my-attr]"

Find an element by Html tag having attribute with value:

    find "div[data-my-attr='my-value']"

Find an element having an attribute:

    find "[data-my-attr]"

Find an element with an attribute and value:

    find "[data-my-attr='my-value']"

-}
find : String -> Elmer.ComponentState model msg -> Elmer.ComponentState model msg
find selector =
    Internal.map (updateTargetSelector selector)


{-| Find the descendents of an element that match the given selector string.
You can use the same syntax for the selector string as you would with the
`find` function.

For example, you could expect that a list has a certain number of items:

    componentState
      |> find "ul"
      |> expectElement (\element ->
        findChildren "li" element
          |> List.count
          |> Expect.equal 3
      )
-}
findChildren : String -> HtmlElement msg -> List (HtmlElement msg)
findChildren selector node =
  List.filterMap (Query.findWithinElement selector) (Query.takeElements node.children)

{-| Make expectations about the targeted element.

    find ".my-class" componentState
      |> expectElement (\element ->
        Elmer.Html.Matchers.hasText "some text" element
      )

-}
expectElement : Matcher (HtmlElement msg) -> Matcher (Elmer.ComponentState model msg)
expectElement expectFunction =
  Internal.mapToExpectation <|
    \componentState ->
      case Query.targetElement componentState of
        Just element ->
          expectFunction element
        Nothing ->
          Expect.fail "Element does not exist"

{-| Expect that the targeted element exists.
-}
expectElementExists : Matcher (Elmer.ComponentState model msg)
expectElementExists componentStateResult =
    expectElement (\_ -> Expect.pass) componentStateResult


-- Private methods

updateTargetSelector : String -> Component model msg -> ComponentState model msg
updateTargetSelector selector componentState =
  let
    currentView = componentState.view componentState.model
  in
    case Query.findElement selector currentView of
        Just element ->
            Ready { componentState | targetSelector = Just selector }

        Nothing ->
          let
            failure = "No html node found with selector: " ++ selector ++ "\n\nThe current view is:\n\n"
              ++ (htmlToString currentView)
          in
            Failed failure


htmlToString : Html msg -> String
htmlToString htmlMsg =
  case Native.Html.asHtmlElement htmlMsg of
    Just node ->
      HtmlInternal.toString node
    Nothing ->
      "<No Nodes>"
