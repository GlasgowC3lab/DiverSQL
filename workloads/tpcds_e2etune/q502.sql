WITH ws AS (
    SELECT ws_item_sk,
           ws_order_number,
           ws_bill_addr_sk,
           ws_net_profit,
           ws_quantity
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450000 AND 2453650
),
wr_agg AS (
    SELECT wr_item_sk,
           wr_order_number,
           SUM(wr_net_loss) AS total_wr_net_loss,
           SUM(wr_return_quantity) AS total_wr_qty
    FROM web_returns
    WHERE wr_returned_date_sk BETWEEN 2450000 AND 2453650
    GROUP BY wr_item_sk, wr_order_number
),
cr_agg AS (
    SELECT cr_item_sk,
           SUM(cr_net_loss) AS total_cr_net_loss,
           SUM(cr_return_quantity) AS total_cr_qty
    FROM catalog_returns
    WHERE cr_returned_date_sk BETWEEN 2450000 AND 2453650
    GROUP BY cr_item_sk
)
SELECT i.i_brand,
       ca.ca_state,
       SUM(ws.ws_net_profit) - COALESCE(SUM(wr_agg.total_wr_net_loss), 0) - COALESCE(SUM(cr_agg.total_cr_net_loss), 0) AS net_profit_adj,
       SUM(ws.ws_quantity) - COALESCE(SUM(wr_agg.total_wr_qty), 0) - COALESCE(SUM(cr_agg.total_cr_qty), 0) AS net_quantity,
       RANK() OVER (ORDER BY SUM(ws.ws_net_profit) - COALESCE(SUM(wr_agg.total_wr_net_loss), 0) - COALESCE(SUM(cr_agg.total_cr_net_loss), 0) DESC) AS profit_rank
FROM ws
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
LEFT JOIN wr_agg ON ws.ws_item_sk = wr_agg.wr_item_sk AND ws.ws_order_number = wr_agg.wr_order_number
LEFT JOIN cr_agg ON ws.ws_item_sk = cr_agg.cr_item_sk
WHERE i.i_category = 'Electronics'
  AND ca.ca_state = 'CA'
GROUP BY i.i_brand, ca.ca_state
HAVING SUM(ws.ws_quantity) > 100
ORDER BY net_profit_adj DESC
LIMIT 20
