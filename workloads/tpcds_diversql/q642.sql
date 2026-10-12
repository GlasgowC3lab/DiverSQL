WITH cs_sample AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
),

cs_join AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_coupon_amt,
        hd.hd_demo_sk,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM cs_sample cs
    LEFT JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
),

wr_join AS (
    SELECT
        wr.wr_order_number,
        wr.wr_returned_date_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss,
        wr.wr_fee,
        hd.hd_demo_sk,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM web_returns wr
    LEFT JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
),

full_combined AS (
    SELECT
        COALESCE(cs.cs_order_number, wr.wr_order_number)               AS order_number,
        COALESCE(cs.cs_sold_date_sk, wr.wr_returned_date_sk)           AS date_sk,
        cs.cs_quantity                                                AS quantity,
        cs.cs_net_paid                                                AS net_amount,
        cs.cs_net_profit                                              AS profit,
        cs.hd_demo_sk,
        cs.hd_dep_count,
        cs.hd_vehicle_count,
        cs.ib_income_band_sk,
        'sale'                                                        AS source
    FROM cs_join cs
    FULL OUTER JOIN wr_join wr
        ON cs.hd_demo_sk = wr.hd_demo_sk
    WHERE (cs.cs_quantity > 1 OR wr.wr_return_quantity > 0)
      AND (cs.cs_coupon_amt > 300 OR wr.wr_fee > 0)
      AND (cs.hd_dep_count >= 2 OR wr.hd_dep_count >= 2)
      AND (cs.hd_vehicle_count >= 0 OR wr.hd_vehicle_count >= 0)
      AND (cs.ib_lower_bound >= 60000 OR wr.ib_lower_bound >= 60000)
      AND (cs.cs_net_profit > 0 OR wr.wr_net_loss < 0)
)

SELECT
    fc.order_number,
    fc.date_sk,
    fc.quantity,
    fc.net_amount,
    fc.profit,
    CASE WHEN fc.profit > 1000 THEN 'High'
         WHEN fc.profit > 0    THEN 'Medium'
         ELSE 'Low' END                                            AS profit_category,
    ROW_NUMBER() OVER (PARTITION BY fc.ib_income_band_sk ORDER BY fc.profit DESC) AS profit_rank,
    fc.source,
    fc.profit - (SELECT AVG(cs2.cs_net_profit) FROM catalog_sales cs2) AS profit_vs_avg
FROM full_combined fc

UNION DISTINCT

SELECT
    NULL AS order_number,
    NULL AS date_sk,
    NULL AS quantity,
    NULL AS net_amount,
    SUM(profit) AS profit,
    CASE WHEN SUM(profit) > 5000 THEN 'High' ELSE 'Medium' END AS profit_category,
    NULL AS profit_rank,
    'income_band_agg' AS source,
    SUM(profit) - (SELECT AVG(cs3.cs_net_profit) FROM catalog_sales cs3) AS profit_vs_avg
FROM (
    SELECT
        cs.cs_net_profit AS profit,
        cs.ib_income_band_sk
    FROM cs_join cs
    WHERE cs.cs_quantity > 1
      AND cs.cs_coupon_amt > 300
      AND cs.hd_dep_count >= 2
      AND cs.hd_vehicle_count >= 0
      AND cs.ib_lower_bound >= 60000
      AND cs.cs_net_profit > 0
) agg

ORDER BY profit_vs_avg DESC
LIMIT 100
