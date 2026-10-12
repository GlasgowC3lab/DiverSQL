WITH cs_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    GROUP BY cs.cs_item_sk, cs.cs_sold_date_sk
)
SELECT
    d.d_year,
    i.i_category,
    i.i_brand,
    SUM(cs_agg.total_net_paid) AS total_net_paid,
    SUM(COALESCE(cr.cr_return_amount, 0)) AS total_catalog_return_amount,
    SUM(COALESCE(sr.sr_return_amt, 0)) AS total_store_return_amt,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_web_return_amt,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
    AVG(ib.ib_lower_bound) AS avg_income_lower_bound
FROM cs_agg
JOIN catalog_sales cs
  ON cs.cs_item_sk = cs_agg.cs_item_sk
 AND cs.cs_sold_date_sk = cs_agg.cs_sold_date_sk
JOIN date_dim d
  ON d.d_date_sk = cs_agg.cs_sold_date_sk
JOIN item i
  ON i.i_item_sk = cs_agg.cs_item_sk
JOIN warehouse w
  ON w.w_warehouse_sk = cs.cs_warehouse_sk
JOIN call_center cc
  ON cc.cc_call_center_sk = cs.cs_call_center_sk
JOIN catalog_page cp
  ON cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
JOIN ship_mode sm
  ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
JOIN customer c
  ON c.c_customer_sk = cs.cs_bill_customer_sk
JOIN customer_demographics cd
  ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
JOIN household_demographics hd
  ON hd.hd_demo_sk = cs.cs_bill_hdemo_sk
JOIN income_band ib
  ON ib.ib_income_band_sk = hd.hd_income_band_sk
JOIN customer_address ca
  ON ca.ca_address_sk = cs.cs_bill_addr_sk
LEFT JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
 AND cr.cr_item_sk = cs.cs_item_sk
LEFT JOIN store_returns sr
  ON sr.sr_item_sk = i.i_item_sk
 AND sr.sr_returned_date_sk = d.d_date_sk
LEFT JOIN web_returns wr
  ON wr.wr_item_sk = i.i_item_sk
 AND wr.wr_returned_date_sk = d.d_date_sk
LEFT JOIN reason r
  ON r.r_reason_sk = COALESCE(cr.cr_reason_sk, sr.sr_reason_sk, wr.wr_reason_sk)
WHERE d.d_year = 2001
  AND i.i_brand = 'Brand#12'
  AND cc.cc_state = 'CA'
  AND EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_refunded_customer_sk = c.c_customer_sk
          AND wr2.wr_returned_date_sk = d.d_date_sk
    )
GROUP BY d.d_year, i.i_category, i.i_brand
ORDER BY total_net_paid DESC
LIMIT 100
