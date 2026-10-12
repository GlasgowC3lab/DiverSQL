WITH store_ret AS (
    SELECT
        sr.sr_returned_date_sk AS return_date_sk,
        sr.sr_return_amt_inc_tax AS return_amount,
        sr.sr_return_quantity AS quantity,
        'store' AS channel,
        s.s_store_name AS entity_name,
        hd.hd_income_band_sk AS income_band,
        LAG(sr.sr_return_amt_inc_tax) OVER (PARTITION BY sr.sr_store_sk ORDER BY sr.sr_returned_date_sk) AS prev_return_amount,
        SUM(sr.sr_return_amt_inc_tax) OVER (PARTITION BY sr.sr_store_sk ORDER BY sr.sr_returned_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total,
        loc.full_location
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    CROSS JOIN LATERAL (
        SELECT concat_ws(', ', ca.ca_city, ca.ca_state) AS full_location
    ) AS loc
    WHERE sr.sr_return_tax > 0
),
web_ret AS (
    SELECT
        wr.wr_returned_date_sk AS return_date_sk,
        wr.wr_return_amt_inc_tax AS return_amount,
        wr.wr_return_quantity AS quantity,
        'web' AS channel,
        CAST(ws.ws_web_page_sk AS varchar) AS entity_name,
        hd.hd_income_band_sk AS income_band,
        LAG(wr.wr_return_amt_inc_tax) OVER (PARTITION BY ws.ws_web_page_sk ORDER BY wr.wr_returned_date_sk) AS prev_return_amount,
        SUM(wr.wr_return_amt_inc_tax) OVER (PARTITION BY ws.ws_web_page_sk ORDER BY wr.wr_returned_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total,
        loc.full_location
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    CROSS JOIN LATERAL (
        SELECT concat_ws(', ', ca.ca_city, ca.ca_state) AS full_location
    ) AS loc
    WHERE wr.wr_return_tax > 0
)
SELECT
    return_date_sk,
    return_amount,
    quantity,
    channel,
    entity_name,
    income_band,
    prev_return_amount,
    running_total,
    full_location
FROM (
    SELECT return_date_sk, return_amount, quantity, channel, entity_name, income_band, prev_return_amount, running_total, full_location
    FROM store_ret
    UNION ALL
    SELECT return_date_sk, return_amount, quantity, channel, entity_name, income_band, prev_return_amount, running_total, full_location
    FROM web_ret
) AS combined
ORDER BY channel, return_date_sk DESC
LIMIT 100
