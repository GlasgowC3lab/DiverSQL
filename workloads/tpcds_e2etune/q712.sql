WITH store_sales_agg AS (
    SELECT ss.ss_promo_sk AS promo_sk,
           SUM(ss.ss_net_profit) AS store_net_profit,
           SUM(ss.ss_quantity) AS store_qty
    FROM store_sales ss
    GROUP BY ss.ss_promo_sk
),
store_returns_agg AS (
    SELECT ss.ss_promo_sk AS promo_sk,
           SUM(sr.sr_net_loss) AS store_return_loss
    FROM store_sales ss
    JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
    GROUP BY ss.ss_promo_sk
),
store_adj AS (
    SELECT ss.promo_sk,
           ss.store_net_profit - COALESCE(sr.store_return_loss, 0) AS store_adj_net_profit,
           ss.store_qty
    FROM store_sales_agg ss
    LEFT JOIN store_returns_agg sr ON ss.promo_sk = sr.promo_sk
),
catalog_agg AS (
    SELECT cs.cs_promo_sk AS promo_sk,
           SUM(cs.cs_net_profit) AS catalog_net_profit,
           SUM(cs.cs_quantity) AS catalog_qty
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_mkt_class = 'North Midwest'
      AND cc.cc_employees > 3000000
    GROUP BY cs.cs_promo_sk
)
SELECT p.p_promo_id,
       p.p_promo_name,
       COALESCE(sa.store_adj_net_profit, 0) + COALESCE(ca.catalog_net_profit, 0) AS total_net_profit,
       COALESCE(sa.store_qty, 0) + COALESCE(ca.catalog_qty, 0) AS total_quantity,
       CASE WHEN (COALESCE(sa.store_adj_net_profit, 0) + COALESCE(ca.catalog_net_profit, 0)) = 0 THEN 0
            ELSE (COALESCE(sa.store_adj_net_profit, 0) + COALESCE(ca.catalog_net_profit, 0)) / (COALESCE(sa.store_qty, 0) + COALESCE(ca.catalog_qty, 0))
       END AS profit_per_unit,
       p.p_channel_tv,
       p.p_channel_radio,
       p.p_channel_email
FROM promotion p
LEFT JOIN store_adj sa ON p.p_promo_sk = sa.promo_sk
LEFT JOIN catalog_agg ca ON p.p_promo_sk = ca.promo_sk
WHERE (COALESCE(sa.store_adj_net_profit, 0) + COALESCE(ca.catalog_net_profit, 0)) > 0
ORDER BY total_net_profit DESC
LIMIT 10
