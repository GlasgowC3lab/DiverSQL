WITH sales AS (
    SELECT
        ss_sold_date_sk AS date_sk,
        ss_store_sk AS store_sk,
        ss_item_sk AS item_sk,
        ss_customer_sk AS cust_sk,
        ss_addr_sk AS addr_sk,
        ss_promo_sk AS promo_sk,
        ss_quantity AS quantity,
        ss_net_paid AS net_paid,
        ss_net_profit AS net_profit
    FROM store_sales
    UNION ALL
    SELECT
        cs_sold_date_sk,
        NULL,
        cs_item_sk,
        cs_bill_customer_sk,
        NULL,
        cs_promo_sk,
        cs_quantity,
        cs_net_paid,
        cs_net_profit
    FROM catalog_sales
    UNION ALL
    SELECT
        ws_sold_date_sk,
        NULL,
        ws_item_sk,
        ws_bill_customer_sk,
        NULL,
        ws_promo_sk,
        ws_quantity,
        ws_net_paid,
        ws_net_profit
    FROM web_sales
)
SELECT
    d.d_year,
    d.d_month_seq,
    COALESCE(s.s_store_name, 'ALL') AS store_name,
    i.i_category,
    p.p_promo_name,
    SUM(sales.quantity) AS total_quantity,
    SUM(sales.net_paid) AS total_net_paid,
    SUM(sales.net_profit) AS total_net_profit
FROM sales
JOIN date_dim d ON sales.date_sk = d.d_date_sk
JOIN item i ON sales.item_sk = i.i_item_sk
LEFT JOIN store s ON sales.store_sk = s.s_store_sk
LEFT JOIN promotion p ON sales.promo_sk = p.p_promo_sk
WHERE d.d_year = 2002
GROUP BY
    d.d_year,
    d.d_month_seq,
    COALESCE(s.s_store_name, 'ALL'),
    i.i_category,
    p.p_promo_name
ORDER BY total_net_profit DESC
LIMIT 100
