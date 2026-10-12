SELECT
    r.r_reason_desc,
    ss.ss_item_sk AS item_sk,
    SUM(ss.ss_net_profit) AS store_net_profit,
    SUM(ws.ws_net_profit) AS web_net_profit,
    SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ss.ss_ext_discount_amt) AS avg_store_discount,
    AVG(ws.ws_ext_discount_amt) AS avg_web_discount,
    SUM(ss.ss_quantity) + SUM(ws.ws_quantity) AS total_quantity,
    RANK() OVER (ORDER BY (SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit)) DESC) AS profit_rank
FROM
    reason r
    CROSS JOIN store_sales ss
    JOIN web_sales ws
        ON ss.ss_item_sk = ws.ws_item_sk
        AND ss.ss_sold_date_sk = ws.ws_sold_date_sk
        AND ss.ss_promo_sk = ws.ws_promo_sk
WHERE
    r.r_reason_id = 'AAAAAAAABAAAAAAA'
    AND ss.ss_sold_date_sk BETWEEN 2450815 AND 2450825
    AND ws.ws_sold_date_sk BETWEEN 2450815 AND 2450825
GROUP BY
    r.r_reason_desc,
    ss.ss_item_sk
ORDER BY
    total_net_profit DESC
LIMIT 10
