WITH wr_agg AS (
    SELECT
        wr.wr_item_sk,
        SUM(wr.wr_net_loss) AS total_return_loss,
        MAX(wr.wr_returned_date_sk) AS latest_return_date
    FROM web_returns wr
    GROUP BY wr.wr_item_sk
),
ws_adj AS (
    SELECT
        ws.ws_promo_sk AS promo_sk,
        ws.ws_ext_discount_amt AS discount_amt,
        ws.ws_net_profit - COALESCE(wr_agg.total_return_loss, 0) AS profit_adj,
        ws.ws_sold_time_sk AS time_sk,
        DATE_FORMAT(DATE_ADD('day', ws.ws_sold_date_sk, DATE '1997-01-01'), '%Y-%m') AS sale_month,
        'web' AS source
    FROM web_sales ws
    LEFT JOIN wr_agg ON ws.ws_item_sk = wr_agg.wr_item_sk
    WHERE ws.ws_net_paid > 0
),
cs_adj AS (
    SELECT
        cs.cs_promo_sk AS promo_sk,
        cs.cs_ext_discount_amt AS discount_amt,
        cs.cs_net_profit AS profit_adj,
        cs.cs_sold_time_sk AS time_sk,
        DATE_FORMAT(DATE_ADD('day', cs.cs_sold_date_sk, DATE '1997-01-01'), '%Y-%m') AS sale_month,
        'catalog' AS source
    FROM catalog_sales cs
    WHERE cs.cs_net_paid_inc_tax > 0
),
promo_union AS (
    SELECT promo_sk, discount_amt, profit_adj, time_sk, sale_month, source FROM cs_adj
    UNION ALL
    SELECT promo_sk, discount_amt, profit_adj, time_sk, sale_month, source FROM ws_adj
),
promo_with_time AS (
    SELECT
        pu.promo_sk,
        pu.source,
        pu.discount_amt,
        pu.profit_adj,
        pu.sale_month,
        t.t_shift,
        t.t_am_pm
    FROM promo_union pu
    JOIN time_dim t ON pu.time_sk = t.t_time_sk
),
promo_agg AS (
    SELECT
        promo_sk,
        source,
        sale_month,
        SUM(profit_adj) AS month_profit,
        AVG(discount_amt) AS month_avg_discount,
        SUM(profit_adj) / NULLIF(AVG(discount_amt), 0) AS profit_per_discount
    FROM promo_with_time
    GROUP BY promo_sk, source, sale_month
    HAVING SUM(profit_adj) <> 0
)
SELECT
    promo_sk,
    source,
    sale_month,
    month_profit,
    month_avg_discount,
    profit_per_discount,
    RANK() OVER (PARTITION BY source ORDER BY profit_per_discount DESC) AS month_rank
FROM promo_agg
ORDER BY source, month_rank
