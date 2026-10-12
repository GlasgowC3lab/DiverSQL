WITH joined AS (
   SELECT
       d.d_year,
       cc.cc_state,
       i.i_brand,
       hd.hd_income_band_sk,
       ss.ss_ticket_number,
       ss.ss_sales_price,
       ss.ss_ext_sales_price,
       ss.ss_net_profit,
       sr.sr_return_amt,
       cr.cr_return_amount,
       wr.wr_return_amt,
       t.t_hour
   FROM tpcds.date_dim d
   JOIN tpcds.call_center cc
     ON cc.cc_open_date_sk = d.d_date_sk
   JOIN tpcds.catalog_page cp
     ON cp.cp_start_date_sk = d.d_date_sk
   JOIN tpcds.web_page wp
     ON wp.wp_creation_date_sk = d.d_date_sk
   JOIN tpcds.promotion p
     ON p.p_start_date_sk = d.d_date_sk
   JOIN tpcds.customer c
     ON c.c_first_sales_date_sk = d.d_date_sk
   JOIN tpcds.household_demographics hd
     ON c.c_current_hdemo_sk = hd.hd_demo_sk
   JOIN tpcds.item i
     ON p.p_item_sk = i.i_item_sk
   JOIN tpcds.store_sales ss
     ON ss.ss_customer_sk = c.c_customer_sk
        AND ss.ss_item_sk = i.i_item_sk
        AND ss.ss_sold_date_sk = d.d_date_sk
   JOIN tpcds.time_dim t
     ON ss.ss_sold_time_sk = t.t_time_sk
   JOIN tpcds.store_returns sr
     ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = i.i_item_sk
        AND sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_returned_date_sk = d.d_date_sk
   JOIN tpcds.catalog_returns cr
     ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_item_sk = i.i_item_sk
        AND cr.cr_refunded_customer_sk = c.c_customer_sk
        AND cr.cr_call_center_sk = cc.cc_call_center_sk
        AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN tpcds.warehouse w
     ON w.w_warehouse_sk = cr.cr_warehouse_sk
   JOIN tpcds.web_returns wr
     ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_item_sk = i.i_item_sk
        AND wr.wr_refunded_customer_sk = c.c_customer_sk
        AND wr.wr_web_page_sk = wp.wp_web_page_sk
        AND wr.wr_returned_time_sk = t.t_time_sk
)
SELECT
    d_year,
    cc_state,
    i_brand,
    hd_income_band_sk,
    COUNT(DISTINCT ss_ticket_number) AS num_sales,
    SUM(ss_ext_sales_price) AS total_sales,
    AVG(ss_sales_price) AS avg_sales_price,
    SUM(sr_return_amt) AS total_store_returns,
    SUM(cr_return_amount) AS total_catalog_returns,
    SUM(wr_return_amt) AS total_web_returns,
    (SUM(ss_net_profit) - (SUM(sr_return_amt) + SUM(cr_return_amount) + SUM(wr_return_amt))) AS net_profit_after_returns,
    MIN(ss_sales_price) AS min_sales_price,
    MAX(ss_sales_price) AS max_sales_price
FROM joined
WHERE d_year = 2001
  AND cc_state = 'CA'
  AND i_brand = 'Brand#45'
  AND hd_income_band_sk = 5
  AND t_hour BETWEEN 9 AND 17
  AND ss_sales_price > 30.00
GROUP BY d_year, cc_state, i_brand, hd_income_band_sk
ORDER BY total_sales DESC
LIMIT 100
