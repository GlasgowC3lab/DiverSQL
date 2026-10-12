SELECT
  d.d_year AS year,
  d.d_month_seq AS month,
  'store' AS channel,
  i.i_category AS category,
  sum(ss.ss_ext_sales_price) AS total_sales,
  sum(coalesce(sr_agg.return_amt_inc_tax, 0)) AS total_returns,
  sum(ss.ss_net_profit) - sum(coalesce(sr_agg.net_loss, 0)) AS net_profit
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
LEFT JOIN (
    SELECT sr_ticket_number,
           sum(sr_return_amt_inc_tax) AS return_amt_inc_tax,
           sum(sr_net_loss) AS net_loss
    FROM store_returns
    GROUP BY sr_ticket_number
) sr_agg ON ss.ss_ticket_number = sr_agg.sr_ticket_number
GROUP BY d.d_year, d.d_month_seq, i.i_category

UNION ALL

SELECT
  d.d_year,
  d.d_month_seq,
  'catalog',
  i.i_category,
  sum(cs.cs_ext_sales_price),
  sum(coalesce(cr_agg.return_amt_inc_tax, 0)),
  sum(cs.cs_net_profit) - sum(coalesce(cr_agg.net_loss, 0))
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
LEFT JOIN (
    SELECT cr_order_number,
           sum(cr_return_amt_inc_tax) AS return_amt_inc_tax,
           sum(cr_net_loss) AS net_loss
    FROM catalog_returns
    GROUP BY cr_order_number
) cr_agg ON cs.cs_order_number = cr_agg.cr_order_number
GROUP BY d.d_year, d.d_month_seq, i.i_category

UNION ALL

SELECT
  d.d_year,
  d.d_month_seq,
  'web',
  i.i_category,
  sum(ws.ws_ext_sales_price),
  sum(coalesce(wr_agg.return_amt_inc_tax, 0)),
  sum(ws.ws_net_profit) - sum(coalesce(wr_agg.net_loss, 0))
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
LEFT JOIN (
    SELECT wr_order_number,
           sum(wr_return_amt_inc_tax) AS return_amt_inc_tax,
           sum(wr_net_loss) AS net_loss
    FROM web_returns
    GROUP BY wr_order_number
) wr_agg ON ws.ws_order_number = wr_agg.wr_order_number
GROUP BY d.d_year, d.d_month_seq, i.i_category
ORDER BY 1, 2, 3, 4
