WITH sales_agg AS (
    SELECT
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_bill_hdemo_sk AS bill_hdemo_sk,
        dd.d_year,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        CASE
            WHEN hd.hd_buy_potential = '>10000' THEN 'High'
            WHEN hd.hd_buy_potential = '0-500'  THEN 'Low'
            ELSE 'Medium'
        END AS buy_potential_category
    FROM catalog_sales cs
    JOIN date_dim dd
        ON cs.cs_sold_date_sk = dd.d_date_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_wholesale_cost > 20
      AND dd.d_year BETWEEN 2000 AND 2002
      AND hd.hd_dep_count BETWEEN 1 AND 5
    GROUP BY cs.cs_sold_date_sk, cs.cs_bill_hdemo_sk, dd.d_year, hd.hd_buy_potential
),
returns_agg AS (
    SELECT
        sr.sr_returned_date_sk AS returned_date_sk,
        sr.sr_hdemo_sk AS hdemo_sk,
        rd.d_year,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN date_dim rd
        ON sr.sr_returned_date_sk = rd.d_date_sk
    JOIN household_demographics hd2
        ON sr.sr_hdemo_sk = hd2.hd_demo_sk
    WHERE sr.sr_net_loss > 100
      AND rd.d_year BETWEEN 2000 AND 2002
      AND hd2.hd_vehicle_count > 1
      AND sr.sr_reversed_charge < 60
    GROUP BY sr.sr_returned_date_sk, sr.sr_hdemo_sk, rd.d_year
),
combined AS (
    SELECT
        s.d_year,
        s.buy_potential_category,
        s.total_sales,
        s.total_profit,
        s.sales_cnt,
        r.total_net_loss,
        r.return_cnt,
        s.sold_date_sk,
        r.returned_date_sk,
        s.bill_hdemo_sk,
        r.hdemo_sk
    FROM sales_agg s
    LEFT JOIN returns_agg r
        ON s.sold_date_sk   = r.returned_date_sk
       AND s.bill_hdemo_sk = r.hdemo_sk
       AND s.d_year        = r.d_year
)
SELECT
    c.d_year,
    c.buy_potential_category,
    c.total_sales,
    c.total_profit,
    c.sales_cnt,
    c.total_net_loss,
    c.return_cnt,
    ROW_NUMBER() OVER (PARTITION BY c.d_year ORDER BY c.total_sales DESC) AS sales_rank,
    RANK()       OVER (PARTITION BY c.buy_potential_category ORDER BY c.total_net_loss DESC) AS loss_rank
FROM combined c
CROSS JOIN (VALUES (1), (2), (3)) AS v(dummy)
WHERE c.total_sales IS NOT NULL
  AND c.total_net_loss IS NOT NULL
ORDER BY c.d_year, sales_rank
LIMIT 100
