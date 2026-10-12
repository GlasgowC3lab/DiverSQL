WITH aggregated_data AS (
    SELECT
        sr.sr_ticket_number,
        i1.i_product_name      AS store_product_name,
        td1.t_meal_time        AS store_meal_time,
        i2.i_product_name      AS web_product_name,
        td2.t_meal_time        AS web_meal_time,
        wp1.wp_url             AS page_url_1,
        wp2.wp_url             AS page_url_2,
        wp3.wp_url             AS page_url_3,
        SUM(sr.sr_return_amt) AS store_return_total,
        SUM(wr.wr_return_amt) AS web_return_total,
        i1.i_brand             AS store_brand
    FROM store_returns sr
    -- First join to time_dim for store return time
    JOIN time_dim td1
        ON sr.sr_return_time_sk = td1.t_time_sk
    -- Join to item for store return item details
    JOIN item i1
        ON sr.sr_item_sk = i1.i_item_sk
    -- Second (redundant) join to time_dim under a different alias
    JOIN time_dim td3
        ON sr.sr_return_time_sk = td3.t_time_sk
    -- Join to item again under a different alias (different role)
    JOIN item i3
        ON sr.sr_item_sk = i3.i_item_sk
    -- Bring in web_returns via the same time_dim (td1) – allowed join rule
    JOIN web_returns wr
        ON wr.wr_returned_time_sk = td1.t_time_sk
    -- Additional join to time_dim for web return time (different alias)
    JOIN time_dim td2
        ON wr.wr_returned_time_sk = td2.t_time_sk
    -- Join to item for the web return item
    JOIN item i2
        ON wr.wr_item_sk = i2.i_item_sk
    -- Join to web_page three times under different aliases
    JOIN web_page wp1
        ON wr.wr_web_page_sk = wp1.wp_web_page_sk
    JOIN web_page wp2
        ON wr.wr_web_page_sk = wp2.wp_web_page_sk
    JOIN web_page wp3
        ON wr.wr_web_page_sk = wp3.wp_web_page_sk
    -- Anti‑semi‑join condition
    WHERE sr.sr_ticket_number NOT IN (
        SELECT DISTINCT sr2.sr_ticket_number
        FROM store_returns sr2
        WHERE sr2.sr_return_amt > 5000
    )
    GROUP BY
        sr.sr_ticket_number,
        i1.i_product_name,
        td1.t_meal_time,
        i2.i_product_name,
        td2.t_meal_time,
        wp1.wp_url,
        wp2.wp_url,
        wp3.wp_url,
        i1.i_brand
    HAVING SUM(sr.sr_return_amt) > 0
)
SELECT
    sr_ticket_number,
    store_product_name,
    store_meal_time,
    web_product_name,
    web_meal_time,
    page_url_1,
    page_url_2,
    page_url_3,
    store_return_total,
    web_return_total,
    ROW_NUMBER() OVER (PARTITION BY store_brand ORDER BY store_return_total DESC) AS brand_rank
FROM aggregated_data
ORDER BY store_return_total DESC
LIMIT 100
