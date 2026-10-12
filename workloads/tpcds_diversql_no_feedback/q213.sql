WITH base AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        i.i_class,
        p.p_discount_active,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        wr.wr_return_amt,
        r.r_reason_desc
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r ON r.r_reason_sk = wr.wr_reason_sk
    WHERE d.d_year = 2001
      AND i.i_class = 'furniture'
      AND s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
),
agg AS (
    SELECT
        s_store_id,
        s_store_name,
        d_year,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_net_profit) AS total_profit,
        SUM(wr_return_amt) AS total_return_amount,
        COUNT(DISTINCT r_reason_desc) AS distinct_return_reasons
    FROM base
    GROUP BY s_store_id, s_store_name, d_year
)
SELECT
    s_store_id,
    s_store_name,
    d_year,
    total_sales,
    total_profit,
    total_return_amount,
    distinct_return_reasons,
    total_profit / NULLIF(total_sales, 0) AS profit_margin,
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rn
FROM agg
WHERE total_sales > 10000
ORDER BY total_sales DESC
LIMIT 100
