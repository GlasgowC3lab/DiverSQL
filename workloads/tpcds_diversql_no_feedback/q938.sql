WITH
  item_sales_agg AS (
    SELECT
      ws.ws_item_sk,
      i.i_brand,
      i.i_category,
      d_sold.d_year,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      SUM(ws.ws_net_profit)       AS total_profit,
      COUNT(*)                    AS order_cnt
    FROM web_sales ws
    JOIN date_dim d_sold
      ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN item i
      ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c_bill
      ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    JOIN household_demographics hd_bill
      ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer c_ship
      ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
    JOIN household_demographics hd_ship
      ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    WHERE i.i_size = 'medium'
      AND i.i_units = 'Each'
      AND i.i_current_price BETWEEN 20 AND 80
      AND hd_bill.hd_vehicle_count >= 1
      AND d_sold.d_year = 2000
    GROUP BY ws.ws_item_sk, i.i_brand, i.i_category, d_sold.d_year
  ),
  items_2000_not_2001 AS (
    SELECT DISTINCT ws.ws_item_sk
    FROM web_sales ws
    JOIN date_dim d
      ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
    EXCEPT
    SELECT DISTINCT ws.ws_item_sk
    FROM web_sales ws
    JOIN date_dim d
      ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
  ),
  cc_dates AS (
    SELECT cc.*, d_open.d_date AS open_date, d_close.d_date AS close_date
    FROM call_center cc
    JOIN date_dim d_open
      ON cc.cc_open_date_sk = d_open.d_date_sk
    JOIN date_dim d_close
      ON cc.cc_closed_date_sk = d_close.d_date_sk
  ),
  cp_dates AS (
    SELECT cp.*, d_start.d_date AS start_date, d_end.d_date AS end_date
    FROM catalog_page cp
    JOIN date_dim d_start
      ON cp.cp_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
      ON cp.cp_end_date_sk = d_end.d_date_sk
  )
SELECT
  agg.i_brand,
  agg.i_category,
  agg.d_year,
  agg.total_sales,
  agg.total_profit,
  agg.order_cnt,
  cc.cc_name,
  cp.cp_description,
  SUM(agg.total_sales) OVER (PARTITION BY agg.i_brand ORDER BY agg.d_year
                            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_sales_brand
FROM item_sales_agg agg
JOIN items_2000_not_2001 inc
  ON agg.ws_item_sk = inc.ws_item_sk
JOIN cc_dates cc
  ON cc.cc_state = 'CA'
JOIN cp_dates cp
  ON cp.cp_department = 'Books'
WHERE cc.cc_state = 'CA'
  AND cp.cp_department = 'Books'
ORDER BY agg.i_brand, agg.d_year
