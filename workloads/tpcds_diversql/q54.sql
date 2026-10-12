/*
Goal: Analyze the financial impact of catalog returns and related web sales by year, state, and shipping mode, summarizing total return amounts and net paid sales, then filtering for significant activity.
*/
WITH aggregated AS (
    SELECT
        d.d_year AS return_year,
        ca.ca_state AS state,
        sm.sm_type AS ship_type,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(*) AS transaction_cnt
    FROM
        catalog_returns cr
        INNER JOIN date_dim d
            ON cr.cr_returned_date_sk = d.d_date_sk
        INNER JOIN ship_mode sm
            ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        INNER JOIN customer_address ca
            ON cr.cr_refunded_addr_sk = ca.ca_address_sk
        INNER JOIN customer_demographics cd
            ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        INNER JOIN household_demographics hd
            ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        INNER JOIN web_sales ws
            ON ws.ws_sold_date_sk = d.d_date_sk
        INNER JOIN web_page wp
            ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE
        d.d_year = 2000
        AND sm.sm_type = 'AIR'
        AND ca.ca_state = 'CA'
        AND cd.cd_gender = 'M'
        AND hd.hd_buy_potential = '>10000'
        AND cr.cr_return_quantity > 20
        AND ws.ws_net_paid > 1000
    GROUP BY
        d.d_year,
        ca.ca_state,
        sm.sm_type
)
SELECT
    return_year,
    state,
    ship_type,
    total_return_amount,
    total_net_paid,
    transaction_cnt,
    (total_return_amount / NULLIF(total_net_paid, 0)) AS return_to_sales_ratio
FROM
    aggregated
WHERE
    total_return_amount > 1000
    AND total_net_paid > 5000
    AND transaction_cnt >= 5
ORDER BY
    return_to_sales_ratio DESC
LIMIT 100
