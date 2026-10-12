-- Goal: Identify high‑value web sales by customer, item and warehouse, showing subtotals and a grand total, ranking warehouses, and demonstrating set operations, sampling, and a full outer join.
WITH
  -- Sample a fraction of the web_sales fact table
  sample_ws AS (
    SELECT *
    FROM web_sales TABLESAMPLE BERNOULLI (10)  -- approx 10% random rows
  ),

  -- Build a left‑deep chain joining all required tables
  base_join AS (
    SELECT
      ws.ws_order_number,
      ws.ws_sold_time_sk,
      ws.ws_item_sk,
      ws.ws_bill_customer_sk,
      ws.ws_bill_hdemo_sk,
      ws.ws_ship_mode_sk,
      ws.ws_warehouse_sk,
      ws.ws_promo_sk,
      ws.ws_web_site_sk,
      ws.ws_net_paid,
      ws.ws_ext_discount_amt,
      ws.ws_net_profit,
      ws.ws_quantity,
      td.t_hour,
      td.t_minute,
      i.i_item_id,
      i.i_current_price,
      c.c_customer_id,
      hd.hd_income_band_sk,
      p.p_discount_active,
      w.w_state,
      site.web_country,
      ib.ib_lower_bound,
      ib.ib_upper_bound
    FROM sample_ws ws
    JOIN time_dim td          ON ws.ws_sold_time_sk   = td.t_time_sk
    JOIN item i               ON ws.ws_item_sk        = i.i_item_sk
    JOIN customer c           ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p          ON ws.ws_promo_sk       = p.p_promo_sk
    JOIN warehouse w          ON ws.ws_warehouse_sk   = w.w_warehouse_sk
    JOIN ship_mode sm         ON ws.ws_ship_mode_sk   = sm.sm_ship_mode_sk
    JOIN web_site site        ON ws.ws_web_site_sk    = site.web_site_sk
    JOIN income_band ib       ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE td.t_hour = 10                     -- selective time filter
      AND td.t_minute = 5                    -- another time filter
      AND i.i_current_price > 100            -- price filter
      AND w.w_state = 'CA'                   -- warehouse location filter
      AND p.p_discount_active = 'Y'          -- promotion active filter
      AND site.web_country = 'United States'-- website country filter
  ),

  -- Join web_returns and reason (left join to keep sales without returns)
  sales_returns AS (
    SELECT
      bj.*,
      wr.wr_return_quantity,
      wr.wr_return_amt,
      wr.wr_reason_sk,
      r.r_reason_desc
    FROM base_join bj
    LEFT JOIN web_returns wr ON bj.ws_order_number = wr.wr_order_number
                               AND bj.ws_item_sk   = wr.wr_item_sk
    LEFT JOIN reason r       ON wr.wr_reason_sk = r.r_reason_sk
  ),

  -- Set operation: orders that appear in both sales and returns (INTERSECT)
  intersect_orders AS (
    SELECT ws_order_number AS order_key
    FROM web_sales
    WHERE ws_quantity > 5
    INTERSECT
    SELECT wr_order_number
    FROM web_returns
    WHERE wr_return_quantity > 0
  ),

  -- Set operation: orders in sales but not in returns (EXCEPT)
  except_orders AS (
    SELECT ws_order_number AS order_key
    FROM web_sales
    WHERE ws_quantity > 5
    EXCEPT
    SELECT wr_order_number
    FROM web_returns
    WHERE wr_return_quantity = 0
  ),

  -- Aggregate with ROLLUP and a ranking window function
  agg_rollup AS (
    SELECT
      c.c_customer_id,
      i.i_item_id,
      w.w_warehouse_name,
      r.r_reason_desc,
      SUM(sr.ws_net_paid)            AS total_net_paid,
      AVG(sr.ws_ext_discount_amt)    AS avg_discount,
      COUNT(DISTINCT sr.ws_order_number) AS distinct_orders,
      MIN(sr.ws_net_profit)          AS min_profit,
      MAX(sr.ws_net_profit)          AS max_profit,
      MAX(sr.ws_order_number)        AS sample_order_number,
      ROW_NUMBER() OVER (
        PARTITION BY w.w_warehouse_name
        ORDER BY SUM(sr.ws_net_paid) DESC
      )                              AS warehouse_sales_rank
    FROM sales_returns sr
    JOIN customer c      ON sr.ws_bill_customer_sk = c.c_customer_sk
    JOIN item i          ON sr.ws_item_sk = i.i_item_sk
    JOIN warehouse w     ON sr.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN reason r   ON sr.wr_reason_sk = r.r_reason_sk
    GROUP BY ROLLUP (c.c_customer_id, i.i_item_id, w.w_warehouse_name, r.r_reason_desc)
  ),

  -- Preferred customers for a full outer join
  preferred_customers AS (
    SELECT c.c_customer_id, c.c_email_address
    FROM customer c
    WHERE c.c_preferred_cust_flag = 'Y'
  )

SELECT
  ar.*,                     -- all aggregated columns
  pc.c_email_address        -- email when the customer is preferred (may be NULL)
FROM agg_rollup ar
FULL OUTER JOIN preferred_customers pc
  ON ar.c_customer_id = pc.c_customer_id
WHERE ar.total_net_paid > 1000                     -- keep only high‑value aggregates
  AND ar.sample_order_number IN (SELECT order_key FROM intersect_orders)   -- intersect set filter
  AND ar.sample_order_number NOT IN (SELECT order_key FROM except_orders)   -- except set filter
LIMIT 100
