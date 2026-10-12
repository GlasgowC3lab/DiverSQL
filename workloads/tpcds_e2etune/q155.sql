WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        d.d_fy_quarter_seq,
        hd.hd_income_band_sk,
        SUM(ss.ss_net_profit) AS total_sales_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    GROUP BY ss.ss_store_sk, d.d_fy_quarter_seq, hd.hd_income_band_sk
),
returns_agg AS (
    SELECT
        d.d_fy_quarter_seq,
        hd.hd_income_band_sk,
        SUM(wr.wr_net_loss) AS total_return_loss,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    GROUP BY d.d_fy_quarter_seq, hd.hd_income_band_sk
)
SELECT
    s.s_store_name,
    sa.d_fy_quarter_seq,
    sa.hd_income_band_sk,
    sa.total_sales_profit,
    COALESCE(ra.total_return_loss, 0) AS total_return_loss,
    sa.total_sales_profit - COALESCE(ra.total_return_loss, 0) AS net_margin,
    ROUND(
        (sa.total_sales_profit - COALESCE(ra.total_return_loss, 0))
        / SUM(sa.total_sales_profit - COALESCE(ra.total_return_loss, 0)) OVER (PARTITION BY sa.d_fy_quarter_seq)
        * 100,
        2
    ) AS net_margin_pct_of_quarter,
    RANK() OVER (PARTITION BY sa.d_fy_quarter_seq ORDER BY (sa.total_sales_profit - COALESCE(ra.total_return_loss, 0)) DESC) AS quarter_store_rank
FROM sales_agg sa
JOIN store s ON sa.ss_store_sk = s.s_store_sk
LEFT JOIN returns_agg ra
    ON sa.d_fy_quarter_seq = ra.d_fy_quarter_seq
    AND sa.hd_income_band_sk = ra.hd_income_band_sk
WHERE sa.total_sales_profit > 10000
ORDER BY sa.d_fy_quarter_seq, net_margin DESC
LIMIT 200
