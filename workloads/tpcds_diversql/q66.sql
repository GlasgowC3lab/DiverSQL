WITH
  intersect_set AS (
    SELECT cs_order_number AS order_number
    FROM catalog_sales
    WHERE cs_quantity > 5
    INTERSECT
    SELECT ws_order_number
    FROM web_sales
    WHERE ws_quantity > 5
  ),
  base AS (
    SELECT
      i.i_category,
      i.i_class,
      cs.cs_net_paid,
      ss.ss_net_paid,
      ws.ws_net_paid,
      cr.cr_net_loss,
      wr.wr_net_loss,
      d1.d_year,
      p.p_channel_press,
      w.w_state
    FROM item i
    JOIN catalog_sales cs               ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_page cp                ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN catalog_returns cr            ON cr.cr_order_number = cs.cs_order_number
                                       AND cr.cr_item_sk = i.i_item_sk
    JOIN store_sales ss                ON ss.ss_item_sk = i.i_item_sk
    JOIN web_sales ws                  ON ws.ws_item_sk = i.i_item_sk
    JOIN web_returns wr                ON wr.wr_order_number = ws.ws_order_number
                                       AND wr.wr_item_sk = i.i_item_sk
    JOIN promotion p                    ON p.p_item_sk = i.i_item_sk
    JOIN ship_mode sm                   ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
    JOIN warehouse w                    ON w.w_warehouse_sk = cs.cs_warehouse_sk
    JOIN customer_address ca            ON ca.ca_address_sk = cs.cs_bill_addr_sk
    JOIN household_demographics hd      ON hd.hd_demo_sk = cs.cs_bill_hdemo_sk
    JOIN income_band ib                 ON ib.ib_income_band_sk = hd.hd_income_band_sk
    JOIN date_dim d1                    ON d1.d_date_sk = cs.cs_sold_date_sk
    JOIN date_dim d2                    ON d2.d_date_sk = cr.cr_returned_date_sk
    JOIN date_dim d3                    ON d3.d_date_sk = ss.ss_sold_date_sk
    JOIN date_dim d4                    ON d4.d_date_sk = ws.ws_sold_date_sk
    JOIN date_dim d5                    ON d5.d_date_sk = wr.wr_returned_date_sk
    JOIN time_dim t1                    ON t1.t_time_sk = cs.cs_sold_time_sk
    JOIN time_dim t2                    ON t2.t_time_sk = cr.cr_returned_time_sk
    JOIN time_dim t3                    ON t3.t_time_sk = ss.ss_sold_time_sk
    JOIN time_dim t4                    ON t4.t_time_sk = ws.ws_sold_time_sk
    JOIN time_dim t5                    ON t5.t_time_sk = wr.wr_returned_time_sk
    JOIN web_site wsit                  ON wsit.web_site_sk = ws.ws_web_site_sk
    WHERE d1.d_year = 2001
      AND p.p_channel_press = 'N'
      AND w.w_state = 'CA'
      AND EXISTS (SELECT 1 FROM intersect_set i WHERE i.order_number = cs.cs_order_number)
  ),
  agg AS (
    SELECT
      i_category,
      i_class,
      SUM(cs_net_paid)          AS catalog_sales,
      SUM(ss_net_paid)          AS store_sales,
      SUM(ws_net_paid)          AS web_sales,
      SUM(cr_net_loss)          AS catalog_return_loss,
      SUM(wr_net_loss)          AS web_return_loss
    FROM base
    GROUP BY ROLLUP (i_category, i_class)
  )
SELECT
  i_category,
  i_class,
  catalog_sales,
  store_sales,
  web_sales,
  catalog_return_loss,
  web_return_loss,
  ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY catalog_sales DESC) AS rn_category
FROM agg
ORDER BY i_category, i_class
LIMIT 100
