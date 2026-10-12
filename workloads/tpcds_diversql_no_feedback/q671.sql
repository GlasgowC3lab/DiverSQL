WITH agg_returns AS (
    SELECT
        sr_customer_sk,
        sr_hdemo_sk,
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM store_returns
    WHERE sr_return_quantity > 0
      AND sr_return_amt > 0
    GROUP BY sr_customer_sk, sr_hdemo_sk
),
joined_data AS (
    SELECT
        c.c_customer_id,
        c.c_birth_year,
        sm.sm_carrier,
        sm.sm_code,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_vehicle_count,
        ws.ws_ext_list_price,
        ws.ws_net_paid_inc_tax,
        ar.total_return_amt,
        CASE
            WHEN ar.total_return_amt > 1000 THEN 'High'
            WHEN ar.total_return_amt > 500 THEN 'Medium'
            ELSE 'Low'
        END AS return_level,
        wp.wp_image_count
    FROM agg_returns ar
    JOIN customer c
        ON c.c_customer_sk = ar.sr_customer_sk
    JOIN household_demographics hd
        ON hd.hd_demo_sk = ar.sr_hdemo_sk
    JOIN income_band ib
        ON ib.ib_income_band_sk = hd.hd_income_band_sk
    JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN ship_mode sm
        ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
    JOIN web_page wp
        ON wp.wp_web_page_sk = ws.ws_web_page_sk
    WHERE sm.sm_carrier IN ('UPS', 'USPS', 'ORIENTAL')
      AND sm.sm_code = 'AIR'
      AND wp.wp_image_count >= 4
      AND ws.ws_ext_list_price > 5000
      AND ib.ib_lower_bound >= 50000
      AND c.c_birth_year BETWEEN 1950 AND 1970
      AND hd.hd_vehicle_count <= 2
),
cube_agg AS (
    SELECT
        sm_carrier,
        ib_income_band_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        SUM(total_return_amt) AS total_returns,
        COUNT(DISTINCT c_customer_id) AS distinct_customers,
        COUNT(*) AS rows_cnt
    FROM joined_data
    GROUP BY CUBE(sm_carrier, ib_income_band_sk)
)
SELECT
    DISTINCT sm_carrier,
    ib_income_band_sk,
    total_sales,
    total_returns,
    distinct_customers,
    rows_cnt,
    ROW_NUMBER() OVER (PARTITION BY sm_carrier ORDER BY total_sales DESC) AS carrier_sales_rank,
    CASE
        WHEN total_sales > 100000 THEN 'Tier1'
        WHEN total_sales > 50000 THEN 'Tier2'
        ELSE 'Tier3'
    END AS sales_tier
FROM cube_agg
WHERE (sm_carrier IS NOT NULL OR ib_income_band_sk IS NOT NULL)
ORDER BY carrier_sales_rank
LIMIT 100
