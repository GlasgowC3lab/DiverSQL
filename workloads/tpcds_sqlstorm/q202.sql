WITH unified_sales AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_bill_customer_sk AS customer_sk,
        'catalog' AS channel_type,
        cc.cc_name AS channel_name,
        cs.cs_ext_sales_price AS sales,
        cs.cs_net_profit AS profit,
        cs.cs_ext_discount_amt AS discount,
        p.p_promo_id AS promo_id
    FROM catalog_sales cs
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    UNION ALL
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        'store',
        s.s_store_name,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ss.ss_ext_discount_amt,
        p.p_promo_id
    FROM store_sales ss
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    UNION ALL
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        'web',
        we.web_name,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_ext_discount_amt,
        p.p_promo_id
    FROM web_sales ws
    LEFT JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
)
SELECT
    d.d_year,
    d.d_month_seq,
    i.i_category,
    i.i_brand,
    u.channel_type,
    u.channel_name,
    sum(u.sales) AS total_sales,
    sum(u.profit) AS total_profit,
    sum(u.discount) AS total_discount,
    CASE WHEN sum(u.sales) <> 0 THEN sum(u.discount) / sum(u.sales) * 100 ELSE 0 END AS discount_percent,
    count(DISTINCT u.customer_sk) AS distinct_customers,
    count(DISTINCT u.promo_id) AS distinct_promotions
FROM unified_sales u
JOIN date_dim d ON u.date_sk = d.d_date_sk
JOIN item i ON u.item_sk = i.i_item_sk
GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_brand, u.channel_type, u.channel_name
ORDER BY d.d_year, d.d_month_seq, i.i_category, i.i_brand, u.channel_type
