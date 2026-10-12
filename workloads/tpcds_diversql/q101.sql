WITH
  /* Sample a fraction of catalog_sales */
  sales_sample AS (
    SELECT *
    FROM catalog_sales TABLESAMPLE BERNOULLI (10)
    WHERE cs_net_paid_inc_tax > 1000
  ),
  /* Deep left‑deep chain joining all 16 tables. Some dimensions are joined twice under different aliases. */
  joined_all AS (
    SELECT
      cs.cs_order_number,
      cs.cs_net_paid_inc_tax,
      cs.cs_ext_discount_amt,
      d_sales.d_year,
      d_ship.d_week_seq,
      i.i_category,
      i.i_item_id,
      cp.cp_type,
      cc.cc_name,
      sm.sm_type,
      w.w_warehouse_name,
      ca.ca_state,
      c.c_customer_id,
      hd.hd_income_band_sk,
      ss.ss_net_profit,
      ws.ws_net_paid,
      cr.cr_net_loss
    FROM sales_sample cs
    /* 1 */ JOIN date_dim d_sales      ON cs.cs_sold_date_sk   = d_sales.d_date_sk
    /* 2 */ JOIN time_dim t_sold      ON cs.cs_sold_time_sk   = t_sold.t_time_sk
    /* 3 */ JOIN item i               ON cs.cs_item_sk        = i.i_item_sk
    /* 4 */ JOIN catalog_page cp      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    /* 5 */ JOIN call_center cc       ON cs.cs_call_center_sk = cc.cc_call_center_sk
    /* 6 */ JOIN ship_mode sm         ON cs.cs_ship_mode_sk   = sm.sm_ship_mode_sk
    /* 7 */ JOIN warehouse w          ON cs.cs_warehouse_sk   = w.w_warehouse_sk
    /* 8 */ JOIN customer c           ON cs.cs_bill_customer_sk = c.c_customer_sk
    /* 9 */ JOIN customer_address ca  ON cs.cs_bill_addr_sk   = ca.ca_address_sk
    /*10 */ JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    /*11 */ JOIN date_dim d_ship      ON cs.cs_ship_date_sk   = d_ship.d_date_sk  -- second alias of date_dim
    /*12 */ JOIN store_sales ss       ON ss.ss_item_sk        = cs.cs_item_sk
                                  AND ss.ss_sold_date_sk   = d_sales.d_date_sk
    /*13 */ JOIN store_returns sr     ON sr.sr_ticket_number  = ss.ss_ticket_number
    /*14 */ JOIN web_sales ws         ON ws.ws_item_sk        = cs.cs_item_sk
                                  AND ws.ws_sold_date_sk   = d_sales.d_date_sk
    /*15 */ JOIN catalog_returns cr   ON cr.cr_order_number   = cs.cs_order_number
    WHERE d_sales.d_year = 2001
  ),
  /* First sub‑query for UNION */
  union_part_a AS (
    SELECT c_customer_id AS cust_id
    FROM joined_all
    WHERE cs_net_paid_inc_tax > 2000
  ),
  /* Second sub‑query for UNION */
  union_part_b AS (
    SELECT c_customer_id AS cust_id
    FROM joined_all
    WHERE cs_ext_discount_amt > 0
  ),
  /* UNION (distinct) of the two sets */
  union_set AS (
    SELECT cust_id FROM union_part_a
    UNION
    SELECT cust_id FROM union_part_b
  ),
  /* INTERSECT of two key sets */
  intersect_set AS (
    SELECT cust_id FROM union_set
    INTERSECT
    SELECT c_customer_id FROM joined_all WHERE i_category = 'Women'
  )
SELECT
  d_year,
  i_category,
  COUNT(DISTINCT intersect_set.cust_id)               AS distinct_customers,
  SUM(cs_net_paid_inc_tax)                           AS total_net_paid,
  AVG(ss_net_profit)                                 AS avg_store_profit
FROM joined_all
JOIN intersect_set ON joined_all.c_customer_id = intersect_set.cust_id
GROUP BY d_year, i_category
ORDER BY total_net_paid DESC
LIMIT 100
