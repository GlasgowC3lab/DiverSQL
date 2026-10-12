WITH
filtered_address AS (
    SELECT
        ca_address_sk,
        ca_zip,
        ca_address_id,
        ca_suite_number
    FROM customer_address
    WHERE regexp_like(ca_address_id, '^AAAA.*')
      AND ca_suite_number LIKE '%Suite%'
),
web_sales_enriched AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_bill_addr_sk,
        ws.ws_ext_discount_amt,
        ws.ws_net_paid_inc_ship,
        hd.hd_demo_sk,
        fa.ca_zip,
        CASE WHEN ws.ws_ext_discount_amt > 1000 THEN 'High' ELSE 'Low' END AS discount_category
    FROM web_sales ws
    JOIN filtered_address fa
        ON ws.ws_bill_addr_sk = fa.ca_address_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE ws.ws_list_price > 100
),
agg_sales AS (
    SELECT
        ca_zip,
        discount_category,
        COUNT(*) AS sales_cnt,
        SUM(ws_net_paid_inc_ship) AS total_net_paid,
        SUM(ws_ext_discount_amt) AS total_discount
    FROM web_sales_enriched
    GROUP BY ca_zip, discount_category
),
promo_set AS (
    SELECT * FROM (VALUES
        ('PromoA'),
        ('PromoB')
    ) AS t(promo_name)
),
final_result AS (
    SELECT
        a.ca_zip,
        a.discount_category,
        a.sales_cnt,
        a.total_net_paid,
        a.total_discount,
        p.promo_name
    FROM agg_sales a
    CROSS JOIN promo_set p
    WHERE a.ca_zip NOT IN (
        SELECT DISTINCT fa2.ca_zip
        FROM filtered_address fa2
        JOIN store_sales ss
            ON fa2.ca_address_sk = ss.ss_addr_sk
        WHERE ss.ss_quantity > 0
    )
)
SELECT
    ca_zip,
    discount_category,
    promo_name,
    sales_cnt,
    total_net_paid,
    total_discount
FROM final_result
ORDER BY total_net_paid DESC
LIMIT 100
