WITH wr_agg AS (
    SELECT
        wr.wr_item_sk,
        wr.wr_order_number,
        SUM(wr.wr_net_loss) AS total_return_loss,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    WHERE wr.wr_return_quantity > 0
    GROUP BY wr.wr_item_sk, wr.wr_order_number
),
ws_adj AS (
    SELECT
        ws.ws_promo_sk AS promo_sk,
        ws.ws_ext_discount_amt AS discount_amt,
        ws.ws_net_profit - COALESCE(wr_agg.total_return_loss, 0) AS profit_adj,
        ws.ws_sold_time_sk AS time_sk,
        ws.ws_quantity AS qty,
        'web' AS source
    FROM web_sales ws
    LEFT JOIN wr_agg
        ON ws.ws_item_sk = wr_agg.wr_item_sk
           AND ws.ws_order_number = wr_agg.wr_order_number
    WHERE ws.ws_quantity >= 1
),
cs_adj AS (
    SELECT
        cs.cs_promo_sk AS promo_sk,
        cs.cs_ext_discount_amt AS discount_amt,
        cs.cs_net_profit AS profit_adj,
        cs.cs_sold_time_sk AS time_sk,
        cs.cs_quantity AS qty,
        'catalog' AS source
    FROM catalog_sales cs
    WHERE cs.cs_quantity BETWEEN 1 AND 10
),
promo_union AS (
    SELECT promo_sk, discount_amt, profit_adj, time_sk, qty, source FROM cs_adj
    UNION ALL
    SELECT promo_sk, discount_amt, profit_adj, time_sk, qty, source FROM ws_adj
),
promo_with_time AS (
    SELECT
        pu.promo_sk,
        pu.source,
        pu.discount_amt,
        pu.profit_adj,
        pu.qty,
        t.t_hour,
        t.t_shift,
        t.t_meal_time
    FROM promo_union pu
    JOIN time_dim t ON pu.time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
),
promo_agg AS (
    SELECT
        promo_sk,
        source,
        SUM(profit_adj) AS total_profit_adj,
        AVG(discount_amt) AS avg_discount,
        SUM(qty) AS total_qty,
        SUM(profit_adj) / NULLIF(AVG(discount_amt), 0) AS profit_per_discount,
        CASE WHEN SUM(profit_adj) > 0 THEN 'Positive' ELSE 'Negative' END AS profit_sign
    FROM promo_with_time
    GROUP BY promo_sk, source
)
SELECT
    promo_sk,
    source,
    total_profit_adj,
    avg_discount,
    total_qty,
    profit_per_discount,
    profit_sign,
    ROW_NUMBER() OVER (PARTITION BY source ORDER BY total_profit_adj DESC) AS promo_rank
FROM promo_agg
ORDER BY source, promo_rank
