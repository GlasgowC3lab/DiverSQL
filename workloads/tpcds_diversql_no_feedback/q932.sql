/*
Goal: Analyze net revenue performance per store, product category, and hour of day for California stores, accounting for returns, and produce detailed rows together with category‑hour subtotals and a grand total. The query demonstrates multiple filters, a CTE with aggregation, a second CTE adding a ranking window, a UNION DISTINCT to add category‑hour aggregates, and a final GROUP BY ROLLUP for subtotals. The result is limited to the first 100 rows.
*/
WITH base_sales AS (
    SELECT
        s.s_store_id,
        i.i_category,
        t.t_hour,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(COALESCE(sr.sr_return_amt_inc_tax, 0)) AS total_return_amt,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_txn_cnt
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_store_sk = s.s_store_sk
    WHERE i.i_category_id = 7                      -- filter 1: specific product category
      AND s.s_state = 'CA'                         -- filter 2: California stores
      AND t.t_hour BETWEEN 8 AND 17               -- filter 3: business hours
      AND ss.ss_quantity > 1                      -- filter 4: more than one item per sale
      AND (sr.sr_fee > 10 OR sr.sr_fee IS NULL)    -- filter 5: significant return fee when present
    GROUP BY s.s_store_id, i.i_category, t.t_hour
),
with_margin AS (
    SELECT
        s_store_id AS store_id,
        i_category,
        t_hour,
        total_net_paid,
        total_return_amt,
        return_txn_cnt,
        (total_net_paid - total_return_amt) AS net_margin,
        ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY (total_net_paid - total_return_amt) DESC) AS rank
    FROM base_sales
),
unioned AS (
    SELECT
        store_id,
        i_category,
        t_hour,
        total_net_paid,
        total_return_amt,
        return_txn_cnt,
        net_margin,
        rank
    FROM with_margin
    UNION DISTINCT
    SELECT
        NULL AS store_id,
        i_category,
        t_hour,
        SUM(total_net_paid) AS total_net_paid,
        SUM(total_return_amt) AS total_return_amt,
        SUM(return_txn_cnt) AS return_txn_cnt,
        SUM(net_margin) AS net_margin,
        NULL AS rank
    FROM with_margin
    GROUP BY i_category, t_hour
)
SELECT
    store_id,
    i_category,
    t_hour,
    SUM(total_net_paid) AS sum_net_paid,
    SUM(total_return_amt) AS sum_return_amt,
    SUM(return_txn_cnt) AS sum_return_cnt,
    SUM(net_margin) AS sum_net_margin,
    rank
FROM unioned
GROUP BY ROLLUP (store_id, i_category, t_hour, rank)
ORDER BY
    store_id NULLS LAST,
    i_category,
    t_hour
LIMIT 100
