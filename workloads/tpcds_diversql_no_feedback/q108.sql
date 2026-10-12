WITH combined_sales AS (
    SELECT
        d.d_year AS sales_year,
        p.p_channel_email AS promo_channel,
        SUM(cs.cs_net_paid_inc_ship_tax) AS total_net_paid
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
      AND p.p_discount_active = 'Y'
      AND i.i_category = 'Sports'
    GROUP BY d.d_year, p.p_channel_email

    UNION ALL

    SELECT
        d.d_year AS sales_year,
        p.p_channel_email AS promo_channel,
        SUM(ws.ws_net_paid_inc_ship_tax) AS total_net_paid
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
      AND p.p_discount_active = 'Y'
      AND i.i_category = 'Sports'
    GROUP BY d.d_year, p.p_channel_email
)
SELECT
    sales_year,
    promo_channel,
    SUM(total_net_paid) AS net_paid_total
FROM combined_sales
GROUP BY ROLLUP (sales_year, promo_channel)
ORDER BY sales_year, promo_channel
