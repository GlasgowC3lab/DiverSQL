/*
Goal: Analyze the combined effect of product returns and web sales for household demographic groups, 
identifying high‑return groups while ranking them by total return amount and sales performance. 
The query pre‑aggregates web sales, joins all three tables, applies multiple filters (including an IN subquery), uses a UNION to combine two filtered perspectives, and adds window rankings.
*/
WITH ws_agg AS (
    SELECT
        ws_ship_hdemo_sk AS hd_demo_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_list_price) AS avg_list_price
    FROM web_sales
    WHERE ws_ship_date_sk BETWEEN 2451900 AND 2452400               -- filter 1
      AND ws_list_price > 50                                         -- filter 2
    GROUP BY ws_ship_hdemo_sk
),
unioned AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_buy_potential,
        SUM(cr.cr_return_amount + CASE WHEN cr.cr_fee > 0 THEN cr.cr_fee ELSE 0 END) AS total_return_amount,
        ws_agg.total_sales,
        'first_view' AS source_flag
    FROM catalog_returns cr
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk                 -- join rule 1
    JOIN ws_agg
        ON ws_agg.hd_demo_sk = hd.hd_demo_sk
    WHERE cr.cr_return_amount > 5                                   -- filter 3
      AND cr.cr_return_quantity > 5                                 -- filter 4
      AND hd.hd_dep_count >= 6                                      -- filter 5
      AND hd.hd_buy_potential LIKE '%1000%'                         -- filter 6
      AND cr.cr_return_quantity IN (
            SELECT ws_quantity
            FROM web_sales
            WHERE ws_list_price > 200
        )                                                       -- IN‑subquery filter
    GROUP BY hd.hd_demo_sk, hd.hd_buy_potential, ws_agg.total_sales

    UNION DISTINCT

    SELECT
        hd.hd_demo_sk,
        hd.hd_buy_potential,
        SUM(cr.cr_return_amount + CASE WHEN cr.cr_fee > 0 THEN cr.cr_fee ELSE 0 END) * 0.9 AS total_return_amount,
        ws_agg.total_sales,
        'second_view' AS source_flag
    FROM catalog_returns cr
    JOIN household_demographics hd
        ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk                -- join rule 2
    JOIN ws_agg
        ON ws_agg.hd_demo_sk = hd.hd_demo_sk
    WHERE cr.cr_return_amount > 10                                  -- filter 7
      AND cr.cr_return_quantity BETWEEN 10 AND 70                  -- filter 8
      AND hd.hd_dep_count <= 9                                      -- filter 9
      AND hd.hd_buy_potential = '1001-5000'                         -- filter 10
      AND cr.cr_return_quantity IN (
            SELECT ws_quantity
            FROM web_sales
            WHERE ws_list_price > 200
        )                                                       -- same IN‑subquery
    GROUP BY hd.hd_demo_sk, hd.hd_buy_potential, ws_agg.total_sales
)
SELECT
    hd_demo_sk,
    hd_buy_potential,
    total_return_amount,
    total_sales,
    RANK() OVER (ORDER BY total_return_amount DESC) AS return_amount_rank,
    ROW_NUMBER() OVER (PARTITION BY hd_buy_potential ORDER BY total_sales DESC) AS sales_row_num
FROM unioned
WHERE total_sales > 5000                                            -- final filter
ORDER BY total_return_amount DESC, hd_demo_sk
LIMIT 100
