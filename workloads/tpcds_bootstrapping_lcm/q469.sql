WITH sales_agg AS (
    SELECT 
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        d_sold.d_year,
        SUM(cs.cs_net_paid)                       AS total_net_paid,
        SUM(cs.cs_ext_discount_amt)               AS total_discount,
        AVG(cs.cs_net_profit)                     AS avg_net_profit,
        COUNT(DISTINCT cs.cs_order_number)        AS order_count,
        COUNT(DISTINCT wp.wp_web_page_sk)         AS distinct_web_pages,
        SUM(wp.wp_max_ad_count)                   AS total_max_ad_count,
        ca_bill.ca_country                         AS billing_country,
        ca_ship.ca_country                         AS shipping_country
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN store s
        ON s.s_closed_date_sk = d_sold.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year BETWEEN 2000 AND 2002
      AND s.s_state = 'CA'
      AND cs.cs_net_paid > 0
    GROUP BY 
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        d_sold.d_year,
        ca_bill.ca_country,
        ca_ship.ca_country
    HAVING SUM(cs.cs_net_paid) > 10000
)
SELECT 
    ss.s_store_id,
    ss.s_store_name,
    ss.s_city,
    ss.s_state,
    ss.d_year,
    ss.total_net_paid,
    ss.total_discount,
    ss.avg_net_profit,
    ss.order_count,
    ss.distinct_web_pages,
    ss.total_max_ad_count,
    ss.billing_country,
    ss.shipping_country,
    ROW_NUMBER() OVER (PARTITION BY ss.d_year ORDER BY ss.total_net_paid DESC) AS rank_within_year
FROM sales_agg ss
ORDER BY ss.d_year, rank_within_year
LIMIT 100
