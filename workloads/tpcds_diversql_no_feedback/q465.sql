WITH joined AS (
    SELECT
        d.d_year,
        cc.cc_state,
        sm.sm_code,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        cs.cs_net_profit,
        cs.cs_order_number,
        ss.ss_ext_sales_price,
        wr.wr_return_amt,
        wr.wr_return_quantity
    FROM tpcds.date_dim d
    JOIN tpcds.call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN tpcds.catalog_sales cs ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_moy = 7
      AND cc.cc_state = 'CA'
      AND cc.cc_employees > 100
      AND sm.sm_code = 'AIR'
      AND p.p_purpose = 'CLEARANCE'
      AND cs.cs_ext_sales_price > 5000
      AND wr.wr_return_quantity > 1
),
agg AS (
    SELECT
        d_year,
        cc_state,
        sm_code,
        SUM(cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT cs_order_number) AS catalog_order_cnt,
        AVG(cs_net_profit) AS avg_catalog_profit,
        MIN(wr_return_amt) AS min_return_amt,
        MAX(cs_ext_discount_amt) AS max_discount,
        SUM(CASE WHEN cs_ext_discount_amt > 1000 THEN cs_ext_sales_price ELSE 0 END) AS high_discount_sales
    FROM joined
    GROUP BY ROLLUP (d_year, cc_state, sm_code)
)
SELECT
    d_year,
    cc_state,
    sm_code,
    total_catalog_sales,
    total_store_sales,
    catalog_order_cnt,
    avg_catalog_profit,
    min_return_amt,
    max_discount,
    high_discount_sales,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_catalog_sales DESC) AS sales_rank
FROM agg
ORDER BY d_year, cc_state, sm_code
LIMIT 100
