WITH base AS (
    SELECT
        s.s_store_id,
        s.s_manager,
        s.s_floor_space,
        s.s_country,
        c.c_customer_id,
        c.c_preferred_cust_flag,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        wp.wp_link_count,
        wp.wp_web_page_id,
        ARRAY[sr.sr_return_amt, wr.wr_return_amt] AS return_amt_array,
        CASE WHEN sr.sr_return_amt > 0 THEN 'Store' ELSE 'None' END AS store_return_flag,
        CASE WHEN wr.wr_return_amt > 0 THEN 'Web' ELSE 'None' END AS web_return_flag
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN web_returns wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE s.s_manager IN ('Brett Yates', 'David Thomas')
      AND s.s_country = 'United States'
      AND s.s_floor_space > 5000000
      AND wp.wp_link_count >= 10
      AND hd.hd_buy_potential IN ('>10000', '1001-5000')
      AND c.c_preferred_cust_flag = 'Y'
),
unnested AS (
    SELECT
        b.*, 
        amt AS return_amount_unnested
    FROM base b
    CROSS JOIN UNNEST(b.return_amt_array) AS t(amt)
),
agg AS (
    SELECT
        u.s_store_id,
        u.hd_buy_potential,
        SUM(u.return_amount_unnested) AS total_return_amount,
        COUNT(*) AS rows_cnt,
        SUM(CASE WHEN u.return_amount_unnested > 100 THEN 1 ELSE 0 END) AS high_return_cnt
    FROM unnested u
    GROUP BY GROUPING SETS (
        (u.s_store_id, u.hd_buy_potential),
        (u.s_store_id),
        (u.hd_buy_potential)
    )
),
store_summary AS (
    SELECT
        a.s_store_id,
        SUM(a.total_return_amount) AS store_total_return,
        SUM(a.rows_cnt) AS store_rows,
        SUM(a.high_return_cnt) AS store_high_return_cnt
    FROM agg a
    GROUP BY a.s_store_id
)
SELECT
    ss.s_store_id,
    ss.store_total_return,
    ss.store_rows,
    ss.store_high_return_cnt,
    ss.store_total_return / NULLIF(ss.store_rows, 0) AS avg_return_per_row,
    CASE WHEN ss.store_total_return > 50000 THEN 'High' ELSE 'Medium' END AS return_level
FROM store_summary ss
JOIN store s ON ss.s_store_id = s.s_store_id
WHERE s.s_manager IN ('Brett Yates', 'David Thomas')
  AND s.s_country = 'United States'
  AND s.s_floor_space > 5000000
ORDER BY ss.store_total_return DESC
LIMIT 100
