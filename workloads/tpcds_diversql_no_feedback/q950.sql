WITH sales_base AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_net_profit,
        ws.ws_quantity,
        d.d_year,
        i.i_category,
        i.i_item_desc
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND regexp_like(i.i_item_desc, '[A-Z]{3}')
      AND p.p_channel_details LIKE '%event%'
)
SELECT
    sb.d_year,
    sb.i_category,
    regexp_extract(sb.i_item_desc, '([A-Z]{3})', 1) AS extracted_code,
    COUNT(DISTINCT sb.ws_order_number) AS order_cnt,
    SUM(sb.ws_net_profit) AS total_profit,
    CASE WHEN SUM(sb.ws_quantity) > 1000 THEN 'High Volume' ELSE 'Low Volume' END AS volume_category
FROM sales_base sb
WHERE EXISTS (
    SELECT 1
    FROM web_returns wr
    WHERE wr.wr_order_number = sb.ws_order_number
)
GROUP BY
    sb.d_year,
    sb.i_category,
    regexp_extract(sb.i_item_desc, '([A-Z]{3})', 1)
ORDER BY total_profit DESC
LIMIT 50
