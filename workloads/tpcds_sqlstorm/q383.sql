WITH sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.s_state,
        i.i_category,
        p.p_promo_name,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(CASE WHEN ss.ss_ext_sales_price = 0 THEN 0 ELSE ss.ss_ext_discount_amt / ss.ss_ext_sales_price END) AS avg_discount_rate
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY
        d.d_year,
        d.d_month_seq,
        s.s_state,
        i.i_category,
        p.p_promo_name
)
SELECT
    d_year,
    d_month_seq,
    s_state,
    i_category,
    p_promo_name,
    total_quantity,
    total_sales,
    total_discount,
    total_profit,
    avg_discount_rate,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY total_sales DESC
LIMIT 100
