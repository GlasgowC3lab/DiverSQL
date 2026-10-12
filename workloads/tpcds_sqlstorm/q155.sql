WITH 
    date_filter AS (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2001
    ),
    store_profit AS (
        SELECT 
            ss_customer_sk AS customer_sk,
            SUM(ss_net_profit) AS total_store_profit,
            COUNT(*) AS store_txn_count,
            MAX(ss_sold_date_sk) AS last_store_sale_date_sk,
            MIN(ss_sold_date_sk) AS first_store_sale_date_sk
        FROM store_sales
        WHERE ss_sold_date_sk IN (SELECT d_date_sk FROM date_filter)
        GROUP BY ss_customer_sk
    ),
    web_profit AS (
        SELECT
            ws_bill_customer_sk AS customer_sk,
            SUM(ws_net_profit) AS total_web_profit,
            COUNT(*) AS web_txn_count,
            MAX(ws_sold_date_sk) AS last_web_sale_date_sk,
            MIN(ws_sold_date_sk) AS first_web_sale_date_sk
        FROM web_sales
        WHERE ws_sold_date_sk IN (SELECT d_date_sk FROM date_filter)
        GROUP BY ws_bill_customer_sk
    ),
    combined AS (
        SELECT 
            COALESCE(sp.customer_sk, wp.customer_sk) AS customer_sk,
            sp.total_store_profit,
            wp.total_web_profit,
            sp.store_txn_count,
            wp.web_txn_count,
            sp.last_store_sale_date_sk,
            wp.last_web_sale_date_sk,
            sp.first_store_sale_date_sk,
            wp.first_web_sale_date_sk,
            CASE 
                WHEN sp.total_store_profit IS NULL THEN 0
                ELSE sp.total_store_profit
            END - CASE 
                WHEN wp.total_web_profit IS NULL THEN 0
                ELSE wp.total_web_profit
            END AS profit_gap
        FROM store_profit sp
        FULL OUTER JOIN web_profit wp
            ON sp.customer_sk = wp.customer_sk
    ),
    demographics AS (
        SELECT 
            c.c_customer_sk,
            c.c_first_name,
            c.c_last_name,
            c.c_birth_year,
            cd.cd_gender,
            cd.cd_marital_status,
            COALESCE(c.c_birth_year, 2001) AS birth_year_fallback
        FROM customer c
        LEFT JOIN customer_demographics cd
            ON c.c_current_cdemo_sk = cd.cd_demo_sk
    ),
    profit_ranking AS (
        SELECT 
            c.customer_sk,
            d.c_first_name,
            d.c_last_name,
            d.cd_gender,
            d.cd_marital_status,
            COALESCE(c.total_store_profit, 0) + COALESCE(c.total_web_profit, 0) AS total_combined_profit,
            ROW_NUMBER() OVER (PARTITION BY d.cd_gender ORDER BY COALESCE(c.total_store_profit, 0) + COALESCE(c.total_web_profit, 0) DESC) AS gender_rank,
            RANK() OVER (ORDER BY COALESCE(c.total_store_profit, 0) + COALESCE(c.total_web_profit, 0) DESC) AS overall_rank,
            CONCAT('Customer ', d.c_first_name, ' ', d.c_last_name) AS display_name,
            CASE 
                WHEN c.profit_gap > 0 THEN 'Store Favored'
                WHEN c.profit_gap < 0 THEN 'Web Favored'
                ELSE 'Tie'
            END AS preferred_channel,
            NULLIF(c.profit_gap, 0) AS nonzero_profit_gap,
            c.profit_gap,
            c.last_store_sale_date_sk,
            c.last_web_sale_date_sk
        FROM combined c
        JOIN demographics d
            ON c.customer_sk = d.c_customer_sk
    ),
    high_spenders AS (
        SELECT 
            pr.customer_sk,
            pr.display_name,
            pr.total_combined_profit,
            pr.preferred_channel,
            DATE_FORMAT(date_dim.d_date, '%Y-%m-%d') AS last_sale_date,
            ROW_NUMBER() OVER (ORDER BY pr.total_combined_profit DESC) AS global_rank
        FROM profit_ranking pr
        LEFT JOIN date_dim
            ON (pr.profit_gap > 0 AND pr.last_store_sale_date_sk = date_dim.d_date_sk)
            OR (pr.profit_gap <= 0 AND pr.last_web_sale_date_sk = date_dim.d_date_sk)
        WHERE pr.total_combined_profit > (
            SELECT AVG(total_combined_profit) * 1.5 FROM profit_ranking
        )
    ),
    customer_high_return AS (
        SELECT sr_customer_sk AS customer_sk
        FROM store_returns
        WHERE sr_return_quantity > 5
        UNION ALL
        SELECT wr_refunded_customer_sk
        FROM web_returns
        WHERE wr_return_quantity > 5
    ),
    selected_customers AS (
        SELECT customer_sk FROM high_spenders
        INTERSECT
        SELECT customer_sk FROM customer_high_return
    ),
    call_center_activity AS (
        SELECT 
            cc.cc_call_center_id,
            COUNT(*) AS total_calls,
            SUM(cr.cr_return_quantity) AS total_return_qty,
            MAX(cr.cr_returned_date_sk) AS last_return_date_sk
        FROM call_center cc
        LEFT JOIN catalog_returns cr
            ON cc.cc_call_center_sk = cr.cr_call_center_sk
        WHERE cr.cr_returned_date_sk IS NOT NULL
        GROUP BY cc.cc_call_center_id
    ),
    call_center_flagged AS (
        SELECT 
            cca.cc_call_center_id,
            CASE 
                WHEN cca.total_calls > (SELECT AVG(total_calls) FROM call_center_activity) THEN 'HIGH'
                ELSE 'NORMAL'
            END AS call_center_load
        FROM call_center_activity cca
    )
SELECT 
    hs.global_rank,
    hs.display_name,
    hs.total_combined_profit,
    hs.preferred_channel,
    hs.last_sale_date,
    COALESCE(ccf.call_center_load, 'NONE') AS call_center_load,
    CASE 
        WHEN hs.total_combined_profit > 0 AND MOD(hs.global_rank, 2) = 0 THEN 'EVEN'
        ELSE 'ODD'
    END AS rank_parity,
    (SELECT COUNT(*) FROM store_returns sr WHERE sr.sr_customer_sk = hs.customer_sk AND sr.sr_return_quantity > 0) AS store_return_count,
    (SELECT COUNT(*) FROM web_returns wr WHERE wr.wr_refunded_customer_sk = hs.customer_sk AND wr.wr_return_quantity > 0) AS web_return_count
FROM high_spenders hs
LEFT JOIN call_center_flagged ccf
    ON hs.global_rank % 5 = try_cast(substring(ccf.cc_call_center_id, 1, 1) AS INTEGER) % 5
WHERE hs.global_rank <= 100
  AND hs.customer_sk IN (SELECT customer_sk FROM selected_customers)
UNION ALL
SELECT 
    -1 AS global_rank,
    'TOTAL_AGG' AS display_name,
    SUM(total_combined_profit) AS total_combined_profit,
    NULL AS preferred_channel,
    NULL AS last_sale_date,
    NULL AS call_center_load,
    NULL AS rank_parity,
    SUM(store_return_count) AS store_return_count,
    SUM(web_return_count) AS web_return_count
FROM (
    SELECT 
        hs.global_rank,
        hs.display_name,
        hs.total_combined_profit,
        hs.preferred_channel,
        hs.last_sale_date,
        COALESCE(ccf.call_center_load, 'NONE') AS call_center_load,
        CASE 
            WHEN hs.total_combined_profit > 0 AND MOD(hs.global_rank, 2) = 0 THEN 'EVEN'
            ELSE 'ODD'
        END AS rank_parity,
        (SELECT COUNT(*) FROM store_returns sr WHERE sr.sr_customer_sk = hs.customer_sk AND sr.sr_return_quantity > 0) AS store_return_count,
        (SELECT COUNT(*) FROM web_returns wr WHERE wr.wr_refunded_customer_sk = hs.customer_sk AND wr.wr_return_quantity > 0) AS web_return_count,
        hs.customer_sk
    FROM high_spenders hs
    LEFT JOIN call_center_flagged ccf
        ON hs.global_rank % 5 = try_cast(substring(ccf.cc_call_center_id, 1, 1) AS INTEGER) % 5
    WHERE hs.global_rank <= 100
      AND hs.customer_sk IN (SELECT customer_sk FROM selected_customers)
) agg
GROUP BY 
    global_rank,
    display_name,
    total_combined_profit,
    preferred_channel,
    last_sale_date,
    call_center_load,
    rank_parity,
    store_return_count,
    web_return_count
ORDER BY global_rank DESC
