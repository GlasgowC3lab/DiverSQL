WITH item_rolling AS (
    SELECT
        sr2.sr_item_sk,
        d2.d_date,
        sum(sr2.sr_return_amt) OVER (
            PARTITION BY sr2.sr_item_sk
            ORDER BY d2.d_date
            ROWS BETWEEN 30 PRECEDING AND CURRENT ROW
        ) AS rolling_30d_return_amt
    FROM store_returns sr2
    JOIN date_dim d2
        ON sr2.sr_returned_date_sk = d2.d_date_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    d_return.d_year,
    sum(sr.sr_return_amt) AS total_return_amount,
    sum(sr.sr_return_quantity) AS total_return_quantity,
    avg(sr.sr_return_amt) AS avg_return_amount,
    count(DISTINCT i.i_item_sk) AS distinct_items_returned,
    min(d_return.d_date) AS earliest_return_date,
    max(d_return.d_date) AS latest_return_date,
    d_closed.d_date AS store_closed_date,
    count(DISTINCT wp.wp_web_page_sk) AS web_pages_created_on_return_dates,
    sum(wp.wp_image_count) AS total_image_count,
    sum(wp.wp_link_count) AS total_link_count,
    max(ir.rolling_30d_return_amt) AS max_30d_rolling_return_amount
FROM store_returns sr
JOIN date_dim d_return
    ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN item i
    ON sr.sr_item_sk = i.i_item_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
LEFT JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
LEFT JOIN web_page wp
    ON wp.wp_creation_date_sk = d_return.d_date_sk
LEFT JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
LEFT JOIN item_rolling ir
    ON ir.sr_item_sk = i.i_item_sk
   AND ir.d_date = d_return.d_date
WHERE d_return.d_year = 2022
  AND s.s_state = 'CA'
  AND i.i_category = 'Electronics'
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    d_return.d_year,
    d_closed.d_date
HAVING sum(sr.sr_return_amt) > 5000
ORDER BY total_return_amount DESC
LIMIT 100
