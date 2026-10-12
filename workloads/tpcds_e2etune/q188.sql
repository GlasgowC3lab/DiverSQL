WITH sales_agg AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        d_sales.d_year,
        d_sales.d_month_seq,
        SUM(cs.cs_net_profit) AS total_sales_profit,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN date_dim d_sales ON cs.cs_sold_date_sk = d_sales.d_date_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_income_band_sk > 5
      AND d_sales.d_year = 2020
      AND d_sales.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    GROUP BY p.p_promo_sk, p.p_promo_name, d_sales.d_year, d_sales.d_month_seq
),
returns_agg AS (
    SELECT
        p.p_promo_sk,
        d_ret.d_year,
        d_ret.d_month_seq,
        SUM(wr.wr_net_loss) AS total_return_loss,
        COUNT(*) AS returns_cnt
    FROM web_returns wr
    JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN item i_ret ON wr.wr_item_sk = i_ret.i_item_sk
    JOIN promotion p ON i_ret.i_item_sk = p.p_item_sk
    WHERE d_ret.d_year = 2020
      AND d_ret.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    GROUP BY p.p_promo_sk, d_ret.d_year, d_ret.d_month_seq
)
SELECT
    s.p_promo_name,
    s.d_year,
    s.d_month_seq,
    s.total_sales_profit,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    s.total_sales_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns,
    s.total_discount,
    s.sales_cnt,
    COALESCE(r.returns_cnt, 0) AS returns_cnt,
    (s.total_sales_profit - COALESCE(r.total_return_loss, 0)) / NULLIF(s.sales_cnt, 0) AS avg_profit_per_sale
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.p_promo_sk = r.p_promo_sk
   AND s.d_year = r.d_year
   AND s.d_month_seq = r.d_month_seq
WHERE (s.total_sales_profit - COALESCE(r.total_return_loss, 0)) > 10000
ORDER BY net_profit_after_returns DESC
LIMIT 10
