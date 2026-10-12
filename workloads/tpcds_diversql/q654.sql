WITH sales_data AS (
   SELECT
       ws.ws_order_number,
       ws.ws_sold_date_sk,
       d.d_date,
       i.i_item_id,
       i.i_category,
       ws.ws_ext_sales_price,
       ws.ws_net_profit,
       ws.ws_quantity,
       cc.cc_state,
       wr.wr_return_amt,
       ib.ib_upper_bound
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
   JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
   LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
   WHERE d.d_year = 2001
     AND d.d_month_seq BETWEEN 1 AND 12
     AND i.i_brand = 'Brand#45'
     AND ib.ib_upper_bound >= 50000
     AND ws.ws_quantity > 2
     AND cc.cc_state = 'CA'
)
SELECT
   sd.ws_order_number,
   sd.d_date,
   sd.i_item_id,
   sd.i_category,
   sd.ws_net_profit,
   CASE
       WHEN sd.ws_ext_sales_price > (SELECT MAX(ws_ext_sales_price) FROM sales_data) * 0.9 THEN 'High'
       ELSE 'Low'
   END AS price_category,
   RANK() OVER (PARTITION BY sd.i_category ORDER BY sd.ws_net_profit DESC) AS profit_rank
FROM sales_data sd
WHERE sd.ws_net_profit > 0

INTERSECT

SELECT
   sd.ws_order_number,
   sd.d_date,
   sd.i_item_id,
   sd.i_category,
   sd.ws_net_profit,
   CASE
       WHEN sd.ws_ext_sales_price > (SELECT MAX(ws_ext_sales_price) FROM sales_data) * 0.9 THEN 'High'
       ELSE 'Low'
   END AS price_category,
   RANK() OVER (PARTITION BY sd.i_category ORDER BY sd.ws_net_profit DESC) AS profit_rank
FROM sales_data sd
WHERE sd.wr_return_amt IS NULL

LIMIT 100
