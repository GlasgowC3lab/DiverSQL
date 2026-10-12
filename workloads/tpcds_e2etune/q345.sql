SELECT
    site.web_name AS site_name,
    page.wp_type AS page_type,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    COUNT(DISTINCT ws.ws_item_sk) AS distinct_items,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(COALESCE(ret.wr_return_amt, 0)) AS total_return_amount,
    SUM(COALESCE(ret.wr_net_loss, 0)) AS total_return_loss,
    SUM(ws.ws_net_profit) - SUM(COALESCE(ret.wr_net_loss, 0)) AS net_profit_after_returns,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    RANK() OVER (ORDER BY SUM(ws.ws_net_profit) - SUM(COALESCE(ret.wr_net_loss, 0)) DESC) AS profit_rank
FROM web_sales ws
JOIN web_page page ON ws.ws_web_page_sk = page.wp_web_page_sk
JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
LEFT JOIN web_returns ret
    ON ws.ws_order_number = ret.wr_order_number
   AND ws.ws_item_sk = ret.wr_item_sk
   AND ws.ws_web_page_sk = ret.wr_web_page_sk
WHERE page.wp_type IN ('ad', 'welcome')
  AND ws.ws_sold_date_sk BETWEEN 2450800 AND 2450900
GROUP BY site.web_name, page.wp_type
HAVING SUM(ws.ws_net_profit) > 10000
ORDER BY net_profit_after_returns DESC
LIMIT 100
