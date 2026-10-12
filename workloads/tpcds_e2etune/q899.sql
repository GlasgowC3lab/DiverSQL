WITH cs_agg AS (
    SELECT ca.ca_state AS state,
           SUM(cs.cs_net_paid_inc_ship_tax) AS cs_net_revenue,
           SUM(cs.cs_quantity) AS cs_quantity_sold,
           SUM(cs.cs_net_profit) AS cs_profit
    FROM catalog_sales cs
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450820 AND 2450830
      AND cs.cs_warehouse_sk IN (3, 4, 6)
    GROUP BY ca.ca_state
),
ws_agg AS (
    SELECT ca.ca_state AS state,
           SUM(ws.ws_net_paid_inc_ship_tax) AS ws_net_revenue,
           SUM(ws.ws_quantity) AS ws_quantity_sold,
           SUM(ws.ws_net_profit) AS ws_profit
    FROM web_sales ws
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450820 AND 2450830
    GROUP BY ca.ca_state
),
wr_agg AS (
    SELECT ca.ca_state AS state,
           r.r_reason_desc AS reason,
           SUM(wr.wr_net_loss) AS wr_total_loss,
           SUM(wr.wr_return_quantity) AS wr_return_qty
    FROM web_returns wr
    JOIN web_sales ws
      ON wr.wr_order_number = ws.ws_order_number
     AND wr.wr_item_sk = ws.ws_item_sk
    JOIN customer_address ca
      ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN reason r
      ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450820 AND 2450830
    GROUP BY ca.ca_state, r.r_reason_desc
)
SELECT
    COALESCE(cs.state, ws.state, wr.state) AS state,
    COALESCE(cs.cs_net_revenue, 0) AS catalog_net_revenue,
    COALESCE(ws.ws_net_revenue, 0) AS web_net_revenue,
    COALESCE(cs.cs_quantity_sold, 0) + COALESCE(ws.ws_quantity_sold, 0) AS total_quantity_sold,
    COALESCE(wr.wr_return_qty, 0) AS total_return_quantity,
    CASE 
        WHEN (COALESCE(cs.cs_quantity_sold, 0) + COALESCE(ws.ws_quantity_sold, 0)) = 0 THEN 0
        ELSE COALESCE(wr.wr_return_qty, 0) * 1.0 / (COALESCE(cs.cs_quantity_sold, 0) + COALESCE(ws.ws_quantity_sold, 0))
    END AS return_rate,
    COALESCE(cs.cs_profit, 0) + COALESCE(ws.ws_profit, 0) - COALESCE(wr.wr_total_loss, 0) AS net_profit_after_returns,
    wr.reason,
    RANK() OVER (ORDER BY (COALESCE(cs.cs_profit, 0) + COALESCE(ws.ws_profit, 0) - COALESCE(wr.wr_total_loss, 0)) DESC) AS profit_rank
FROM cs_agg cs
FULL OUTER JOIN ws_agg ws ON cs.state = ws.state
FULL OUTER JOIN wr_agg wr ON COALESCE(cs.state, ws.state) = wr.state
WHERE (COALESCE(cs.cs_net_revenue, 0) + COALESCE(ws.ws_net_revenue, 0)) > 20000
ORDER BY net_profit_after_returns DESC
LIMIT 50
