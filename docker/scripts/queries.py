from gql import gql

GET_CAR_DETAILS = gql(
    """
    query CarDetails {
        cars(isOwned: false) {
            id
            displayName
            searchUrl
        }
    }
"""
)

CREATE_CAR_DETAIL = gql(
    """
    mutation CreateCarDetail(
        $carId: Int!,
        $url: String!,
        $year: Int!,
        $miles: Int!,
        $price: Int!,
        $distance: Int,
        $displayName: String!
        $effectiveDate: String!
    ) {
    createCarDetail(
        carId: $carId,
        url: $url,
        year: $year,
        miles: $miles,
        price: $price,
        distance: $distance,
        displayName: $displayName,
        effectiveDate: $effectiveDate,
    )
    }
    """
)

CREATE_YIELD = gql(
    """
    mutation CreateYield(
        $oneMonth: Float!,
        $twoMonth: Float!,
        $threeMonth: Float!,
        $sixMonth: Float!,
        $oneYear: Float!,
        $twoYear: Float!,
        $threeYear: Float!,
        $fiveYear: Float!,
        $sevenYear: Float!,
        $tenYear: Float!,
        $twentyYear: Float!,
        $thirtyYear: Float!,
        $effectiveDate: String!
    ) {
    createYield(
        oneMonth: $oneMonth,
        twoMonth: $twoMonth,
        threeMonth: $threeMonth,
        sixMonth: $sixMonth,
        oneYear: $oneYear,
        twoYear: $twoYear,
        threeYear: $threeYear,
        fiveYear: $fiveYear,
        sevenYear: $sevenYear,
        tenYear: $tenYear,
        twentyYear: $twentyYear,
        thirtyYear: $thirtyYear,
        effectiveDate: $effectiveDate,
    )
    }
    """
)
