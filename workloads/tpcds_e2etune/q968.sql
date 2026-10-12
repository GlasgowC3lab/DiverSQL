SELECT
    p.p_promo_id,
    p.p_promo_name,
    p.p_channel_tv,
    COALESCE(sm.store_net_profit, 0) AS store_net_profit,
    COALESCE(wm.web_net_profit, 0) AS web_net_profit,
    COALESCE(rm.return_loss, 0) AS return_loss,
    (COALESCE(sm.store_net_profit, 0) + COALESCE(wm.web_net_profit, 0) - COALESCE(rm.return_loss, 0)) AS total_net_profit,
    p.p_cost,
    (COALESCE(sm.store_net_profit, 0) + COALESCE(wm.web_net_profit, 0) - COALESCE(rm.return_loss, 0)) / NULLIF(p.p_cost, 0) AS roi,
    RANK() OVER (ORDER BY (COALESCE(sm.store_net_profit, 0) + COALESCE(wm.web_net_profit, 0) - COALESCE(rm.return_loss, 0)) / NULLIF(p.p_cost, 0) DESC) AS roi_rank
FROM promotion p
LEFT JOIN (
    SELECT
        ss_promo_sk AS promo_sk,
        SUM(ss_net_profit) AS store_net_profit,
        SUM(ss_ext_sales_price) AS store_sales,
        COUNT(DISTINCT ss_ticket_number) AS store_orders
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2450800 AND 2450900
    GROUP BY ss_promo_sk
) sm ON p.p_promo_sk = sm.promo_sk
LEFT JOIN (
    SELECT
        ws_promo_sk AS promo_sk,
        SUM(ws_net_profit) AS web_net_profit,
        SUM(ws_ext_sales_price) AS web_sales,
        COUNT(DISTINCT ws_order_number) AS web_orders
    FROM web_sales ws
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450800 AND 2450900
      AND wsite.web_country = 'United States'
    GROUP BY ws_promo_sk
) wm ON p.p_promo_sk = wm.promo_sk
LEFT JOIN (
    SELECT
        ss_promo_sk AS promo_sk,
        SUM(sr_net_loss) AS return_loss,
        SUM(sr_refunded_cash) AS refunded_cash,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN store_sales ss ON sr.sr_item_sk = ss.ss_item_sk AND sr.sr_ticket_number = ss.ss_ticket_number
    WHERE sr.sr_returned_date_sk BETWEEN 2450800 AND 2450900
    GROUP BY ss_promo_sk
) rm ON p.p_promo_sk = rm.promo_sk
WHERE p.p_cost > 0
  AND p.p_channel_tv = 'Y'
ORDER BY roi_rank
LIMIT 20
