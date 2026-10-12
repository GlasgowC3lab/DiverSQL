WITH sales_agg AS (
    SELECT ws_item_sk,
           SUM(ws_net_paid) AS total_sales,
           SUM(ws_quantity) AS total_quantity,
           AVG(ws_ext_discount_amt) AS avg_discount,
           SUM(ws_net_profit) AS total_profit
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450815 AND 2450825
    GROUP BY ws_item_sk
),
returns_agg AS (
    SELECT wr_item_sk,
           SUM(wr_return_amt) AS total_return_amount,
           SUM(wr_return_quantity) AS total_return_qty,
           SUM(wr_net_loss) AS total_return_loss
    FROM web_returns
    WHERE wr_returned_date_sk BETWEEN 2450815 AND 2450825
    GROUP BY wr_item_sk
)
SELECT s.ws_item_sk AS item_sk,
       s.total_sales,
       r.total_return_amount,
       s.total_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns,
       CASE WHEN s.total_quantity > 0
            THEN 100.0 * COALESCE(r.total_return_qty, 0) / s.total_quantity
            ELSE 0 END AS return_rate_pct,
       RANK() OVER (ORDER BY (s.total_profit - COALESCE(r.total_return_loss, 0)) DESC) AS profit_rank
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.ws_item_sk = r.wr_item_sk
WHERE (s.total_sales > 1000 OR COALESCE(r.total_return_amount, 0) > 0)
ORDER BY net_profit_after_returns DESC
LIMIT 10
