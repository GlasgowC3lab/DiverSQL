WITH sales_promo AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_ext_tax,
        cs.cs_net_paid_inc_tax,
        cs.cs_net_profit,
        p.p_promo_id,
        p.p_response_target,
        p.p_discount_active,
        p.p_channel_email,
        p.p_channel_tv,
        p.p_channel_catalog,
        MAP(ARRAY['email','tv','catalog'], ARRAY[p.p_channel_email, p.p_channel_tv, p.p_channel_catalog]) AS promo_channels
    FROM catalog_sales cs
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cs.cs_quantity > 1
      AND cs.cs_sales_price BETWEEN 10 AND 200
      AND cs.cs_ext_tax < 50
      AND p.p_response_target = 1
      AND p.p_discount_active = 'Y'
      AND p.p_channel_email = 'Y'
)
SELECT
    sp.cs_sold_date_sk,
    sp.p_promo_id,
    COUNT(*) AS order_cnt,
    SUM(sp.cs_quantity) AS total_qty,
    AVG(sp.cs_sales_price) AS avg_price,
    MIN(sp.cs_net_paid_inc_tax) AS min_paid,
    MAX(sp.cs_net_paid_inc_tax) AS max_paid,
    ROW_NUMBER() OVER (ORDER BY SUM(sp.cs_quantity) DESC) AS global_row_num,
    ROW_NUMBER() OVER (PARTITION BY sp.p_promo_id ORDER BY SUM(sp.cs_quantity) DESC) AS promo_row_num,
    u.channel_name,
    u.channel_flag
FROM sales_promo sp
LEFT JOIN UNNEST(sp.promo_channels) AS u (channel_name, channel_flag) ON true
GROUP BY
    sp.cs_sold_date_sk,
    sp.p_promo_id,
    u.channel_name,
    u.channel_flag
HAVING COUNT(*) > 0
ORDER BY total_qty DESC
LIMIT 100
