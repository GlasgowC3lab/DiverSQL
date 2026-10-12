WITH
  /* Items whose product name contains "Pro" or "Deluxe" and the word "Widget" */
  item_match AS (
    SELECT
      i.i_item_sk,
      i.i_item_id,
      i.i_product_name,
      regexp_extract(i.i_product_name, '(\\w+)', 1) AS first_word,
      concat(i.i_brand, '-', i.i_category) AS brand_category
    FROM tpcds.item i
    WHERE regexp_like(i.i_product_name, '(?i)(pro|deluxe)')
      AND i.i_product_name LIKE '%Widget%'
  ),

  /* Orders that appear in both catalog_returns and web_returns for the matched items */
  orders_in_both_returns AS (
    SELECT cr.cr_order_number AS order_number
    FROM tpcds.catalog_returns cr
    JOIN item_match im ON cr.cr_item_sk = im.i_item_sk
    GROUP BY cr.cr_order_number
    INTERSECT
    SELECT wr.wr_order_number AS order_number
    FROM tpcds.web_returns wr
    JOIN item_match im ON wr.wr_item_sk = im.i_item_sk
    GROUP BY wr.wr_order_number
  ),

  /* Union of sales from catalog and web channels for the matched items */
  sales_union AS (
    SELECT
      cs.cs_order_number AS order_number,
      d.d_year,
      cs.cs_item_sk AS item_sk,
      sum(cs.cs_net_paid_inc_tax) AS total_paid,
      sum(cs.cs_net_profit) AS total_profit
    FROM tpcds.catalog_sales cs
    JOIN tpcds.date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item_match im ON cs.cs_item_sk = im.i_item_sk
    GROUP BY cs.cs_order_number, d.d_year, cs.cs_item_sk
    UNION
    SELECT
      ws.ws_order_number AS order_number,
      d.d_year,
      ws.ws_item_sk AS item_sk,
      sum(ws.ws_net_paid_inc_tax) AS total_paid,
      sum(ws.ws_net_profit) AS total_profit
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item_match im ON ws.ws_item_sk = im.i_item_sk
    GROUP BY ws.ws_order_number, d.d_year, ws.ws_item_sk
  ),

  /* Aggregated loss from catalog returns */
  catalog_return_loss AS (
    SELECT cr.cr_order_number AS order_number,
           sum(cr.cr_net_loss) AS loss
    FROM tpcds.catalog_returns cr
    JOIN item_match im ON cr.cr_item_sk = im.i_item_sk
    GROUP BY cr.cr_order_number
  ),

  /* Aggregated loss from web returns */
  web_return_loss AS (
    SELECT wr.wr_order_number AS order_number,
           sum(wr.wr_net_loss) AS loss
    FROM tpcds.web_returns wr
    JOIN item_match im ON wr.wr_item_sk = im.i_item_sk
    GROUP BY wr.wr_order_number
  )
SELECT
  su.order_number,
  su.d_year,
  su.total_paid,
  su.total_profit,
  coalesce(crl.loss, 0) + coalesce(wrl.loss, 0) AS total_return_loss,
  im.brand_category,
  im.first_word
FROM sales_union su
JOIN orders_in_both_returns obr ON su.order_number = obr.order_number
LEFT JOIN catalog_return_loss crl ON su.order_number = crl.order_number
LEFT JOIN web_return_loss wrl ON su.order_number = wrl.order_number
JOIN item_match im ON su.item_sk = im.i_item_sk
ORDER BY su.total_paid DESC
LIMIT 100
