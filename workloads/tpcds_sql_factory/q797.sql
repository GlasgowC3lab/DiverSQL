WITH wr_agg AS (
    SELECT
        wr.wr_item_sk,
        wr.wr_order_number,
        SUM(wr.wr_net_loss) AS total_return_loss,
        COUNT(DISTINCT wr.wr_returned_date_sk) AS distinct_return_days
    FROM web_returns wr
    WHERE wr.wr_fee > 0
    GROUP BY wr.wr_item_sk, wr.wr_order_number
),
ws_adj AS (
    SELECT
        ws.ws_promo_sk AS promo_sk,
        ws.ws_ext_discount_amt AS discount_amt,
        ws.ws_net_profit - COALESCE(wr_agg.total_return_loss, 0) AS profit_adj,
        ws.ws_sold_time_sk AS time_sk,
        ws.ws_ship_mode_sk AS ship_mode,
        'web' AS source
    FROM web_sales ws
    LEFT JOIN wr_agg ON ws.ws_item_sk = wr_agg.wr_item_sk AND ws.ws_order_number = wr_agg.wr_order_number
    WHERE ws.ws_ship_mode_sk IS NOT NULL
),
cs_adj AS (
    SELECT
        cs.cs_promo_sk AS promo_sk,
        cs.cs_ext_discount_amt AS discount_amt,
        cs.cs_net_profit AS profit_adj,
        cs.cs_sold_time_sk AS time_sk,
        cs.cs_ship_mode_sk AS ship_mode,
        'catalog' AS source
    FROM catalog_sales cs
    WHERE cs.cs_ship_mode_sk IS NOT NULL
),
promo_union AS (
    SELECT promo_sk, discount_amt, profit_adj, time_sk, ship_mode, source FROM cs_adj
    UNION ALL
    SELECT promo_sk, discount_amt, profit_adj, time_sk, ship_mode, source FROM ws_adj
),
promo_with_time AS (
    SELECT
        pu.promo_sk,
        pu.source,
        pu.discount_amt,
        pu.profit_adj,
        pu.ship_mode,
        t.t_shift,
        t.t_hour
    FROM promo_union pu
    JOIN time_dim t ON pu.time_sk = t.t_time_sk
    WHERE t.t_shift = 'Evening'
),
promo_agg AS (
    SELECT
        promo_sk,
        source,
        ship_mode,
        SUM(profit_adj) AS total_profit,
        AVG(discount_amt) AS avg_discount,
        SUM(profit_adj) / NULLIF(AVG(discount_amt), 0) AS profit_per_discount
    FROM promo_with_time
    GROUP BY promo_sk, source, ship_mode
)
SELECT
    promo_sk,
    source,
    ship_mode,
    total_profit,
    avg_discount,
    profit_per_discount,
    DENSE_RANK() OVER (PARTITION BY source ORDER BY profit_per_discount DESC) AS rank_by_ship_mode
FROM promo_agg
ORDER BY source, rank_by_ship_mode
