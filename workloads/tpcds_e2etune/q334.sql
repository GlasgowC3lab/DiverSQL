WITH catalog_agg AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_vehicle_count,
        w.w_city,
        w.w_state,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(*) AS catalog_txn_cnt
    FROM catalog_sales cs
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2453650
      AND cs.cs_net_paid > 1000.00
    GROUP BY hd.hd_demo_sk, hd.hd_income_band_sk, hd.hd_vehicle_count, w.w_city, w.w_state
),
store_agg AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_vehicle_count,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_ext_sales_price) AS store_sales,
        COUNT(*) AS store_txn_cnt
    FROM store_sales ss
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2453650
      AND ss.ss_ext_sales_price > 500.00
    GROUP BY hd.hd_demo_sk, hd.hd_income_band_sk, hd.hd_vehicle_count
),
returns_agg AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_vehicle_count,
        SUM(wr.wr_net_loss) AS total_return_loss,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450000 AND 2453650
      AND wr.wr_return_amt > 0.00
    GROUP BY hd.hd_demo_sk, hd.hd_income_band_sk, hd.hd_vehicle_count
)
SELECT
    ca.hd_income_band_sk,
    ca.hd_vehicle_count,
    ca.w_city,
    ca.w_state,
    ca.total_sales + COALESCE(sa.store_sales, 0) AS gross_sales,
    ca.total_net_profit + COALESCE(sa.store_net_profit, 0) AS gross_profit,
    COALESCE(ra.total_return_loss, 0) AS total_return_loss,
    (ca.total_net_profit + COALESCE(sa.store_net_profit, 0) - COALESCE(ra.total_return_loss, 0)) AS net_profit_after_returns,
    ((ca.total_net_profit + COALESCE(sa.store_net_profit, 0) - COALESCE(ra.total_return_loss, 0))
        / NULLIF(ca.total_sales + COALESCE(sa.store_sales, 0), 0)) * 100 AS profit_margin_pct,
    ca.catalog_txn_cnt,
    COALESCE(sa.store_txn_cnt, 0) AS store_txn_cnt,
    COALESCE(ra.return_cnt, 0) AS return_cnt
FROM catalog_agg ca
LEFT JOIN store_agg sa
    ON ca.hd_demo_sk = sa.hd_demo_sk
   AND ca.hd_income_band_sk = sa.hd_income_band_sk
   AND ca.hd_vehicle_count = sa.hd_vehicle_count
LEFT JOIN returns_agg ra
    ON ca.hd_demo_sk = ra.hd_demo_sk
   AND ca.hd_income_band_sk = ra.hd_income_band_sk
   AND ca.hd_vehicle_count = ra.hd_vehicle_count
ORDER BY net_profit_after_returns DESC
LIMIT 10
