module Page.Form exposing (Data, Model, Msg, page)

import DataSource exposing (DataSource)
import Dict exposing (Dict)
import Form exposing (Form)
import Head
import Head.Seo as Seo
import Html
import Html.Attributes as Attr
import Page exposing (Page, PageWithState, StaticPayload)
import PageServerResponse exposing (PageServerResponse)
import Pages.PageUrl exposing (PageUrl)
import Pages.Url
import Server.Request as Request exposing (Request)
import Shared
import View exposing (View)


type alias Model =
    {}


type alias Msg =
    Never


type alias RouteParams =
    {}


type alias User =
    { first : String
    , last : String
    , username : String
    , email : String
    , birthDay : String
    }


defaultUser : User
defaultUser =
    { first = "Jane"
    , last = "Doe"
    , username = "janedoe"
    , email = "janedoe@example.com"
    , birthDay = "1969-07-20"
    }


errorsView : List String -> Html.Html msg
errorsView errors =
    case errors of
        first :: rest ->
            Html.div []
                [ Html.ul
                    [ Attr.style "border" "solid red"
                    ]
                    (List.map
                        (\error ->
                            Html.li []
                                [ Html.text error
                                ]
                        )
                        (first :: rest)
                    )
                ]

        [] ->
            Html.div [] []


form : User -> Form User
form user =
    Form.succeed User
        |> Form.required
            (Form.input
                "first"
                (\{ toInput, toLabel, errors } ->
                    Html.div []
                        [ errorsView errors
                        , toLabel []
                            [ Html.text "First"
                            ]
                        , toInput []
                        ]
                )
                |> Form.withInitialValue user.first
            )
        |> Form.required
            (Form.input
                "last"
                (\{ toInput, toLabel, errors } ->
                    Html.div []
                        [ errorsView errors
                        , toLabel []
                            [ Html.text "Last"
                            ]
                        , toInput []
                        ]
                )
                |> Form.withInitialValue user.last
            )
        |> Form.required
            (Form.input
                "username"
                (\{ toInput, toLabel, errors } ->
                    Html.div []
                        [ errorsView errors
                        , toLabel []
                            [ Html.text "Username"
                            ]
                        , toInput []
                        ]
                )
                |> Form.withInitialValue user.username
                |> Form.withServerValidation
                    (\username ->
                        if username == "asdf" then
                            DataSource.succeed [ "username is taken" ]

                        else
                            DataSource.succeed []
                    )
            )
        |> Form.required
            (Form.input
                "email"
                (\{ toInput, toLabel, errors } ->
                    Html.div []
                        [ errorsView errors
                        , toLabel []
                            [ Html.text "Email"
                            ]
                        , toInput []
                        ]
                )
                |> Form.withInitialValue user.email
            )
        |> Form.required
            (Form.date
                "dob"
                (\{ toInput, toLabel, errors } ->
                    Html.div []
                        [ errorsView errors
                        , toLabel []
                            [ Html.text "Date of Birth"
                            ]
                        , toInput []
                        ]
                )
                |> Form.withInitialValue user.birthDay
                |> Form.withMinDate "1900-01-01"
                |> Form.withMaxDate "2022-01-01"
            )


page : Page RouteParams Data
page =
    Page.serverRender
        { head = head
        , data = data
        }
        |> Page.buildNoState { view = view }


type alias Data =
    { user : Maybe User
    , errors : Maybe (Dict String { raw : String, errors : List String })
    }


data : RouteParams -> Request (DataSource (PageServerResponse Data))
data routeParams =
    Request.oneOf
        [ Form.toRequest2 (form defaultUser)
            |> Request.map
                (\userOrErrors ->
                    userOrErrors
                        |> DataSource.map
                            (\result ->
                                (case result of
                                    Ok ( user, errors ) ->
                                        { user = Just user
                                        , errors = Just errors
                                        }

                                    Err errors ->
                                        { user = Nothing
                                        , errors = Just errors
                                        }
                                )
                                    |> PageServerResponse.RenderPage
                            )
                )
        , PageServerResponse.RenderPage
            { user = Nothing
            , errors = Nothing
            }
            |> DataSource.succeed
            |> Request.succeed
        ]


head :
    StaticPayload Data RouteParams
    -> List Head.Tag
head static =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = "elm-pages"
        , image =
            { url = Pages.Url.external "TODO"
            , alt = "elm-pages logo"
            , dimensions = Nothing
            , mimeType = Nothing
            }
        , description = "TODO"
        , locale = Nothing
        , title = "TODO title" -- metadata.title -- TODO
        }
        |> Seo.website


view :
    Maybe PageUrl
    -> Shared.Model
    -> StaticPayload Data RouteParams
    -> View Msg
view maybeUrl sharedModel static =
    let
        user : User
        user =
            static.data.user
                |> Maybe.withDefault defaultUser
    in
    { title = "Form Example"
    , body =
        [ static.data.user
            |> Maybe.map
                (\user_ ->
                    Html.p
                        [ Attr.style "padding" "10px"
                        , Attr.style "background-color" "#a3fba3"
                        ]
                        [ Html.text <| "Successfully received user " ++ user_.first ++ " " ++ user_.last
                        ]
                )
            |> Maybe.withDefault (Html.p [] [])
        , Html.h1
            []
            [ Html.text <| "Edit profile " ++ user.first ++ " " ++ user.last ]
        , form user
            |> Form.toHtml static.data.errors

        --, Html.input [ Attr.type_ "submit" ] []
        ]
    }
