WITH sales_agg AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_education_status,
        cd.cd_gender,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating = 'Good'
      AND cd.cd_gender = 'F'
      AND ss.ss_quantity > 1
    GROUP BY cd.cd_demo_sk, cd.cd_education_status, cd.cd_gender
),
returns_agg AS (
    SELECT
        cd.cd_demo_sk,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(*) AS returns_cnt
    FROM web_returns wr
    JOIN customer_demographics cd
        ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating = 'Good'
      AND cd.cd_gender = 'F'
    GROUP BY cd.cd_demo_sk
)
SELECT
    s.cd_education_status,
    s.cd_gender,
    s.total_profit,
    COALESCE(r.total_return_amt, 0) AS total_return_amt,
    s.sales_cnt,
    COALESCE(r.returns_cnt, 0) AS returns_cnt,
    (s.total_profit - COALESCE(r.total_return_amt, 0)) AS net_contribution,
    RANK() OVER (ORDER BY (s.total_profit - COALESCE(r.total_return_amt, 0)) DESC) AS net_rank
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.cd_demo_sk = r.cd_demo_sk
WHERE s.total_profit > 1000
ORDER BY net_contribution DESC
LIMIT 20
