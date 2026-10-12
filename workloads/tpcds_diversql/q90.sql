WITH filtered_sales AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        i.i_item_id,
        i.i_product_name,
        i.i_item_desc,
        p.p_promo_name,
        p.p_channel_email,
        d.d_date,
        t.t_hour,
        CONCAT(i.i_brand, ' ', i.i_product_name) AS brand_product,
        REGEXP_EXTRACT(i.i_item_desc, '(?i)(organic|fresh)', 1) AS matched_keyword
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE REGEXP_LIKE(i.i_item_desc, '(?i)organic|fresh')
      AND p.p_channel_email = 'Y'
      AND i.i_product_name LIKE '%Deluxe%'
)
SELECT
    d_date,
    t_hour,
    SUM(ss_net_profit) AS total_profit,
    COUNT(*) AS transaction_cnt,
    ROW_NUMBER() OVER (PARTITION BY d_date ORDER BY SUM(ss_net_profit) DESC) AS profit_rank
FROM filtered_sales
GROUP BY d_date, t_hour
ORDER BY total_profit DESC
LIMIT 100
