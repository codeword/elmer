module Elmer.Http.Result exposing
  ( HttpResult
  , withBody
  , withHeader
  , withStatus
  )

{-| Functions for working with the stubbed result of an HTTP request.

@docs HttpResult, withBody, withHeader, withStatus

-}

import Elmer.Http.Internal as Internal
import Elmer.Http.Status exposing (HttpStatus)
import Dict

{-| Represents the stubbed result of an HTTP request.
-}
type alias HttpResult =
  Internal.HttpResult


{-| Set the body of an HttpResult.

If the given HttpResult is set to return an error, then this function
will do nothing. 
-}
withBody : String -> HttpResult -> HttpResult
withBody body result =
  case result of
    Internal.Response response ->
      Internal.Response { response | body = body }
    Internal.Error _ ->
      result


{-| Add a header to an HttpResult.

If the given HttpResult is set to return an error, then this function
will do nothing. 
-}
withHeader : (String, String) -> HttpResult -> HttpResult
withHeader (headerName, headerValue) result =
  case result of
    Internal.Response response ->
      Internal.Response { response | headers = Dict.insert headerName headerValue response.headers }
    Internal.Error _ ->
      result


{-| Set the status of an HttpResult.

If the given HttpResult is set to return an error, then this function
will do nothing.
-}
withStatus : HttpStatus -> HttpResult -> HttpResult
withStatus (Internal.HttpStatus newStatus) result =
  case result of
    Internal.Response response ->
      Internal.Response { response | status = newStatus }
    Internal.Error _ ->
      result