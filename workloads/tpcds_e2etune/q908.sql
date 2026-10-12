WITH sales_agg AS (
    SELECT
        d.d_fy_quarter_seq AS quarter_seq,
        cd.cd_gender AS gender,
        SUM(ss.ss_net_profit) AS total_sales_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    INNER JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    INNER JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_fy_year = 2020
      AND cd.cd_credit_rating = 'Good'
      AND cd.cd_purchase_estimate > 1500
    GROUP BY d.d_fy_quarter_seq, cd.cd_gender
),
returns_agg AS (
    SELECT
        d.d_fy_quarter_seq AS quarter_seq,
        cd.cd_gender AS gender,
        SUM(sr.sr_net_loss) AS total_return_loss,
        COUNT(*) AS returns_cnt
    FROM store_returns sr
    INNER JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    INNER JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_fy_year = 2020
      AND cd.cd_credit_rating = 'Good'
      AND cd.cd_purchase_estimate > 1500
    GROUP BY d.d_fy_quarter_seq, cd.cd_gender
)
SELECT
    s.quarter_seq,
    s.gender,
    s.total_sales_profit,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    s.total_sales_profit - COALESCE(r.total_return_loss, 0) AS net_margin,
    s.sales_cnt,
    COALESCE(r.returns_cnt, 0) AS returns_cnt
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.quarter_seq = r.quarter_seq
   AND s.gender = r.gender
WHERE (s.total_sales_profit - COALESCE(r.total_return_loss, 0)) > 0
ORDER BY net_margin DESC
LIMIT 5
