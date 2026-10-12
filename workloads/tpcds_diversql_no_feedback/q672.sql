WITH sales_agg AS (
   SELECT
      cs.cs_item_sk,
      i.i_category        AS i_category,
      i.i_brand           AS i_brand,
      d.ib_income_band_sk AS income_band_sk,
      d.ib_lower_bound   AS income_lower,
      d.ib_upper_bound   AS income_upper,
      cs.cs_sold_date_sk,
      cs.cs_sold_time_sk,
      t.t_hour,
      SUM(cs.cs_ext_sales_price)           AS sum_sales,
      AVG(cs.cs_sales_price)               AS avg_sales_price,
      COUNT(*)                             AS cnt_sales,
      MAX(cs.cs_ext_sales_price)           AS max_sale,
      MIN(cs.cs_ext_sales_price)           AS min_sale,
      CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END AS promo_active_flag
   FROM catalog_sales cs
   JOIN item i               ON cs.cs_item_sk = i.i_item_sk
   JOIN promotion p          ON cs.cs_promo_sk = p.p_promo_sk
   JOIN time_dim t           ON cs.cs_sold_time_sk = t.t_time_sk
   JOIN customer_address ca  ON cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN income_band d        ON hd.hd_income_band_sk = d.ib_income_band_sk
   WHERE cs.cs_quantity > 1
     AND cs.cs_ext_sales_price > 100
     AND i.i_current_price BETWEEN 10 AND 500
     AND p.p_cost < 1000
     AND ca.ca_state = 'CA'
     AND t.t_hour BETWEEN 8 AND 18
     AND hd.hd_dep_count <= 2
   GROUP BY
      cs.cs_item_sk,
      i.i_category,
      i.i_brand,
      d.ib_income_band_sk,
      d.ib_lower_bound,
      d.ib_upper_bound,
      cs.cs_sold_date_sk,
      cs.cs_sold_time_sk,
      t.t_hour,
      p.p_discount_active
),
returns_agg AS (
   SELECT
      sr.sr_item_sk,
      SUM(sr.sr_return_amt) AS sum_store_return,
      COUNT(*)               AS cnt_store_return,
      MAX(sr.sr_return_amt) AS max_store_return
   FROM store_returns sr
   JOIN time_dim t      ON sr.sr_return_time_sk = t.t_time_sk
   JOIN item i          ON sr.sr_item_sk = i.i_item_sk
   JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
   JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
   WHERE t.t_hour BETWEEN 8 AND 18
     AND i.i_current_price BETWEEN 10 AND 500
     AND ca.ca_state = 'CA'
     AND hd.hd_dep_count <= 2
   GROUP BY sr.sr_item_sk
),
web_sales_agg AS (
   SELECT
      ws.ws_item_sk,
      SUM(ws.ws_ext_sales_price) AS sum_web_sales,
      COUNT(*)                    AS cnt_web_sales
   FROM web_sales ws
   JOIN time_dim t      ON ws.ws_sold_time_sk = t.t_time_sk
   JOIN item i          ON ws.ws_item_sk = i.i_item_sk
   JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
   JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
   WHERE t.t_hour BETWEEN 8 AND 18
     AND i.i_current_price BETWEEN 10 AND 500
     AND ca.ca_state = 'CA'
     AND hd.hd_dep_count <= 2
   GROUP BY ws.ws_item_sk
),
web_returns_agg AS (
   SELECT
      wr.wr_item_sk,
      SUM(wr.wr_return_amt) AS sum_web_return,
      COUNT(*)               AS cnt_web_return
   FROM web_returns wr
   JOIN time_dim t      ON wr.wr_returned_time_sk = t.t_time_sk
   JOIN item i          ON wr.wr_item_sk = i.i_item_sk
   WHERE t.t_hour BETWEEN 8 AND 18
     AND i.i_current_price BETWEEN 10 AND 500
   GROUP BY wr.wr_item_sk
),
inventory_agg AS (
   SELECT
      inv.inv_item_sk,
      SUM(inv.inv_quantity_on_hand) AS total_on_hand
   FROM inventory inv
   JOIN item i ON inv.inv_item_sk = i.i_item_sk
   WHERE i.i_current_price BETWEEN 10 AND 500
   GROUP BY inv.inv_item_sk
)
SELECT
   s.cs_item_sk                                 AS item_sk,
   s.i_category,
   s.i_brand,
   s.t_hour,
   s.sum_sales,
   s.avg_sales_price,
   s.cnt_sales,
   r.sum_store_return,
   ws.sum_web_sales,
   wr.sum_web_return,
   inv.total_on_hand,
   CASE WHEN s.promo_active_flag = 1 THEN s.sum_sales * 0.9 ELSE s.sum_sales END AS adjusted_sales,
   ROW_NUMBER() OVER (PARTITION BY s.i_category ORDER BY s.sum_sales DESC)            AS category_rank,
   SUM(s.sum_sales) OVER (PARTITION BY s.i_category ORDER BY s.t_hour
                         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)      AS running_category_sales,
   LAG(s.sum_sales) OVER (PARTITION BY s.i_category ORDER BY s.t_hour)               AS prior_hour_sales
FROM sales_agg s
LEFT JOIN returns_agg r   ON s.cs_item_sk = r.sr_item_sk
LEFT JOIN web_sales_agg ws ON s.cs_item_sk = ws.ws_item_sk
LEFT JOIN web_returns_agg wr ON s.cs_item_sk = wr.wr_item_sk
LEFT JOIN inventory_agg inv ON s.cs_item_sk = inv.inv_item_sk
ORDER BY s.sum_sales DESC
LIMIT 100
