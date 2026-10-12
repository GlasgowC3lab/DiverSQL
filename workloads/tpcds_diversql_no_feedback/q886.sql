/* Goal: Compare total net paid for Electronics items sold via catalog and web channels, filtering out low‑value transactions using the maximum promotion cost as a scalar benchmark, and list the top results across both channels. */
SELECT
    cs.cs_item_sk AS item_sk,
    SUM(cs.cs_net_paid) AS total_paid,
    'catalog' AS sales_channel
FROM
    catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
WHERE
    i.i_category = 'Electronics'
    AND cs.cs_net_paid > (SELECT MAX(p2.p_cost) FROM promotion p2)
GROUP BY
    cs.cs_item_sk

UNION ALL

SELECT
    ws.ws_item_sk AS item_sk,
    SUM(ws.ws_net_paid) AS total_paid,
    'web' AS sales_channel
FROM
    web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
WHERE
    i.i_category = 'Electronics'
    AND ws.ws_net_paid > (SELECT MAX(p2.p_cost) FROM promotion p2)
GROUP BY
    ws.ws_item_sk

ORDER BY
    total_paid DESC
LIMIT 100
