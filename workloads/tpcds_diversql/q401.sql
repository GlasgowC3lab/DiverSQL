WITH sales_agg AS (
  SELECT
    d.d_year,
    i.i_category,
    w.w_state,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt
  FROM catalog_sales cs
  JOIN date_dim d               ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i                    ON cs.cs_item_sk = i.i_item_sk
  JOIN warehouse w               ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN customer c                ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib            ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN customer_address ca       ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN promotion p               ON cs.cs_promo_sk = p.p_promo_sk
  JOIN store_sales ss            ON ss.ss_item_sk = i.i_item_sk
                                 AND ss.ss_sold_date_sk = d.d_date_sk
  JOIN inventory inv             ON inv.inv_item_sk = i.i_item_sk
                                 AND inv.inv_date_sk = d.d_date_sk
                                 AND inv.inv_warehouse_sk = w.w_warehouse_sk
  JOIN web_sales ws              ON ws.ws_item_sk = i.i_item_sk
                                 AND ws.ws_sold_date_sk = d.d_date_sk
  JOIN web_returns wr            ON wr.wr_item_sk = i.i_item_sk
                                 AND wr.wr_returned_date_sk = d.d_date_sk
                                 AND wr.wr_order_number = ws.ws_order_number
  JOIN web_page wp               ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site we               ON ws.ws_web_site_sk = we.web_site_sk
  WHERE d.d_year = 2001
    AND i.i_category = 'Sports'
    AND c.c_birth_month = 5
    AND w.w_state = 'CA'
    AND p.p_discount_active = 'Y'
    AND ib.ib_upper_bound > 50000
    AND cs.cs_ext_sales_price > (
          SELECT AVG(cs2.cs_ext_sales_price)
          FROM catalog_sales cs2
          JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
          WHERE d2.d_year = 2000
        )
  GROUP BY CUBE (d.d_year, i.i_category, w.w_state)
)
SELECT
  d_year,
  i_category,
  w_state,
  total_sales,
  order_cnt,
  ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_sales DESC) AS category_sales_rank
FROM sales_agg
ORDER BY total_sales DESC
LIMIT 100
