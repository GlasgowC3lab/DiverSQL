WITH returns_agg AS (
    SELECT i.i_item_sk AS item_sk,
           SUM(sr.sr_net_loss) AS total_return_loss
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk
),
profit_by_category AS (
    SELECT
        cp.cp_department,
        i.i_category,
        w.w_state,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(ws.ws_net_profit) AS web_profit,
        SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) AS total_profit,
        SUM(DISTINCT COALESCE(r.total_return_loss, 0)) AS total_return_loss
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN returns_agg r ON r.item_sk = i.i_item_sk
    WHERE cp.cp_type = 'monthly'
      AND cp.cp_start_date_sk BETWEEN 2450800 AND 2450900
      AND cs.cs_sold_date_sk BETWEEN 2450800 AND 2451000
      AND ws.ws_sold_date_sk BETWEEN 2450800 AND 2451000
      AND w.w_state = 'CA'
    GROUP BY cp.cp_department, i.i_category, w.w_state
)
SELECT
    cp_department,
    i_category,
    w_state,
    catalog_profit,
    web_profit,
    total_profit,
    total_return_loss,
    total_profit - total_return_loss AS net_profit_adj,
    ROW_NUMBER() OVER (PARTITION BY cp_department ORDER BY total_profit DESC) AS category_rank
FROM profit_by_category
WHERE total_profit > 5000
ORDER BY net_profit_adj DESC
LIMIT 10
