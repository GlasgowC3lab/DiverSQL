WITH base AS (
    SELECT
        d.d_date,
        cc.cc_name,
        cp.cp_description,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_ext_sales_price,
        LAG(ss.ss_net_paid) OVER (PARTITION BY ss.ss_item_sk ORDER BY d.d_date) AS prior_net_paid
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '1900-01-01' AND DATE '1900-01-31'
      AND hd.hd_vehicle_count >= 2
      AND ib.ib_lower_bound >= 20000
      AND p.p_promo_sk IN (
          SELECT p2.p_promo_sk FROM promotion p2 WHERE p2.p_cost > 5000
      )
      AND ss.ss_quantity > (
          SELECT MAX(ss2.ss_quantity) FROM store_sales ss2 WHERE ss2.ss_quantity < 100
      )
)
SELECT
    d_date,
    cc_name,
    cp_description,
    ib_lower_bound,
    ib_upper_bound,
    SUM(ss_ext_sales_price) AS total_sales,
    AVG(ss_net_paid) AS avg_net_paid,
    COUNT(*) AS txn_count,
    MAX(prior_net_paid) AS max_prior_net_paid
FROM base
GROUP BY
    d_date,
    cc_name,
    cp_description,
    ib_lower_bound,
    ib_upper_bound
ORDER BY total_sales DESC
LIMIT 100
