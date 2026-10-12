WITH
  /* Store channel data */
  store_data AS (
    SELECT
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      d.d_year,
      i.i_item_sk,
      i.i_product_name,
      ss.ss_net_profit,
      cc.cc_state,
      cp.cp_department,
      wp_date.wp_max_ad_count,
      r.r_reason_desc,
      lr.total_ret_qty,
      ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ss.ss_net_profit DESC) AS rn
    FROM store_sales ss
    JOIN date_dim d               ON ss.ss_sold_date_sk   = d.d_date_sk
    JOIN time_dim t               ON ss.ss_sold_time_sk   = t.t_time_sk
    JOIN item i                   ON ss.ss_item_sk        = i.i_item_sk
    JOIN customer c               ON ss.ss_customer_sk    = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk       = cd.cd_demo_sk
    JOIN store_returns sr         ON sr.sr_ticket_number = ss.ss_ticket_number
                                 AND sr.sr_item_sk       = ss.ss_item_sk
    JOIN reason r                 ON sr.sr_reason_sk      = r.r_reason_sk
    JOIN call_center cc           ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN catalog_page cp          ON cp.cp_end_date_sk    = d.d_date_sk
    JOIN web_page wp_date         ON wp_date.wp_creation_date_sk = d.d_date_sk
    LEFT JOIN LATERAL (
      SELECT SUM(sr2.sr_return_quantity) AS total_ret_qty
      FROM store_returns sr2
      WHERE sr2.sr_item_sk = i.i_item_sk
    ) lr ON TRUE
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND c.c_preferred_cust_flag = 'Y'
      AND cd.cd_gender = 'M'
      AND cc.cc_state = 'CA'
      AND wp_date.wp_max_ad_count >= 2
  ),

  /* Web channel data */
  web_data AS (
    SELECT
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      d.d_year,
      i.i_item_sk,
      i.i_product_name,
      ws.ws_net_profit,
      cc.cc_state,
      cp.cp_department,
      wp_date.wp_max_ad_count,
      r.r_reason_desc,
      lr.total_ret_qty,
      ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM web_sales ws
    JOIN date_dim d               ON ws.ws_sold_date_sk   = d.d_date_sk
    JOIN time_dim t               ON ws.ws_sold_time_sk   = t.t_time_sk
    JOIN item i                   ON ws.ws_item_sk        = i.i_item_sk
    JOIN customer c               ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk   = cd.cd_demo_sk
    JOIN web_returns wr          ON wr.wr_order_number = ws.ws_order_number
                                 AND wr.wr_item_sk      = ws.ws_item_sk
    JOIN reason r                 ON wr.wr_reason_sk    = r.r_reason_sk
    JOIN call_center cc           ON cc.cc_open_date_sk = d.d_date_sk
    JOIN catalog_page cp          ON cp.cp_start_date_sk = d.d_date_sk
    /* two different references to web_page – one for the date fields, one for the sales key */
    JOIN web_page wp_date         ON wp_date.wp_access_date_sk = d.d_date_sk
    JOIN web_page wp_sales        ON wp_sales.wp_web_page_sk   = ws.ws_web_page_sk
    LEFT JOIN LATERAL (
      SELECT SUM(wr2.wr_return_quantity) AS total_ret_qty
      FROM web_returns wr2
      WHERE wr2.wr_item_sk = i.i_item_sk
    ) lr ON TRUE
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND c.c_preferred_cust_flag = 'Y'
      AND cd.cd_gender = 'F'
      AND cc.cc_state = 'CA'
      AND wp_date.wp_max_ad_count >= 2
  ),

  /* Customers that appear in both channels */
  common_customers AS (
    SELECT c_customer_sk FROM store_data
    INTERSECT
    SELECT c_customer_sk FROM web_data
  ),

  /* Union of the two channel datasets (deduped) */
  combined AS (
    SELECT * FROM store_data
    UNION
    SELECT * FROM web_data
  )
SELECT
  cd.c_customer_sk,
  cd.c_first_name,
  cd.c_last_name,
  cd.d_year,
  cd.i_product_name,
  cd.r_reason_desc,
  cd.total_ret_qty,
  cd.rn
FROM combined cd
JOIN common_customers ccust ON cd.c_customer_sk = ccust.c_customer_sk
WHERE cd.rn <= 5               -- keep top‑5 rows per customer
ORDER BY cd.rn, cd.c_customer_sk
LIMIT 100
