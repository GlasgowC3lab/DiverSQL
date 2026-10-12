WITH store_no_return AS (
  SELECT
    c.c_customer_id,
    i.i_item_id,
    ss.ss_quantity AS quantity,
    ss.ss_net_paid AS net_paid,
    ss.ss_sold_date_sk AS sale_date_sk,
    t.t_hour
  FROM store_sales ss
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  WHERE t.t_hour BETWEEN 9 AND 17
    AND i.i_category = 'Electronics'
    AND NOT EXISTS (
      SELECT 1
      FROM catalog_returns cr
      WHERE cr.cr_item_sk = ss.ss_item_sk
        AND cr.cr_returned_date_sk = ss.ss_sold_date_sk
        AND cr.cr_returning_customer_sk = ss.ss_customer_sk
    )
),
web_no_return AS (
  SELECT
    c.c_customer_id,
    i.i_item_id,
    ws.ws_quantity AS quantity,
    ws.ws_net_paid AS net_paid,
    ws.ws_sold_date_sk AS sale_date_sk,
    t.t_hour
  FROM web_sales ws
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
  JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
  WHERE w.web_company_name = 'able'
    AND i.i_category = 'Electronics'
    AND NOT EXISTS (
      SELECT 1
      FROM web_returns wr
      WHERE wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_returned_date_sk = ws.ws_sold_date_sk
        AND wr.wr_returning_customer_sk = ws.ws_bill_customer_sk
    )
)
SELECT
  c_customer_id,
  i_item_id,
  quantity,
  net_paid,
  sale_date_sk,
  t_hour
FROM store_no_return
UNION ALL
SELECT
  c_customer_id,
  i_item_id,
  quantity,
  net_paid,
  sale_date_sk,
  t_hour
FROM web_no_return
LIMIT 100
