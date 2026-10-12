/* Goal: Identify the top 5 warehouse locations with the highest combined net loss for each return reason, using sampled store returns and several filters. */
WITH sr AS (
    SELECT *
    FROM store_returns TABLESAMPLE BERNOULLI (10)
    WHERE sr_store_credit > 10
      AND sr_reversed_charge < 500
),
joined AS (
    SELECT
        r.r_reason_desc,
        ws.ws_warehouse_sk,
        sr.sr_net_loss,
        wr.wr_net_loss
    FROM sr
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_returns wr
        ON r.r_reason_sk = wr.wr_reason_sk
       AND wr.wr_return_quantity > 0
    JOIN web_sales ws
        ON wr.wr_item_sk = ws.ws_item_sk
       AND wr.wr_order_number = ws.ws_order_number
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ws.ws_warehouse_sk IN (4, 7)
      AND ws.ws_wholesale_cost < 80
      AND wp.wp_type = 'article'
),
agg AS (
    SELECT
        r_reason_desc,
        ws_warehouse_sk,
        SUM(COALESCE(sr_net_loss, 0) + COALESCE(wr_net_loss, 0)) AS total_net_loss,
        COUNT(*) AS cnt_returns
    FROM joined
    GROUP BY r_reason_desc, ws_warehouse_sk
    HAVING COUNT(*) > 5
),
ranked AS (
    SELECT
        r_reason_desc,
        ws_warehouse_sk,
        total_net_loss,
        cnt_returns,
        ROW_NUMBER() OVER (PARTITION BY r_reason_desc ORDER BY total_net_loss DESC) AS rn
    FROM agg
)
SELECT
    r_reason_desc,
    ws_warehouse_sk,
    total_net_loss,
    cnt_returns,
    rn
FROM ranked
WHERE rn <= 5
ORDER BY total_net_loss DESC
LIMIT 100
