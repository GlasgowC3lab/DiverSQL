WITH cs_base AS (
    SELECT
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_bill_cdemo_sk,
        cd.cd_demo_sk AS cd_demo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_sold_date_sk,
        cd.cd_gender,
        hd.hd_income_band_sk,
        d.d_year,
        d.d_date
    FROM catalog_sales cs
    RIGHT OUTER JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1915 AND 1919
      AND cs.cs_ext_sales_price > 100
      AND cd.cd_credit_rating = 'Excellent'
),
cs_agg AS (
    SELECT
        cd_demo_sk,
        d_year,
        SUM(cs_ext_sales_price) AS sum_sales,
        SUM(cs_net_profit) AS sum_profit
    FROM cs_base
    GROUP BY cd_demo_sk, d_year
),
sr_base AS (
    SELECT
        sr.sr_return_amt,
        sr.sr_net_loss,
        sr.sr_cdemo_sk AS sr_cdemo_sk,
        sr.sr_hdemo_sk,
        sr.sr_returned_date_sk,
        r.r_reason_desc,
        cd2.cd_gender,
        hd2.hd_income_band_sk,
        d2.d_year,
        d2.d_date
    FROM store_returns sr
    LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN customer_demographics cd2
        ON sr.sr_cdemo_sk = cd2.cd_demo_sk
    LEFT JOIN household_demographics hd2
        ON sr.sr_hdemo_sk = hd2.hd_demo_sk
    LEFT JOIN date_dim d2
        ON sr.sr_returned_date_sk = d2.d_date_sk
    WHERE d2.d_year BETWEEN 1915 AND 1919
      AND sr.sr_return_amt > 50
      AND r.r_reason_desc LIKE '%price%'
),
sr_agg AS (
    SELECT
        sr_cdemo_sk,
        d_year,
        SUM(sr_return_amt) AS sum_returns,
        SUM(sr_net_loss) AS sum_loss
    FROM sr_base
    GROUP BY sr_cdemo_sk, d_year
),
combined AS (
    SELECT
        COALESCE(cs.cd_demo_sk, sr.sr_cdemo_sk) AS demo_sk,
        COALESCE(cs.d_year, sr.d_year) AS year,
        COALESCE(cs.sum_sales, 0) - COALESCE(sr.sum_returns, 0) AS net_amount,
        CASE
            WHEN cs.cd_demo_sk IS NOT NULL AND sr.sr_cdemo_sk IS NULL THEN 'Sale Only'
            WHEN cs.cd_demo_sk IS NULL AND sr.sr_cdemo_sk IS NOT NULL THEN 'Return Only'
            WHEN cs.cd_demo_sk IS NOT NULL AND sr.sr_cdemo_sk IS NOT NULL THEN 'Both'
            ELSE 'None'
        END AS record_type,
        COALESCE(cs.sum_profit, 0) - COALESCE(sr.sum_loss, 0) AS net_profit
    FROM cs_agg cs
    FULL OUTER JOIN sr_agg sr
        ON cs.cd_demo_sk = sr.sr_cdemo_sk
       AND cs.d_year = sr.d_year
)
SELECT
    year,
    record_type,
    SUM(net_amount) AS total_net_amount,
    AVG(net_profit) AS avg_net_profit,
    COUNT(*) AS groups_cnt
FROM combined
WHERE year IS NOT NULL
GROUP BY year, record_type
HAVING SUM(net_amount) > 1000
ORDER BY year DESC, total_net_amount DESC
LIMIT 100
