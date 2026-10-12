WITH intersect_orders AS (
        SELECT cs.cs_order_number
        FROM catalog_sales cs
        JOIN store_sales ss ON ss.ss_customer_sk = cs.cs_bill_customer_sk
        WHERE cs.cs_ext_sales_price > 0
        INTERSECT
        SELECT cr.cr_order_number
        FROM catalog_returns cr
        WHERE cr.cr_return_amount = 0
    )
SELECT
    d_sold.d_year,
    s.s_store_name,
    p.p_promo_name,
    cd_bill.cd_gender,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(cs.cs_ext_sales_price)          AS total_catalog_sales,
    SUM(ss.ss_ext_sales_price)          AS total_store_sales,
    COUNT(DISTINCT c_bill.c_customer_sk) AS distinct_customers
FROM catalog_sales cs
JOIN date_dim d_sold        ON cs.cs_sold_date_sk   = d_sold.d_date_sk
JOIN time_dim t_sold        ON cs.cs_sold_time_sk   = t_sold.t_time_sk
JOIN customer c_bill        ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer_address ca_bill ON cs.cs_bill_addr_sk   = ca_bill.ca_address_sk
JOIN promotion p            ON cs.cs_promo_sk       = p.p_promo_sk
JOIN catalog_returns cr    ON cr.cr_order_number   = cs.cs_order_number
JOIN date_dim d_return      ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN time_dim t_return      ON cr.cr_returned_time_sk = t_return.t_time_sk
JOIN web_returns wr        ON wr.wr_refunded_customer_sk = c_bill.c_customer_sk
JOIN date_dim d_wr_return   ON wr.wr_returned_date_sk = d_wr_return.d_date_sk
JOIN time_dim t_wr_return   ON wr.wr_returned_time_sk = t_wr_return.t_time_sk
JOIN store_sales ss        ON ss.ss_customer_sk = c_bill.c_customer_sk
JOIN store s               ON ss.ss_store_sk     = s.s_store_sk
JOIN household_demographics hd_store ON ss.ss_hdemo_sk = hd_store.hd_demo_sk
JOIN income_band ib        ON hd_store.hd_income_band_sk = ib.ib_income_band_sk
JOIN promotion p2           ON ss.ss_promo_sk = p2.p_promo_sk
WHERE cs.cs_order_number IN (SELECT cs_order_number FROM intersect_orders)
  AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_order_number = cs.cs_order_number
          AND cr2.cr_return_amount > 0
      )
GROUP BY
    d_sold.d_year,
    s.s_store_name,
    p.p_promo_name,
    cd_bill.cd_gender,
    ib.ib_lower_bound,
    ib.ib_upper_bound
ORDER BY d_sold.d_year DESC, total_catalog_sales DESC
LIMIT 100
