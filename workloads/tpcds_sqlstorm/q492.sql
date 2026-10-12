WITH unified_sales AS (
  SELECT cs_sold_date_sk AS sold_date_sk,
         cs_item_sk AS item_sk,
         cs_bill_customer_sk AS customer_sk,
         cs_call_center_sk AS call_center_sk,
         cs_quantity AS quantity,
         cs_net_paid AS net_paid,
         cs_net_profit AS net_profit,
         cs_ext_sales_price AS ext_sales_price,
         cs_ext_discount_amt AS ext_discount_amt,
         cs_order_number AS order_number,
         'catalog' AS channel
  FROM catalog_sales
  UNION ALL
  SELECT ss_sold_date_sk,
         ss_item_sk,
         ss_customer_sk,
         NULL AS call_center_sk,
         ss_quantity,
         ss_net_paid,
         ss_net_profit,
         ss_ext_sales_price,
         ss_ext_discount_amt,
         ss_ticket_number,
         'store'
  FROM store_sales
  UNION ALL
  SELECT ws_sold_date_sk,
         ws_item_sk,
         ws_bill_customer_sk,
         NULL AS call_center_sk,
         ws_quantity,
         ws_net_paid,
         ws_net_profit,
         ws_ext_sales_price,
         ws_ext_discount_amt,
         ws_order_number,
         'web'
  FROM web_sales
),
sales_with_date AS (
  SELECT us.*,
         d.d_date,
         d.d_year,
         d.d_month_seq,
         d.d_week_seq,
         d.d_qoy,
         ROW_NUMBER() OVER (PARTITION BY us.customer_sk ORDER BY d.d_date) AS customer_seq,
         SUM(us.net_paid) OVER (PARTITION BY us.customer_sk ORDER BY d.d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_net_paid,
         AVG(us.net_paid) OVER (PARTITION BY us.customer_sk) AS avg_net_paid_all_time
  FROM unified_sales us
  LEFT JOIN date_dim d
    ON us.sold_date_sk = d.d_date_sk
),
returns_agg AS (
  SELECT 'catalog' AS channel,
         cr_order_number AS order_number,
         SUM(cr_return_amount) AS total_return_amount,
         SUM(cr_return_quantity) AS total_return_qty
  FROM catalog_returns
  GROUP BY cr_order_number
  UNION ALL
  SELECT 'store' AS channel,
         sr_ticket_number AS order_number,
         SUM(sr_return_amt) AS total_return_amount,
         SUM(sr_return_quantity) AS total_return_qty
  FROM store_returns
  GROUP BY sr_ticket_number
  UNION ALL
  SELECT 'web' AS channel,
         wr_order_number AS order_number,
         SUM(wr_return_amt) AS total_return_amount,
         SUM(wr_return_quantity) AS total_return_qty
  FROM web_returns
  GROUP BY wr_order_number
),
sales_enriched AS (
  SELECT swd.*,
         COALESCE(ra.total_return_amount, 0) AS return_amount,
         COALESCE(ra.total_return_qty, 0) AS return_qty,
         (swd.ext_sales_price - COALESCE(ra.total_return_amount, 0)) AS net_sales_amount,
         CASE
           WHEN swd.net_profit > 0 AND COALESCE(ra.total_return_qty, 0) = 0 THEN 'Profitable'
           WHEN swd.net_profit < 0 THEN 'Loss'
           ELSE 'BreakEven'
         END AS profit_status,
         CONCAT(i.i_item_id, ':', CAST(swd.d_date AS varchar)) AS item_date_key,
         COALESCE(NULLIF(swd.call_center_sk, 0), -1) AS effective_call_center_sk,
         CASE
           WHEN swd.quantity IS NULL THEN 'UNKNOWN'
           WHEN swd.quantity = 0 THEN 'ZERO_QTY'
           WHEN swd.quantity > 100 THEN 'BULK'
           ELSE 'NORMAL'
         END AS qty_category,
         CASE
           WHEN REGEXP_LIKE(i.i_product_name, '^.*[0-9]{4}.*$') THEN 'HAS_YEAR'
           ELSE 'NO_YEAR'
         END AS product_name_pattern,
         (swd.net_paid / NULLIF(swd.quantity, 0)) AS unit_net_paid,
         (SELECT AVG(cs.cs_net_profit)
            FROM catalog_sales cs
           WHERE cs.cs_bill_customer_sk = swd.customer_sk
             AND cs.cs_sold_date_sk <= swd.sold_date_sk) AS catalog_lifetime_avg_profit,
         CASE WHEN swd.customer_sk IN (
                SELECT customer_sk FROM unified_sales WHERE channel = 'catalog'
                INTERSECT
                SELECT customer_sk FROM unified_sales WHERE channel = 'store'
                INTERSECT
                SELECT customer_sk FROM unified_sales WHERE channel = 'web')
              THEN 1 ELSE 0 END AS in_all_channels
  FROM sales_with_date swd
  LEFT JOIN returns_agg ra
    ON swd.channel = ra.channel AND swd.order_number = ra.order_number
  LEFT JOIN item i
    ON swd.item_sk = i.i_item_sk
),
final_agg AS (
  SELECT
    d_year,
    channel,
    qty_category,
    CASE WHEN GROUPING(profit_status) = 0 THEN profit_status ELSE NULL END AS profit_status,
    COUNT(*) AS sales_cnt,
    SUM(net_sales_amount) AS total_net_sales,
    SUM(return_amount) AS total_returns,
    AVG(unit_net_paid) AS avg_unit_net_paid,
    SUM(CASE WHEN in_all_channels = 1 THEN 1 ELSE 0 END) AS all_channel_customers,
    COUNT(DISTINCT customer_sk) AS distinct_customers,
    GROUPING(d_year) AS g_year,
    GROUPING(channel) AS g_channel,
    GROUPING(qty_category) AS g_qty_category,
    GROUPING(profit_status) AS g_profit_status
  FROM sales_enriched
  WHERE (net_sales_amount > 0 OR net_sales_amount IS NULL)
    AND (COALESCE(ext_discount_amt, 0) NOT BETWEEN 0 AND 5 OR ext_discount_amt IS NULL)
    AND (CASE WHEN quantity IS NULL THEN FALSE ELSE TRUE END)
  GROUP BY GROUPING SETS ((d_year, channel, qty_category, profit_status), (d_year, channel, qty_category))
)
SELECT *
FROM final_agg
ORDER BY d_year DESC NULLS LAST, channel, qty_category
