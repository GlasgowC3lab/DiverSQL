WITH sales AS (
    SELECT
        ss.ss_sold_date_sk AS sold_date_sk,
        ss.ss_store_sk AS store_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_promo_sk AS promo_sk,
        ss.ss_customer_sk AS customer_sk,
        ss.ss_quantity AS quantity,
        ss.ss_sales_price AS sales_price,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_paid_inc_tax AS net_paid_inc_tax
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk IS NOT NULL
),
date_info AS (
    SELECT
        d.d_date_sk,
        d.d_year,
        d.d_moy,
        d.d_date
    FROM date_dim d
    WHERE d.d_year BETWEEN 2000 AND 2002
),
store_info AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_zip,
        s.s_hours,
        s.s_manager
    FROM store s
),
item_info AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_color
    FROM item i
),
promo_info AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        p.p_discount_active
    FROM promotion p
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_email_address
    FROM customer c
)
SELECT
    d.d_year,
    d.d_moy AS month,
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    COUNT(*) AS total_sales,
    SUM(si.quantity) AS total_quantity_sold,
    SUM(si.sales_price * si.quantity) AS gross_sales,
    SUM(si.net_paid_inc_tax) AS net_sales,
    COUNT(DISTINCT i.i_item_sk) AS distinct_items_sold,
    array_join(
        array_agg(
            DISTINCT lower(trim(regexp_replace(i.i_product_name, '[^a-zA-Z0-9 ]', '')))
        ),
        '|'
    ) AS cleaned_product_names,
    array_join(
        array_agg(
            DISTINCT replace(i.i_color, ' ', '_')
        ),
        ','
    ) AS distinct_colors,
    MAX(length(i.i_product_name)) AS max_product_name_len,
    AVG(length(trim(i.i_product_name))) AS avg_product_name_len,
    array_join(
        array_agg(
            DISTINCT reverse(split_part(c.c_email_address, '@', 2))
        ),
        '|'
    ) AS reversed_email_domains
FROM sales si
JOIN date_info d ON si.sold_date_sk = d.d_date_sk
JOIN store_info s ON si.store_sk = s.s_store_sk
JOIN item_info i ON si.item_sk = i.i_item_sk
JOIN promo_info p ON si.promo_sk = p.p_promo_sk
JOIN customer_info c ON si.customer_sk = c.c_customer_sk
GROUP BY
    d.d_year,
    d.d_moy,
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state
