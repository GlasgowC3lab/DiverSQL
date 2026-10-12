WITH sampled_sales AS (
    SELECT *
    FROM store_sales TABLESAMPLE BERNOULLI (10)
),

sales_agg AS (
    SELECT
        ss_store_sk,
        ss_hdemo_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM sampled_sales
    WHERE ss_ext_sales_price > 1000
      AND ss_net_profit BETWEEN -5000 AND 5000
      AND ss_quantity >= 1
    GROUP BY ss_store_sk, ss_hdemo_sk
),

joined_data AS (
    SELECT
        s.s_store_id,
        s.s_state,
        s.s_city,
        s.s_gmt_offset,
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        sa.total_sales,
        sa.total_profit,
        sa.sales_cnt
    FROM sales_agg sa
    INNER JOIN store s
        ON sa.ss_store_sk = s.s_store_sk
    INNER JOIN household_demographics hd
        ON sa.ss_hdemo_sk = hd.hd_demo_sk
    INNER JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
),

returns_full AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_refunded_hdemo_sk,
        cr.cr_return_amount,
        cr.cr_net_loss
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 50
      AND cr.cr_net_loss < 1000
),

demog_returns AS (
    SELECT
        jd.s_store_id,
        jd.s_state,
        jd.s_city,
        jd.total_sales,
        jd.total_profit,
        jd.sales_cnt,
        r.cr_return_amount,
        r.cr_net_loss,
        jd.hd_demo_sk
    FROM joined_data jd
    FULL OUTER JOIN returns_full r
        ON jd.hd_demo_sk = r.cr_refunded_hdemo_sk
),

store_with_avg_return AS (
    SELECT
        dr.*,
        lr.avg_return_amount
    FROM demog_returns dr
    LEFT JOIN LATERAL (
        SELECT AVG(cr_return_amount) AS avg_return_amount
        FROM catalog_returns cr2
        WHERE cr2.cr_refunded_hdemo_sk = dr.hd_demo_sk
    ) lr ON TRUE
),

stores_high_sales AS (
    SELECT s_store_id
    FROM store_with_avg_return
    WHERE total_sales > 200000
),

stores_low_returns AS (
    SELECT s_store_id
    FROM store_with_avg_return
    WHERE cr_net_loss IS NULL OR cr_net_loss < 500
),

common_stores AS (
    SELECT s_store_id
    FROM stores_high_sales
    INTERSECT
    SELECT s_store_id
    FROM stores_low_returns
)

SELECT
    s.s_state,
    s.s_city,
    s.s_store_id,
    COALESCE(ag.total_sales, 0) AS total_sales,
    COALESCE(ag.total_profit, 0) AS total_profit,
    COALESCE(ag.sales_cnt, 0) AS sales_cnt,
    COALESCE(ag.avg_return_amount, 0) AS avg_return_amount
FROM store s
LEFT JOIN (
    SELECT
        jd.s_store_id,
        SUM(jd.total_sales) AS total_sales,
        SUM(jd.total_profit) AS total_profit,
        SUM(jd.sales_cnt) AS sales_cnt,
        MAX(jd.avg_return_amount) AS avg_return_amount
    FROM store_with_avg_return jd
    GROUP BY jd.s_store_id
) ag
    ON s.s_store_id = ag.s_store_id
WHERE s.s_store_id IN (SELECT s_store_id FROM common_stores)
GROUP BY CUBE(s.s_state, s.s_city, s.s_store_id, ag.total_sales, ag.total_profit, ag.sales_cnt, ag.avg_return_amount)
ORDER BY s.s_state ASC, s.s_city ASC
OFFSET 0
LIMIT 100
